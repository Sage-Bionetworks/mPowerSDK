//
//  APHMedicationTrackerDataStore.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/21/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHMedicationTrackerDataStore.h"
#import "APHMedicationTrackerTask.h"

NSString * kTrackedMedicationsKey;
NSString * kSkippedSelectMedicationsSurveyQuestionKey;
NSString * kMomentInDayResultKey;

NSString * kControlGroupAnswer      = @"Control Group";
NSString * kSkippedAnswer           = @"Medication Unknown";
NSString * kNoMedication            = @"No Tracked Medication";

//
//    elapsed time delay before asking the patient if they took their medications
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowSurvey         = 20.0 * 60.0;

@interface APHMedicationTrackerDataStore ()

@property (nonatomic) NSMutableDictionary *changesDictionary;

@end

@implementation APHMedicationTrackerDataStore

+ (instancetype)defaultStore {
    static id __instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[self alloc] init];
    });
    return __instance;
}

+ (void)initialize {
    kTrackedMedicationsKey                         = NSStringFromSelector(@selector(trackedMedications));
    kSkippedSelectMedicationsSurveyQuestionKey     = NSStringFromSelector(@selector(skippedSelectMedicationsSurveyQuestion));
    kMomentInDayResultKey                          = NSStringFromSelector(@selector(momentInDayResult));
}

- (instancetype)init {
    return [self initWithUserDefaultsWithSuiteName:nil];
}

- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName {
    if ((self = [super init])) {
        _storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        _changesDictionary = [NSMutableDictionary new];
    }
    return self;
}

- (NSDate *)lastCompletionDate {
    if (_lastCompletionDate == nil) {
        // Allow custom setting of last completion date and only access the app delegate the last
        // completion date is not set.
        return [self.user taskCompletion];
    }
    return _lastCompletionDate;
}

- (APCUser*)user {
    if (_user == nil) {
        _user = [[[APCAppDelegate sharedAppDelegate] dataSubstrate] currentUser];
    }
    return _user;
}

- (APCDataGroupsManager *)dataGroupsManager {
    if (_dataGroupsManager == nil) {
        _dataGroupsManager = [[APCAppDelegate sharedAppDelegate] dataGroupsManagerForUser:self.user];
    }
    return _dataGroupsManager;
}

@synthesize momentInDayResult = _momentInDayResult;

- (ORKStepResult *)momentInDayResult {
    ORKStepResult *momentInDayResult = [self.changesDictionary objectForKey:kMomentInDayResultKey] ?: _momentInDayResult;
    if (momentInDayResult == nil) {
        NSString *defaultAnswer = nil;
        if (self.dataGroupsManager.isStudyControlGroup) {
            defaultAnswer = kControlGroupAnswer;
        }
        else if (self.skippedSelectMedicationsSurveyQuestion) {
            defaultAnswer = kSkippedAnswer;
        }
        else if (self.hasNoTrackedMedication) {
            defaultAnswer = kNoMedication;
        }
        if (defaultAnswer != nil) {
            ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:APHMedicationTrackerMomentInDayFormItemIdentifier];
            input.startDate = [NSDate date];
            input.endDate = input.startDate;
            input.questionType = ORKQuestionTypeSingleChoice;
            input.choiceAnswers = @[defaultAnswer];
            momentInDayResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerMomentInDayStepIdentifier
                                                                      results:@[input]];
            self.changesDictionary[kMomentInDayResultKey] = momentInDayResult;
        }
    }
    return momentInDayResult;
}

- (void)setMomentInDayResult:(ORKStepResult *)momentInDayResult {
    [self.changesDictionary setValue:[momentInDayResult copy] forKey:kMomentInDayResultKey];
}

- (NSArray <NSString *> *)trackedMedications {
    NSString *key = kTrackedMedicationsKey;
    return [self.changesDictionary objectForKey:key] ?: [self.storedDefaults objectForKey:key];
}

- (void)setTrackedMedications:(NSArray <NSString *> *)trackedMedications {
    [self.changesDictionary setValue:[trackedMedications copy] forKey:kTrackedMedicationsKey];
    [self.changesDictionary setValue:@(trackedMedications == nil) forKey:kSkippedSelectMedicationsSurveyQuestionKey];
}

- (BOOL)skippedSelectMedicationsSurveyQuestion {
    NSString *key = kSkippedSelectMedicationsSurveyQuestionKey;
    id obj = [self.changesDictionary objectForKey:key] ?: [self.storedDefaults objectForKey:key];
    return [obj boolValue];
}

- (void)setSkippedSelectMedicationsSurveyQuestion:(BOOL)skippedSelectMedicationsSurveyQuestion {
    if (skippedSelectMedicationsSurveyQuestion) {
        self.trackedMedications = nil;
    }
    else {
        [self.changesDictionary setValue:@(NO) forKey:kSkippedSelectMedicationsSurveyQuestionKey];
    }
}

- (BOOL)hasNoTrackedMedication {
    NSArray *trackedMeds = self.trackedMedications;
    return (trackedMeds != nil) && (trackedMeds.count == 0);
}

- (BOOL)hasSelectedMedicationOrSkipped {
    return self.skippedSelectMedicationsSurveyQuestion || (self.trackedMedications != nil);
}

- (BOOL)shouldIncludeMomentInDayStep {
    if (self.dataGroupsManager.isStudyControlGroup || self.trackedMedications.count == 0) {
        return NO;
    }
    
    if (self.lastCompletionDate == nil || self.momentInDayResult == nil) {
        return YES;
    }
    
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastCompletionDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowSurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)hasChanges {
    return [self.dataGroupsManager hasChanges] || (self.changesDictionary.count > 0);
}

- (void)commitChanges {
    self.lastCompletionDate = [NSDate date];
    
    // store the moment in day result locally
    ORKStepResult *momentInDayResult = [self.changesDictionary objectForKey:kMomentInDayResultKey];
    if (momentInDayResult != nil) {
        _momentInDayResult = momentInDayResult;
    }
    
    // store the tracked medications and skip result in user defaults
    id skipped = self.changesDictionary[kSkippedSelectMedicationsSurveyQuestionKey];
    if (skipped != nil) {
        [self.storedDefaults setValue:skipped forKey:kSkippedSelectMedicationsSurveyQuestionKey];
        if ([skipped boolValue]) {
            [self.storedDefaults removeObjectForKey:kTrackedMedicationsKey];
        }
        else {
            NSArray *trackedMeds = self.changesDictionary[kTrackedMedicationsKey];
            [self.storedDefaults setValue:trackedMeds forKey:kTrackedMedicationsKey];
        }
    }
    
    // clear temp storage
    [self.changesDictionary removeAllObjects];
    
    // Save user data groups
    if ([self.dataGroupsManager hasChanges]) {
        typeof(self) __weak weakSelf = self;
        [self.user updateDataGroups:self.dataGroupsManager.dataGroups onCompletion:^(NSError *error) {
            if ((error == nil) && ![weakSelf hasChanges]) {
                [weakSelf reset];
            }
        }];
    }
}

- (void)reset {
    
    [self.changesDictionary removeAllObjects];

    // release the user and data groups
    _user = nil;
    _dataGroupsManager = nil;
}

@end
