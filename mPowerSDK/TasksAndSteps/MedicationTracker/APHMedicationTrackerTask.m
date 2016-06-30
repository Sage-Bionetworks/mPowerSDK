//
//  APHMedicationTrackerTask.m
//  mPowerSDK
//
// Copyright (c) 2015, Sage Bionetworks. All rights reserved.
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

#import "APHMedicationTrackerTask.h"
#import <APCAppCore/APCAppCore.h>
#import "APHMedicationTracker.h"
#import "APHLocalization.h"
#import "NSArray+APHExtensions.h"
#import "NSNull+APHExtensions.h"
@import BridgeAppSDK;

// Identifiers used by this task
NSString * const APHInstruction0StepIdentifier                      = @"instruction";
NSString * const APHMedicationTrackerConclusionStepIdentifier       = @"medicationConclusion";
NSString * const APHMedicationTrackerTaskIdentifier                 = @"Medication Tracker";
NSString * const APHMedicationTrackerIntroductionStepIdentifier     = @"medicationIntroduction";
NSString * const APHMedicationTrackerChangedStepIdentifier          = @"medicationChanged";
NSString * const APHMedicationTrackerSelectionStepIdentifier        = @"medicationSelection";
NSString * const APHMedicationTrackerFrequencyStepIdentifier        = @"medicationFrequency";
NSString * const APHMedicationTrackerNoneAnswerIdentifier           = @"None";
NSString * const APHMedicationTrackerSkipAnswerIdentifier           = @"Skip";

@interface APHMedicationTrackerTask ()

@property (nonatomic) NSMutableArray <ORKStep *> *steps;
@property (nonatomic, readonly, copy) NSDictionary *mappingDictionary;
@property (nonatomic) BOOL medicationChanged;
@property (nonatomic) NSArray *medChoiceValues;

@end

@implementation APHMedicationTrackerTask

@synthesize identifier = _identifier;

+ (NSDictionary*)defaultMapping {
    static NSDictionary * _defaultMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [[APCAppDelegate sharedAppDelegate] pathForResource:@"MedicationTracking" ofType:@"json"];
        NSData *json = [NSData dataWithContentsOfFile:path];
        if (json) {
            NSError *parseError;
            _defaultMapping = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:&parseError];
            NSAssert1(parseError == nil, @"Error parsing data group mapping: %@", parseError);
        }
    });
    return _defaultMapping;
}

- (instancetype)init {
    return [self initWithDictionaryRepresentation:nil];
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary {
    return [self initWithDictionaryRepresentation:nil subTask:nil];
}

- (instancetype)initWithDictionaryRepresentation:(NSDictionary * _Nullable)dictionary
                                         subTask:(id <ORKTask> _Nullable)subTask {
    self = [super init];
    if (self) {
        _identifier = [subTask identifier] ?: [APHMedicationTrackerTaskIdentifier copy];
        _subTask = subTask;
        
        // map the medications
        _mappingDictionary = [dictionary copy] ?: [[self class] defaultMapping];
        NSMutableArray *meds = [NSMutableArray new];
        for (NSDictionary * dictionary in _mappingDictionary[@"items"]) {
            [meds addObject:[[SBAMedication alloc] initWithDictionaryRepresentation:dictionary]];
        }
        _medications = [meds copy];
        
        // map the medication steps
        NSMutableArray *medSteps = [NSMutableArray new];
        for (NSDictionary * dictionary in _mappingDictionary[@"steps"]) {
            ORKStep *step = [self createStepFromMappingDictionary:dictionary];
            if (step) {
                [medSteps addObject:step];
            }
        }
        for (NSDictionary * dictionary in _mappingDictionary[@"activitySteps"]) {
            ORKStep *step = [self createStepFromMappingDictionary:dictionary];
            if (step) {
                // Insert before the conclusion step
                [medSteps insertObject:step atIndex:medSteps.count - 1];
            }
        }
        _medicationTrackerSteps = [medSteps copy];
        
        // Create the ordered set
        _steps = [NSMutableArray new];
    }
    return self;
}

- (APHMedicationTrackerDataStore *)dataStore {
    return [APHMedicationTrackerDataStore defaultStore];
}

- (APCDataGroupsManager *)dataGroupsManager {
    if (_dataGroupsManager == nil) {
        _dataGroupsManager = [[APCAppDelegate sharedAppDelegate] dataGroupsManagerForUser:nil];
    }
    return _dataGroupsManager;
}

- (ORKStep*)createStepFromMappingDictionary:(NSDictionary*)stepDictionary {
    
    NSString *identifier = stepDictionary[@"identifier"];
    NSString *title = stepDictionary[@"title"];
    NSString *text = stepDictionary[@"text"];
    BOOL optional = [stepDictionary[@"optional"] boolValue];
    
    ORKStep *step = nil;
    if ([identifier isEqualToString:APHMedicationTrackerIntroductionStepIdentifier]) {
        step = [self createIntroductionStepWithTitle:title text:text];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerChangedStepIdentifier]) {
        step = [self createMedicationChangedStepWithTitle:title text:text optional:optional];
    }
    else if ([identifier isEqualToString:APCDataGroupsStepIdentifier]) {
        step = [self.dataGroupsManager surveyStep];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
        step = [self createMedicationSelectionStepWithTitle:title text:text optional:optional];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
        step = [self createFrequencyStepWithTitle:title text:text optional:optional];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerMomentInDayStepIdentifier]) {
        step = [self createMomentInDayStepWithTitle:title text:text optional:optional];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerActivityTimingStepIdentifier]) {
        step = [self createActivityTimingStepWithTitle:title text:text optional:optional];
    }
    else if ([identifier isEqualToString:APHMedicationTrackerConclusionStepIdentifier]) {
        step = [self createConclusionStepWithTitle:title text:text];
    }
    else if (identifier != nil) {
        step = [[ORKInstructionStep alloc] initWithIdentifier:identifier];
        step.title = title;
        step.text = text;
    }
    
    // Some of the steps have identifiers that are hardcoded by ResearchKit,
    // if that is the case then copy to a step with the desired identifier
    if ((step != nil) && ![step.identifier isEqualToString:identifier]) {
        step = [step copyWithIdentifier:identifier];
    }

    return step;
}

- (ORKStep*)createIntroductionStepWithTitle:(NSString*)title text:(NSString*)text
{
    ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:APHMedicationTrackerIntroductionStepIdentifier];
    step.title = title;
    step.text = text;
    return step;
}

- (ORKStep*)createMedicationChangedStepWithTitle:(NSString*)title text:(NSString*)text optional:(BOOL)optional {
    
    // Create the question
    NSString *stepText = text;
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerChangedStepIdentifier title:title text:stepText];
    step.optional = optional;

    // Create the answer format
    ORKAnswerFormat  *format = [ORKBooleanAnswerFormat booleanAnswerFormat];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerChangedStepIdentifier
                                                            text:nil
                                                    answerFormat:format];
    [step setFormItems:@[item]];
    
    return step;
}

- (ORKStep*)createMedicationSelectionStepWithTitle:(NSString*)title text:(NSString*)text optional:(BOOL)optional {
    
    // Create the question
    NSString *questionText = text;
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier title:title text:questionText];
    step.optional = NO;
    
    // Add the list of medications
    NSMutableArray *choices = [NSMutableArray new];
    for (SBAMedication *med in self.medications) {
        [choices addObject:[ORKTextChoice choiceWithText:med.text value:med.identifier]];
    }
    
    // Add a choice for none of the above
    NSString *noneText = NSLocalizedStringWithDefaultValue(@"APH_NONE_OF_THE_ABOVE", nil, APHLocaleBundle(), @"None of the above", @"Text for a selection choice indicating that none of the options was applicable.");
    ORKTextChoice *noneTextChoice = [ORKTextChoice choiceWithText:noneText detailText:nil value:APHMedicationTrackerNoneAnswerIdentifier exclusive:YES];
    [choices addObject:noneTextChoice];
    
    // Add a choice for skipping the question
    if (optional) {
        NSString *skipText = NSLocalizedStringWithDefaultValue(@"APH_SKIP_TEXT", nil, APHLocaleBundle(), @"Prefer not to answer", @"Text for a selection choice indicating that the user wants to skip the question.");
        ORKTextChoice *skipTextChoice = [ORKTextChoice choiceWithText:skipText detailText:nil value:APHMedicationTrackerSkipAnswerIdentifier exclusive:YES];
        [choices addObject:skipTextChoice];
    }
    
    // Create the answer format
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleMultipleChoice
                                textChoices:choices];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier
                                                            text:nil
                                                    answerFormat:format];
    [step setFormItems:@[item]];
    
    return step;
}

- (ORKStep*)createFrequencyStepWithTitle:(NSString*)title text:(NSString*)text optional:(BOOL)optional {
    NSString *questionText = text;
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerFrequencyStepIdentifier
                                                          title:title
                                                           text:questionText];
    step.optional = optional;
    return step;
}

- (ORKStep*)createMomentInDayStepWithTitle:(NSString*)title text:(NSString*)text optional:(BOOL)optional {
    NSString *introText = text;
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerMomentInDayStepIdentifier title:title text:introText];
    
    NSString *justBefore = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_BEFORE_CHOICE", nil, APHLocaleBundle(), @"Immediately before taking Parkinson medication", @"Choice for doing activity before taking medication.");
    NSString *justBeforeValue = @"Immediately before taking Parkinson medication";
    
    NSString *justAfter = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_AFTER_CHOICE", nil, APHLocaleBundle(), @"Just after taking Parkinson medication (at your best)", @"Choice for doing activity after taking medication.");
    NSString *justAfterValue = @"Just after taking Parkinson medication (at your best)";
    
    NSString *other = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_OTHER_CHOICE", nil, APHLocaleBundle(), @"Another time", @"Choice for doing activity at another time of day other than before or after taking medication.");
    NSString *otherValue = @"Another time";
    
    NSArray *textChoices = @[[ORKTextChoice choiceWithText:justBefore value:justBeforeValue],
                             [ORKTextChoice choiceWithText:justAfter value:justAfterValue],
                             [ORKTextChoice choiceWithText:other value:otherValue]];

    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:textChoices];
    
    NSString *itemText = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_QUESTION", nil, APHLocaleBundle(), @"When are you performing this activity?", @"Question text for the moment in day question.");
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerMomentInDayFormItemIdentifier
                                                            text:itemText
                                                    answerFormat:format];
    step.formItems = @[item];
    step.optional = optional;
    
    self.medChoiceValues = @[justBeforeValue, justAfterValue];
    
    return step;
}

- (ORKStep*)createActivityTimingStepWithTitle:(NSString*)title text:(NSString*)text optional:(BOOL)optional {
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier title:title text:text];
    step.optional = optional;
    return step;
}

- (ORKStep*)createConclusionStepWithTitle:(NSString*)title text:(NSString*)text
{
    ORKInstructionStep *step = [[ORKCompletionStep alloc] initWithIdentifier:APHMedicationTrackerConclusionStepIdentifier];
    // Replace the language in the last step
    step.title = title;
    step.text = text;
    return step;
}

- (BOOL)shouldUpdateAndIncludeStep:(ORKStep*)step {
    if ([step.identifier isEqualToString:APHMedicationTrackerChangedStepIdentifier]) {
        return ![self shouldIncludeMedicationTrackingSteps] && [self.dataStore shouldIncludeChangedQuestion];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
        // Frequency step inclusion depends upon current state and will mutate accordingly
        return [self shouldIncludeMedicationTrackingSteps] && [self shouldUpdateAndIncludeFrequencyStep:step];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerMomentInDayStepIdentifier]) {
        return (self.subTask != nil)  && self.dataStore.shouldIncludeMomentInDayStep;
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerActivityTimingStepIdentifier]) {
        // Activity timing inclusion depends upon current state and will mutate accordingly
        return [self shouldUpdateAndIncludeActivityTimingStep:step];
    }
    return [self shouldIncludeMedicationTrackingSteps];
}

- (BOOL)shouldIncludeMedicationTrackingSteps {
    if (self.subTask != nil) {
        // If there is a subtask then include only if the question has no answer and hasn't been skipped
        return self.medicationChanged || self.dataStore.hasChanges || !self.dataStore.hasSelectedOrSkipped;
    }
    return YES;
}

- (BOOL)shouldUpdateAndIncludeFrequencyStep:(ORKStep*)step {
    
    ORKFormStep *formStep = (ORKFormStep *)step;
    if (![formStep isKindOfClass:[ORKFormStep class]]) {
        NSAssert(NO, @"Medication frequency step is not of expected class");
        return NO;
    }
    
    // Add the list of medications
    NSMutableArray *items = [NSMutableArray new];
    for (SBAMedication *med in self.dataStore.selectedItems) {
        if (!med.injection) {
            ORKAnswerFormat *answerFormat = [[ORKScaleAnswerFormat alloc] initWithMaximumValue:12 minimumValue:1 defaultValue:0 step:1];
            ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:med.identifier
                                                                    text:med.text
                                                            answerFormat:answerFormat];
            [items addObject:item];
        }
    }
    
    formStep.formItems = items;
    
    return (items.count > 0);
}

- (BOOL)shouldUpdateAndIncludeActivityTimingStep:(ORKStep *)step {
    
    ORKFormStep *formStep = (ORKFormStep *)step;
    if (![formStep isKindOfClass:[ORKFormStep class]]) {
        NSAssert(NO, @"Medication frequency step is not of expected class");
        return NO;
    }
    
    if ((self.subTask == nil) || !self.dataStore.shouldIncludeMomentInDayStep) {
        return NO;
    }

    // Get the medication list
    NSArray *medList = self.dataStore.trackedItems;
    if (medList.count == 0) {
        return NO;
    }
    
    // Build list of meds
    NSString *itemTextFormat = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_TIMING_QUESTION", nil, APHLocaleBundle(), @"When was the last time you took your %@?", @"Prompt for timing of medication in pre-activity medication timing survey where %@ is a list of medications (For example, 'Levodopa or Rytary')");
    
    NSString *medListText = nil;
    if (medList.count == 1) {
        medListText = [medList firstObject];
    }
    else if (medList.count == 2) {
        NSString *twoItemListFormat = NSLocalizedStringWithDefaultValue(@"APH_TWO_ITEM_LIST_FORMAT", nil, APHLocaleBundle(), @"%@ or %@", @"Format of a list with two items (For example, 'Levodopa or Rytary')");
        medListText = [NSString stringWithFormat:twoItemListFormat, medList[0], medList[1]];
    }
    else {
        NSString *threeItemListFormat = NSLocalizedStringWithDefaultValue(@"APH_THREE_ITEM_LIST_FORMAT", nil, APHLocaleBundle(), @"%@, %@, or %@", @"Format of a list with three items (For example, 'Levodopa, Simet, or Rytary')");
        NSString *listDelimiter = NSLocalizedStringWithDefaultValue(@"APH_LIST_FORMAT_DELIMITER", nil, APHLocaleBundle(), @", ", @"Delimiter for a list of more than 3 items. (For example, 'Foo, Levodopa, Simet, or Rytary')");
        NSUInteger stopIndex = medList.count - 3;
        NSMutableString *listText = [NSMutableString new];
        [medList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop __unused) {
            [listText appendString:obj];
            if (idx < stopIndex) {
                [listText appendString:listDelimiter];
            }
            *stop = (idx == stopIndex);
        }];
        medListText = [NSString stringWithFormat:threeItemListFormat, listText, medList[stopIndex+1], medList[stopIndex+2]];
    }

    NSString *itemText = [NSString stringWithFormat:itemTextFormat, medListText];

    // If the steps include the medication introduction, do not include the explanation text here
    if ([self previousStepWithIdentifier:APHMedicationTrackerIntroductionStepIdentifier] != nil) {
        step.text = itemText;
        itemText = nil;
    }
    
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:[self activityTimingChoices]];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier
                                                            text:itemText
                                                    answerFormat:format];
    [formStep setFormItems:@[item]];
    
    return YES;
}

/**
 * Index of a given medication timing choice (used in graphing)
 */
- (NSUInteger)indexForMedicationActivityTimingChoice:(id <NSCopying, NSCoding, NSObject> _Nullable)choiceValue {
    if ([choiceValue isKindOfClass:[NSNumber class]]) {
        return [(NSNumber*)choiceValue unsignedIntegerValue];
    }
    return NSNotFound;
}

/**
 * Timing choice to include in the result sumamary for the givin task result
 */
- (id <NSCopying, NSCoding, NSObject> )timingChoiceFromTaskResult:(ORKTaskResult *)result {
    
    ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APHMedicationTrackerMomentInDayStepIdentifier];
    if (stepResult == nil) {
        // if the step result isn't found then look in the cache
        stepResult = [[[self.dataStore momentInDayResult] filteredArrayWithIdentifiers:@[APHMedicationTrackerMomentInDayStepIdentifier]] firstObject];
    }
    
    if ([stepResult isKindOfClass:[ORKStepResult class]]) {
        ORKChoiceQuestionResult *selectionResult = (ORKChoiceQuestionResult *)[stepResult.results firstObject];
        if ([selectionResult isKindOfClass:[ORKChoiceQuestionResult class]]) {
            id value = [selectionResult.choiceAnswers firstObject];
            return @([self.medChoiceValues indexOfObject:value]);
        }
    }
    return @(NSNotFound);
}

- (NSArray <ORKTextChoice *> *) activityTimingChoices
{
    NSString *formatMinutes = NSLocalizedStringWithDefaultValue(@"APH_MINUTES_RANGE_FORMAT", nil, APHLocaleBundle(),
                                                                @"%1$@-%2$@ minutes ago", @"Format for a time interval of %1$@ to %2$@ minutes ago where %1$@ is the localized number for the smaller value and %2$@ is the localized number for the larger value.");
    NSString *formatHours = NSLocalizedStringWithDefaultValue(@"APH_HOURS_RANGE_FORMAT", nil, APHLocaleBundle(),
                                                              @"%1$@-%2$@ hours ago", @"Format for a time interval of %1$@ to %2$@ hours ago where %1$@ is the localized number for the smaller value and %2$@ is the localized number for the larger value.");
    NSString *formatMoreThanHoursAgo = NSLocalizedStringWithDefaultValue(@"APH_MORE_THAN_HOURS_FORMAT", nil, APHLocaleBundle(), @"More than %@ hours ago", @"Timing option text in pre-activity medication timing survey for more than %@ hours ago.");
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    __block NSMutableArray <ORKTextChoice *> *choices = [NSMutableArray array];
    
    // NOTE: See BRIDGE-138 for details. syoung 12/28/2015 Having the choices map to a result that is in English
    // is intentional and should *not* be localized.
    void (^addInterval)(NSUInteger, NSUInteger) = ^(NSUInteger minTime, NSUInteger maxTime) {
        
        NSString *text = nil;
        NSString *value = nil;
        if (minTime < maxTime) {
            if ((minTime % 60 == 0) && (maxTime % 60 == 0)) {
                NSUInteger minHours = minTime/60;
                NSUInteger maxHours = maxTime/60;
                value = [NSString stringWithFormat:@"%1$@-%2$@ hours ago", @(minHours), @(maxHours)];
                text = [NSString stringWithFormat:formatHours, [numberFormatter stringForObjectValue:@(minHours)], [numberFormatter stringForObjectValue:@(maxHours)]];
            }
            else {
                value = [NSString stringWithFormat:@"%1$@-%2$@ minutes ago", @(minTime), @(maxTime)];
                text = [NSString stringWithFormat:formatMinutes, [numberFormatter stringForObjectValue:@(minTime)], [numberFormatter stringForObjectValue:@(maxTime)]];
            }
        }
        else {
            NSUInteger hours = minTime/60;
            value = [NSString stringWithFormat:@"More than %@ hours ago", @(hours)];
            text = [NSString stringWithFormat:formatMoreThanHoursAgo, [numberFormatter stringForObjectValue:@(hours)]];
        }
        
        [choices addObject:[ORKTextChoice choiceWithText:text value:value]];
    };
    
    addInterval(0, 30);
    addInterval(30, 60);
    addInterval(1 * 60, 2 * 60);
    addInterval(2 * 60, 4 * 60);
    addInterval(4 * 60, 8 * 60);
    addInterval(8 * 60, 0);
    
    // Add the "not sure" choice to both the choices array and the map
    [choices addObject:[ORKTextChoice choiceWithText:
                        NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_NOT_SURE", nil, APHLocaleBundle(), @"Not sure", @"Timing option text in pre-activity medication timing survey for someone who is unsure of when medication was last taken.")
                                               value:@"Not sure"]];
    
    // Copy the arrays to static values
    return [choices copy];
}

- (NSArray *)selectedMedicationFromResult:(ORKTaskResult*)result {
    [self.dataStore updateSelectedItems:self.medications stepIdentifier:APHMedicationTrackerSelectionStepIdentifier result:result];
    [self.dataStore updateFrequencyForStepIdentifier:APHMedicationTrackerFrequencyStepIdentifier result:result];
    return self.dataStore.selectedItems;
}

//- (NSArray *)selectedMedicationFromResult:(ORKTaskResult*)result
//                                        previousMedication:(NSArray <APHMedication*> *)previousMedication {
//
//    ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier];
//    ORKChoiceQuestionResult *selectionResult = (ORKChoiceQuestionResult *)[stepResult.results firstObject];
//
//    if (selectionResult == nil) {
//        return nil;
//    }
//    if (![selectionResult isKindOfClass:[ORKChoiceQuestionResult class]]) {
//        NSAssert(NO, @"The Medication selection result was not of the expected class of ORKChoiceQuestionResult");
//        return nil;
//    }
//    // If skipped return nil
//    if ((selectionResult.choiceAnswers == nil) ||
//        ([selectionResult.choiceAnswers isEqualToArray:@[APHMedicationTrackerSkipAnswerIdentifier]])) {
//        return nil;
//    }
//    
//    // Get the selected ids
//    NSArray *selectedMedIds = selectionResult.choiceAnswers;
//
//    // Get the selected meds by filtering this list
//    NSArray *selectedMeds = [self.medications filteredArrayWithIdentifiers:selectedMedIds];
//    if (selectedMeds.count > 0) {
//        // Map frequency from the previously stored results
//        NSPredicate *idPredicate = [NSPredicate predicateWithFormat:@"%K IN %@", NSStringFromSelector(@selector(identifier)), selectedMedIds];
//        NSPredicate *frequencyPredicate = [NSPredicate predicateWithFormat:@"%K > 0", NSStringFromSelector(@selector(frequency))];
//        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[frequencyPredicate, idPredicate]];
//        NSArray <SBAMedication *> *previousMeds = [previousMedication filteredArrayUsingPredicate:predicate];
//        if (previousMeds.count > 0) {
//            // If there are frequency results to map, then map them into the returned results
//            // (which may be a different object from the med list in the data store)
//            for (SBAMedication *med in selectedMeds) {
//                SBAMedication *previousMed = [previousMeds objectWithIdentifier:med.identifier];
//                med.frequency = previousMed.frequency;
//            }
//        }
//    }
//
//    return  selectedMeds;
//}

//- (NSArray <APHMedication*> *)updateMedicationFrequency:(NSArray <APHMedication*> *)selectedMedication
//                                             withResult:(ORKTaskResult*)result {
//    ORKStepResult *frequencyResult = (ORKStepResult *)[result resultForIdentifier:APHMedicationTrackerFrequencyStepIdentifier];
//    if (frequencyResult != nil) {
//        
//        // If there are frequency results to map, then map them into the returned results
//        // (which may be a different object from the med list in the data store)
//        for (SBAMedication *med in selectedMedication) {
//            ORKScaleQuestionResult *result = (ORKScaleQuestionResult *)[frequencyResult resultForIdentifier:med.identifier];
//            if ([result isKindOfClass:[ORKScaleQuestionResult class]]) {
//                med.frequency = [result.scaleAnswer unsignedIntegerValue];
//            }
//        }
//    }
//    
//    return selectedMedication;
//}

- (void)updateStateAfterStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    if ([step.identifier isEqualToString:APCDataGroupsStepIdentifier]) {
        // If this is a data groups step then save result to the data groups manager
        ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APCDataGroupsStepIdentifier];
        [self.dataGroupsManager setSurveyAnswerWithStepResult:stepResult];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
        // If this is the selection step or the frequency step then store the result to the data store
        [self.dataStore updateSelectedItems:self.medications stepIdentifier:step.identifier result:result];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
        // Update the frequency
        [self.dataStore updateFrequencyForStepIdentifier:step.identifier result:result];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerChangedStepIdentifier]) {
        ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APHMedicationTrackerChangedStepIdentifier];
        ORKBooleanQuestionResult *questionResult = (ORKBooleanQuestionResult *)[stepResult.results firstObject];
        self.medicationChanged = [questionResult.booleanAnswer boolValue];
    }
}

- (void)removeStepsAfterStep:(nullable ORKStep *)step {
    // Remove any steps after the current step because they are no longer part of the current path
    if (step != nil) {
        NSUInteger orderedIdx = [self.steps indexOfObject:step] + 1;
        if (orderedIdx < self.steps.count) {
            [self.steps removeObjectsInRange:NSMakeRange(orderedIdx, self.steps.count-orderedIdx)];
        }
    }
}

- (nullable ORKStep *)previousStepWithIdentifier:(NSString *)identifier {
    // First loop for the step in the mutable list of steps that have already been performed
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), identifier];
    return [[self.steps filteredArrayUsingPredicate:predicate] firstObject];
}

#pragma mark - ORKTask

- (nullable ORKStep *)stepAfterStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    
    // Setup variables for next steps
    NSUInteger nextIdx = 0;
    ORKStep *nextStep = nil;
    
    // Update current state
    [self updateStateAfterStep:step withResult:result];
    [self removeStepsAfterStep:step];

    if ((self.subTask != nil) && (step == nil)) {
        // The first step should come from the subtask if available
        nextStep = [self.subTask stepAfterStep:nil withResult:result];
    }
    else if (step.identifier != nil) {
        
        // Look for the next step in the medication tracker step list
        nextIdx = [self.medicationTrackerSteps indexOfObject:step];
        if (nextIdx == NSNotFound){
            NSArray *stepIdentifiers = [self.medicationTrackerSteps valueForKey:@"identifier"];
            nextIdx = [stepIdentifiers indexOfObject:step.identifier];
        }

        // If the step is not found then there should be a subtask
        if (nextIdx == NSNotFound) {
            NSAssert(self.subTask != nil, @"Step identifier not recognized.");
            if ([self indexOfStep:step] == 0) {
                // If this is the first step, then transition to the med steps
                nextIdx = 0;
            }
            else {
                // If this is NOT the first step after the subtask first step
                // then look for the next step in the subtask list
                nextStep = [self.subTask stepAfterStep:step withResult:result];
            }
        }
        else {
            // Otherwise increment the index
            nextIdx++;
        }
    }
    
    // Get the next step using a while loop in case one of the steps is not included
    while ((nextStep == nil) && (nextIdx != NSNotFound) && (nextIdx < self.medicationTrackerSteps.count)) {
        
        if ((nextIdx+1 == self.medicationTrackerSteps.count) && (self.subTask != nil)) {
            // If there is a subtask and this is the last step, then ignore it and get the
            // next step from the subtask
            ORKStep *firstStep = [self.steps firstObject];
            nextStep = [self.subTask stepAfterStep:firstStep withResult:result];
        }
        else {
            // Examine the next step in the medication list
            ORKStep *step = self.medicationTrackerSteps[nextIdx];
            if ([self shouldUpdateAndIncludeStep:step]) {
                nextStep = step;
            }
        }

        nextIdx++;
    }
    
    if (nextStep != nil) {
        [self.steps addObject:nextStep];
    }
    
    return nextStep;
}

- (nullable ORKStep *)stepBeforeStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    // Look for the step in the list of steps that have already been added to the mutable steps array
    NSUInteger idx = [self.steps indexOfObject:step];
    if ((idx != NSNotFound) && (idx > 0) && (idx < self.steps.count)) {
        return self.steps[idx - 1];
    }
    return nil;
}
    
- (NSUInteger)indexOfStep:(ORKStep *)step {
    // Get index of current step
    NSUInteger idx = [self.steps indexOfObject:step];
    if (idx == NSNotFound) {
        idx = [[self.steps valueForKey:NSStringFromSelector(@selector(identifier))] indexOfObject:step.identifier];
    }
    return idx;
}

- (nullable ORKStep *)stepWithIdentifier:(NSString *)identifier {
    
    // First loop for the step in the mutable list of steps that have already been performed
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), identifier];
    ORKStep *step = [[self.steps filteredArrayUsingPredicate:predicate] firstObject];
    
    // If not found, then look in the med steps
    if (step == nil) {
        step = [[self.medicationTrackerSteps filteredArrayUsingPredicate:predicate] firstObject];
    }
    
    // If not found, then look in the subtask
    if ((step == nil) && [self.subTask respondsToSelector:@selector(stepWithIdentifier:)]) {
        step = [self.subTask stepWithIdentifier:identifier];
    }
    
    return step;
}

- (ORKTaskProgress)progressOfCurrentStep:(ORKStep *)step withResult:(ORKTaskResult *)result {

    ORKTaskProgress progress;
    
    NSUInteger idx = [self indexOfStep:step];
    
    // Do not include the total number of steps (by default) b/c it will vary depending upon the answers
    // to the steps included in this task
    progress.current = idx;
    progress.total = 0;
    
    if ((idx > 0) && (idx != NSNotFound) && [self.subTask respondsToSelector:@selector(progressOfCurrentStep:withResult:)]) {
        ORKTaskProgress subtaskProgress = [self.subTask progressOfCurrentStep:step withResult:result];
        if ((subtaskProgress.total != 0) &&
            (subtaskProgress.current != NSNotFound) &&
            (subtaskProgress.current > 0)) {
            // If there is a total steps and we are not showing the intro step, then go ahead and display the progress
            progress.total = subtaskProgress.total + (idx - subtaskProgress.current);
        }
    }

    return progress;
}

- (void)validateParameters {
    if ([self.subTask respondsToSelector:@selector(validateParameters)]) {
        [self.subTask validateParameters];
    }
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForReading {
    if ([self.subTask respondsToSelector:@selector(requestedHealthKitTypesForReading)]) {
        return [self.subTask requestedHealthKitTypesForReading];
    }
    return nil;
}

- (NSSet<HKObjectType *> *)requestedHealthKitTypesForWriting {
    if ([self.subTask respondsToSelector:@selector(requestedHealthKitTypesForWriting)]) {
        return [self.subTask requestedHealthKitTypesForWriting];
    }
    return nil;
}

- (ORKPermissionMask)requestedPermissions {
    if ([self.subTask respondsToSelector:@selector(requestedPermissions)]) {
        return [self.subTask requestedPermissions];
    }
    return ORKPermissionNone;
}

- (BOOL)providesBackgroundAudioPrompts {
    return [self.subTask respondsToSelector:@selector(providesBackgroundAudioPrompts)] &&
        [self.subTask providesBackgroundAudioPrompts];
}

#pragma mark - ORKTaskResultSource

- (nullable ORKStepResult *)stepResultForStepIdentifier:(NSString *)stepIdentifier {
    if ([stepIdentifier isEqualToString:APCDataGroupsStepIdentifier]) {
        return self.dataGroupsManager.stepResult;
    }
    else if ([stepIdentifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
        NSArray *selectedMeds = self.dataStore.selectedItems;
        if (selectedMeds.count > 0) {
            ORKChoiceQuestionResult *result = [[ORKChoiceQuestionResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
            result.choiceAnswers = [selectedMeds identifiers];
            return [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerSelectionStepIdentifier results:@[result]];
        }
    }
    else if ([stepIdentifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
        NSMutableArray *results = [NSMutableArray new];
        for (SBAMedication *med in self.dataStore.selectedItems) {
            if (med.frequency > 0) {
                ORKScaleQuestionResult *result = [[ORKScaleQuestionResult alloc] initWithIdentifier:med.identifier];
                result.scaleAnswer = @(med.frequency);
                [results addObject:result];
            }
        }
        if (results.count > 0) {
            return [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerFrequencyStepIdentifier results:results];
        }
    }
    return nil;
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if ([self.subTask conformsToProtocol:@protocol(NSSecureCoding)]) {
        [aCoder encodeObject:self.subTask forKey:@"subTask"];
    }
    [aCoder encodeObject:self.mappingDictionary forKey:@"mappingDictionary"];
    [aCoder encodeObject:[self.steps copy] forKey:@"steps"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    id subTask = [aDecoder decodeObjectForKey:@"subTask"];
    NSDictionary *mappingDictionary = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"mappingDictionary"];
    self = [self initWithDictionaryRepresentation:mappingDictionary subTask:subTask];
    if (self) {
        _steps = [[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"steps"] mutableCopy];
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    APHMedicationTrackerTask *task = [[[self class] allocWithZone:zone] initWithDictionaryRepresentation:self.mappingDictionary subTask:self.subTask];
    task->_steps = [self.steps mutableCopy];
    return task;
}

#pragma mark - Equality

- (NSUInteger)hash {
    return [_identifier hash] | [_steps hash] | [_subTask hash] | [_mappingDictionary hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isMemberOfClass:[self class]]) {
        return NO;
    }
    if ((self.subTask != nil) && ![self.subTask isEqual:[object subTask]]) {
        return NO;
    }
    return  [self.mappingDictionary isEqualToDictionary:[object mappingDictionary]] &&
            [self.steps isEqualToArray:[object steps]];
    
}

@end
