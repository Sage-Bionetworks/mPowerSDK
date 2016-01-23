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
#import "APHMedicationTrackerDataStore.h"
#import "APHMedication.h"
#import "APHLocalization.h"

// Identifiers used by this task
NSString * const APHInstruction0StepIdentifier                      = @"instruction";
NSString * const APHConclusionStepIdentifier                        = @"conclusion";
NSString * const APHMedicationTrackerTaskIdentifier                 = @"Medication Tracker";
NSString * const APHMedicationTrackerSelectionStepIdentifier        = @"medicationSelection";
NSString * const APHMedicationTrackerFrequencyStepIdentifier        = @"medicationFrequency";
NSString * const APHMedicationTrackerMomentInDayStepIdentifier      = @"momentInDay";
NSString * const APHMedicationTrackerMomentInDayFormItemIdentifier  = @"momentInDayFormat";
NSString * const APHMedicationTrackerNoneAnswerIdentifier           = @"None";

@interface APHMedicationTrackerTask ()

@property (nonatomic, readonly) APCDataGroupsManager *dataGroupsManager;
@property (nonatomic, readonly) NSArray <NSString *> *stepIdentifiers;
@property (nonatomic) NSMutableArray <ORKStep *> *steps;

@end

@implementation APHMedicationTrackerTask

@synthesize identifier = _identifier;

+ (NSString*)pathForDefaultMapping {
    return [[APCAppDelegate sharedAppDelegate] pathForResource:@"MedicationTracking" ofType:@"json"];
}

+ (NSDictionary*)defaultMapping {
    static NSDictionary * _defaultMapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [self pathForDefaultMapping];
        NSData *json = [NSData dataWithContentsOfFile:path];
        if (json) {
            NSError *parseError;
            _defaultMapping = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:&parseError];
            if (parseError) {
                NSLog(@"Error parsing data group mapping: %@", parseError);
            }
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
        NSDictionary *mapping = dictionary ?: [[self class] defaultMapping];
        NSMutableArray *meds = [NSMutableArray new];
        for (NSDictionary * dictionary in mapping[@"items"]) {
            [meds addObject:[[APHMedication alloc] initWithDictionaryRepresentation:dictionary]];
        }
        _medications = [meds copy];
        
        // Create the ordered set
        _steps = [NSMutableArray new];
        _stepIdentifiers = @[APHInstruction0StepIdentifier,
                             APCDataGroupsStepIdentifier,
                             APHMedicationTrackerSelectionStepIdentifier,
                             APHMedicationTrackerFrequencyStepIdentifier,
                             APHMedicationTrackerMomentInDayStepIdentifier,
                             APHConclusionStepIdentifier];
    }
    return self;
}

- (APHMedicationTrackerDataStore *)dataStore {
    return [APHMedicationTrackerDataStore defaultStore];
}

- (APCDataGroupsManager *)dataGroupsManager {
    return self.dataStore.dataGroupsManager;
}

- (ORKStep*)createMedicationSelectionStep {
    
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_SELECT_MEDS_INTRO", nil, APHLocaleBundle(), @"We would like to understand how your performance on activities could be affected by your medications.", @"Medication tracking survey intro text.");
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier title:nil text:title];
    
    step.optional = NO;
    
    // Add the list of medications
    NSMutableArray *choices = [NSMutableArray new];
    for (APHMedication *med in self.medications) {
        [choices addObject:[ORKTextChoice choiceWithText:med.text value:med.identifier]];
    }
    
    // Add a choice for none of the above
    NSString *noneText = NSLocalizedStringWithDefaultValue(@"APH_NONE_OF_THE_ABOVE", nil, APHLocaleBundle(), @"None of the above", @"Text for a selection choice indicating that none of the options was applicable.");
    [choices addObject:[ORKTextChoice choiceWithText:noneText value:APHMedicationTrackerNoneAnswerIdentifier]];
    
    // Create the answer format
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:choices];
    
    // Create the question
    NSString *questionText = NSLocalizedStringWithDefaultValue(@"APH_SELECT_MEDS_QUESTION", nil, APHLocaleBundle(),
    @"Select all the Parkinson's Medications that you are currently taking.", @"Medication tracking survey question text.");
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier
                                                            text:questionText
                                                    answerFormat:format];
    [step setFormItems:@[item]];
    
    return step;
}

- (ORKStep*)createFrequencyStepFromResult:(ORKTaskResult *)result {
    
    NSArray <APHMedication *> *meds = [self selectedMedicationFromResult:result trackingOnly:NO pillOnly:YES];
    if (meds.count == 0) {
        return nil;
    }
    
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_MEDS_FREQENCY_INTRO", nil, APHLocaleBundle(), @"How many times a day do you take each of the following medications?", @"Medication tracking survey fequency selection text.");
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerFrequencyStepIdentifier title:nil text:title];
    
    // Add the list of medications
    NSMutableArray *items = [NSMutableArray new];
    for (APHMedication *med in meds) {
        ORKAnswerFormat *answerFormat = [[ORKScaleAnswerFormat alloc] initWithMaximumValue:12 minimumValue:1 defaultValue:0 step:1];
        ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:med.identifier
                                                                text:med.text
                                                        answerFormat:answerFormat];
        [items addObject:item];
    }
    
    [step setFormItems:items];
    
    return step;
}

- (ORKStep*)createMomentInDayStep
{
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_INTRO", nil, APHLocaleBundle(), @"We would like to understand how your performance on this activity could be affected by the timing of your medication.", @"Explanation of purpose of pre-activity medication timing survey.");
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:APHMedicationTrackerMomentInDayStepIdentifier title:nil text:title];
    
    step.optional = NO;
    
    NSString *itemTextFormat = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_QUESTION", nil, APHLocaleBundle(), @"When was the last time you took your %@?", @"Prompt for timing of medication in pre-activity medication timing survey where %@ is a list of medications (For example, 'Levodopa or Rytary')");
    NSString *orWord = NSLocalizedStringWithDefaultValue(@"APH_OR_FORMAT", nil, APHLocaleBundle(), @"or", @"Format of a list with two items using the OR key word.");
    NSString *listDelimiter = NSLocalizedStringWithDefaultValue(@"APH_LIST_FORMAT_DELIMITER", nil, APHLocaleBundle(), @",", @"Delimiter for a list of more than 3 items. (For example, 'Levodopa, Simet or Rytary')");
    
    NSMutableString *listText = [NSMutableString new];
    NSArray <NSString *> *medList = self.dataStore.trackedMedications;
    [medList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop __unused) {
        if (medList.count > 1) {
            if (idx+1 == medList.count) {
                [listText appendFormat:@" %@ ", orWord];
            }
            else if (idx != 0) {
                [listText appendFormat:@"%@ ", listDelimiter];
            }
        }
        [listText appendString:obj];
    }];
    NSString *itemText = [NSString stringWithFormat:itemTextFormat, listText];
    
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:[self momentInDayChoices]];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:APHMedicationTrackerMomentInDayFormItemIdentifier
                                                            text:itemText
                                                    answerFormat:format];
    [step setFormItems:@[item]];
    
    return step;
}

- (NSArray <ORKTextChoice *> *) momentInDayChoices
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
    addInterval(2 * 60, 0);
    
    // Add the "not sure" choice to both the choices array and the map
    [choices addObject:[ORKTextChoice choiceWithText:
                        NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_NOT_SURE", nil, APHLocaleBundle(), @"Not sure", @"Timing option text in pre-activity medication timing survey for someone who is unsure of when medication was last taken.")
                                               value:@"Not sure"]];
    
    // Copy the arrays to static values
    return [choices copy];
}

- (ORKStep*)createConclusionStep
{
    ORKInstructionStep *step = [ORKInstructionStep completionStep];
    // Replace the language in the last step
    step.title = [APHLocalization localizedStringWithKey:@"APH_ACTIVITY_CONCLUSION_TEXT"];
    step.text = @"";
    return step;
}

- (NSArray <APHMedication *> * _Nullable)selectedMedicationFromResult:(ORKTaskResult *)result
                                               trackingOnly:(BOOL)trackingOnly
                                                   pillOnly:(BOOL)pillOnly {
    
    ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    ORKChoiceQuestionResult *selectionResult = (ORKChoiceQuestionResult *)[stepResult.results firstObject];

    if (selectionResult == nil) {
        return nil;
    }
    if (![selectionResult isKindOfClass:[ORKChoiceQuestionResult class]]) {
        NSAssert(NO, @"The Medication selection result was not of the expected class of ORKChoiceQuestionResult");
        return nil;
    }
    if (selectionResult.choiceAnswers == nil) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", NSStringFromSelector(@selector(identifier)), selectionResult.choiceAnswers];
    if (trackingOnly) {
        NSPredicate *trackingPredicate = [NSPredicate predicateWithFormat:@"%K = YES", NSStringFromSelector(@selector(tracking))];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, trackingPredicate]];
    }
    if (pillOnly) {
        NSPredicate *pillPredicate = [NSPredicate predicateWithFormat:@"%K = NO", NSStringFromSelector(@selector(injection))];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, pillPredicate]];
    }
    
    return [self.medications filteredArrayUsingPredicate:predicate];
}

- (void)updateStateAfterStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    if ([step.identifier isEqualToString:APCDataGroupsStepIdentifier]) {
        // If this is a data groups step then save result to the data groups manager
        ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APCDataGroupsStepIdentifier];
        [self.dataGroupsManager setSurveyAnswerWithStepResult:stepResult];
    }
    else if ([step.identifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
        // If this is the selection step then store the result to the data store
        NSArray <APHMedication *> *meds = [self selectedMedicationFromResult:result trackingOnly:YES pillOnly:NO];
        self.dataStore.trackedMedications = [meds valueForKey:NSStringFromSelector(@selector(shortText))];
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

- (BOOL)shouldIncludeMedicationSelectionStep {
    if (self.dataGroupsManager.isStudyControlGroup) {
        // Do not include if this is the control group
        return NO;
    }
    else if (self.subTask != nil) {
        // If there is a subtask then include only if the question has no answer and hasn't been skipped
        return !self.dataStore.hasSelectedMedicationOrSkipped;
    }
    return YES;
}

#pragma mark - ORKTask

- (nullable ORKStep *)stepAfterStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    
    // Setup variables for next steps
    NSUInteger nextIdx = 0;
    ORKStep *nextStep = nil;
    NSString *nextStepIdentifier = nil;
    
    // Update current state
    [self updateStateAfterStep:step withResult:result];
    [self removeStepsAfterStep:step];

    // Get the next step identifier in the ordered list of identifiers
    if (step.identifier != nil) {
        nextIdx = [self.stepIdentifiers indexOfObject:step.identifier];
        if (nextIdx == NSNotFound) {
            // If the index is not found in the list then look for it in the subtask
            NSAssert(self.subTask != nil, @"Step identifier not recognized.");
            nextStep = [self.subTask stepAfterStep:step withResult:result];
            nextStepIdentifier = nextStep.identifier;
        }
        else {
            // Otherwise increment the index
            nextIdx++;
        }
    }
    
    // Get the next step using a while loop in case the frequency step is nil for this result
    while ((nextStep == nil) && (nextIdx != NSNotFound) && (nextIdx < self.stepIdentifiers.count)) {
        
        // If a step is only conditionally included, then nest the if statement
        // so that we don't hit the assert. In the case where the conditional is
        // not fullfilled (nextStep == nil), then the code will loop through to
        // check the next step that is included in the list of step identifiers.

        nextStepIdentifier = self.stepIdentifiers[nextIdx];
        if ([nextStepIdentifier isEqualToString:APHInstruction0StepIdentifier]) {
            nextStep = [self.subTask stepAfterStep:nil withResult:result];
        }
        else if ([nextStepIdentifier isEqualToString:APCDataGroupsStepIdentifier]) {
            if ([self.dataGroupsManager needsUserInfoDataGroups]) {
                nextStep = [self.dataGroupsManager surveyStep];
            }
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
            if ([self shouldIncludeMedicationSelectionStep])
            {
                nextStep = [self createMedicationSelectionStep];
            }
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
            nextStep = [self createFrequencyStepFromResult:result];
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerMomentInDayStepIdentifier]) {
            if ((self.subTask != nil) && self.dataStore.shouldIncludeMomentInDayStep) {
                nextStep = [self createMomentInDayStep];
            }
        }
        else if ([nextStepIdentifier isEqualToString:APHConclusionStepIdentifier]) {
            if (self.subTask) {
                // If there is a subtask then get the step after the first step in the list since all the
                // other steps were injected prior to the second step in the subtask
                ORKStep *firstStep = [self.steps firstObject];
                nextStep = [self.subTask stepAfterStep:firstStep withResult:result];
                nextStepIdentifier = nextStep.identifier;
            }
            else {
                nextStep = [self createConclusionStep];
            }
        }
        else {
            NSAssert1(NO, @"Medication Tracker Task for next step with identifier %@ is not recognized.", nextStepIdentifier);
        }

        nextIdx++;
    }
    
    // If the next step is not nil, then add to the tracking array
    if (nextStep != nil) {
        // Check to make sure that the identifier matches the expected identifier
        // If not, then replace the step identinfier in the list
        if (![nextStep.identifier isEqualToString:nextStepIdentifier]) {
            NSUInteger idx = [self.stepIdentifiers indexOfObject:nextStepIdentifier];
            if (idx != NSNotFound) {
                NSMutableArray *mutuableStepIdentifiers = [self.stepIdentifiers mutableCopy];
                [mutuableStepIdentifiers replaceObjectAtIndex:idx withObject:nextStep.identifier];
                _stepIdentifiers = [mutuableStepIdentifiers copy];
            }
        }
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

- (nullable ORKStep *)stepWithIdentifier:(NSString *)identifier {
    
    // First loop for the step in the mutable list of steps that have already been performed
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), identifier];
    ORKStep *step = [[self.steps filteredArrayUsingPredicate:predicate] firstObject];
    
    // If not found, then look in the subtask
    if ((step == nil) && [self.subTask respondsToSelector:@selector(stepWithIdentifier:)]) {
        step = [self.subTask stepWithIdentifier:identifier];
    }
    
    return step;
}

- (ORKTaskProgress)progressOfCurrentStep:(ORKStep *)step withResult:(ORKTaskResult *)result {

    ORKTaskProgress progress;
    
    // Get index of current step
    NSUInteger idx = [self.steps indexOfObject:step];
    if (idx == NSNotFound) {
        idx = [[self.steps valueForKey:NSStringFromSelector(@selector(identifier))] indexOfObject:step.identifier];
    }
    
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

@end
