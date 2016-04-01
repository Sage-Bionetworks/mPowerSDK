//
//  APHMedicationTrackerDataStore.m
//  mPowerSDK
//
// Copyright (c) 2016, Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "APHMedicationTrackerDataStore.h"
#import "APHMedicationTrackerTask.h"
@import BridgeAppSDK;

NSString * kSelectedMedicationsKey;
NSString * kSkippedSelectMedicationsSurveyQuestionKey;
NSString * kMomentInDayResultKey;
NSString * kLastMedicationSurveyDateKey;

NSString * kControlGroupAnswer      = @"Control Group";
NSString * kSkippedAnswer           = @"Medication Unknown";
NSString * kNoMedication            = @"No Tracked Medication";

//
//    elapsed time delay before asking the patient if they took their medications
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMomentInDaySurvey         = 20.0 * 60.0;

//
//    elapsed time delay before asking the user if their diagnosis or medication have changed
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMedChangedSurvey         = 30.0 * 24.0 * 60.0 * 60.0;

@implementation APHMedicationTrackerKeyedUnarchiver

+ (Class)classForClassName:(NSString *)codedName {
    if ([codedName isEqualToString:@"APHMedication"]) {
        return [SBAMedication class];
    }
    else {
        return [super classForClassName:codedName];
    }
}

@end


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
    kSelectedMedicationsKey                        = NSStringFromSelector(@selector(selectedMedications));
    kSkippedSelectMedicationsSurveyQuestionKey     = NSStringFromSelector(@selector(skippedSelectMedicationsSurveyQuestion));
    kMomentInDayResultKey                          = NSStringFromSelector(@selector(momentInDayResult));
    kLastMedicationSurveyDateKey                   = NSStringFromSelector(@selector(lastMedicationSurveyDate));
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
        return [[[[APCAppDelegate sharedAppDelegate] dataSubstrate] currentUser] taskCompletion];
    }
    return _lastCompletionDate;
}

@synthesize momentInDayResult = _momentInDayResult;

- (NSArray<ORKStepResult *> *)momentInDayResult {
    NSArray<ORKStepResult *> *momentInDayResult = [self.changesDictionary objectForKey:kMomentInDayResultKey] ?: _momentInDayResult;
    if (momentInDayResult == nil) {
        NSString *defaultAnswer = nil;
        if (self.skippedSelectMedicationsSurveyQuestion) {
            defaultAnswer = kSkippedAnswer;
        }
        else if (self.hasNoTrackedMedication) {
            defaultAnswer = kNoMedication;
        }
        if (defaultAnswer != nil) {
            NSArray *idMap = @[@[APHMedicationTrackerMomentInDayStepIdentifier, APHMedicationTrackerMomentInDayFormItemIdentifier],
                               @[APHMedicationTrackerActivityTimingStepIdentifier, APHMedicationTrackerActivityTimingStepIdentifier],];
            NSMutableArray *results = [NSMutableArray new];
            NSDate *startDate = [NSDate date];
            for (NSArray *map in idMap) {
                ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:map.lastObject];
                input.startDate = startDate;
                input.endDate = startDate;
                input.questionType = ORKQuestionTypeSingleChoice;
                input.choiceAnswers = @[defaultAnswer];
                ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:map.firstObject
                                                                                  results:@[input]];
                [results addObject:stepResult];
            }
            momentInDayResult = [results copy];
            self.changesDictionary[kMomentInDayResultKey] = momentInDayResult;
        }
    }
    return momentInDayResult;
}

- (void)setMomentInDayResult:(NSArray<ORKStepResult *> *)momentInDayResult {
    [self.changesDictionary setValue:[momentInDayResult copy] forKey:kMomentInDayResultKey];
}

- (NSArray <NSString *> *)trackedMedications {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = YES", NSStringFromSelector(@selector(tracking))];
    NSArray *selectedMeds = [self selectedMedications];
    NSArray *trackedMeds = [selectedMeds filteredArrayUsingPredicate:predicate];
    return [trackedMeds valueForKey:NSStringFromSelector(@selector(shortText))];
}

- (NSArray<SBAMedication *> *)selectedMedications {
    NSArray *result = self.changesDictionary[kSelectedMedicationsKey];
    if (result == nil) {
        NSData *data = [self.storedDefaults objectForKey:kSelectedMedicationsKey];
        if (data != nil) {
            result = [APHMedicationTrackerKeyedUnarchiver unarchiveObjectWithData:data];
        }
    }
    return result;
}

- (void)setSelectedMedications:(NSArray<SBAMedication *> *)selectedMedications {
    [self.changesDictionary setValue:selectedMedications forKey:kSelectedMedicationsKey];
    [self.changesDictionary setValue:@(selectedMedications == nil) forKey:kSkippedSelectMedicationsSurveyQuestionKey];
}

- (NSDate *)lastMedicationSurveyDate {
    return [self.storedDefaults objectForKey:kLastMedicationSurveyDateKey];
}

- (void)setLastMedicationSurveyDate:(NSDate *)lastMedicationSurveyDate {
    if (lastMedicationSurveyDate != nil) {
        [self.storedDefaults setObject:lastMedicationSurveyDate forKey:kLastMedicationSurveyDateKey];
    }
}

- (BOOL)skippedSelectMedicationsSurveyQuestion {
    NSString *key = kSkippedSelectMedicationsSurveyQuestionKey;
    id obj = [self.changesDictionary objectForKey:key] ?: [self.storedDefaults objectForKey:key];
    return [obj boolValue];
}

- (void)setSkippedSelectMedicationsSurveyQuestion:(BOOL)skippedSelectMedicationsSurveyQuestion {
    if (skippedSelectMedicationsSurveyQuestion) {
        self.selectedMedications = nil;
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
    if (self.trackedMedications.count == 0) {
        return NO;
    }
    
    if (self.lastCompletionDate == nil || self.momentInDayResult == nil) {
        return YES;
    }
    
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastCompletionDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMomentInDaySurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)shouldIncludeMedicationChangedQuestion {
    if (!self.hasSelectedMedicationOrSkipped) {
        // Chould not ask if there has been a change if the question has never been asked
        return NO;
    }
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastMedicationSurveyDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMedChangedSurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)hasChanges {
    return (self.changesDictionary.count > 0);
}

- (void)commitChanges {

    // store the moment in day result in memeory
    NSArray *momentInDayResult = [self.changesDictionary objectForKey:kMomentInDayResultKey];
    if (momentInDayResult != nil) {
        self.lastCompletionDate = [NSDate date];
        _momentInDayResult = momentInDayResult;
    }
    
    // store the tracked medications and skip result in user defaults
    id skipped = self.changesDictionary[kSkippedSelectMedicationsSurveyQuestionKey];
    if (skipped != nil) {
        self.lastMedicationSurveyDate = [NSDate date];
        [self.storedDefaults setValue:skipped forKey:kSkippedSelectMedicationsSurveyQuestionKey];
        if ([skipped boolValue]) {
            [self.storedDefaults removeObjectForKey:kSelectedMedicationsKey];
        }
        else {
            NSArray *selectedMeds = self.changesDictionary[kSelectedMedicationsKey];
            if (selectedMeds != nil) {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selectedMeds];
                [self.storedDefaults setValue:data
                                       forKey:kSelectedMedicationsKey];
            }
        }
    }
    
    // clear temp storage
    [self.changesDictionary removeAllObjects];
}

- (void)reset {
    [self.changesDictionary removeAllObjects];
}

@end
