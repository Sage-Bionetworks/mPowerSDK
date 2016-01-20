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
#import "APHActivityManager.h"
#import "APHMedication.h"
#import "APHLocalization.h"

NSString * const APHMedicationTrackerTaskIdentifier = @"Medication Tracker";
NSString * const APHMedicationTrackerSelectionStepIdentifier = @"medication.selection";
NSString * const APHMedicationTrackerFrequencyStepIdentifier = @"medication.frequency";
NSString * const APHMedicationTrackerConclusionStepIdentifier = @"conclusion";
NSString * const APHMedicationTrackerNoneAnswerIdentifier = @"None";

@interface APHMedicationTrackerTask ()

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
    return [self initWithDictionaryRepresentation:nil dataGroupsManager:nil];
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary dataGroupsManager:(APCDataGroupsManager*)dataGroupsManager {
    self = [super init];
    if (self) {
        _identifier = [APHMedicationTrackerTaskIdentifier copy];
        
        // map the medications
        NSDictionary *mapping = dictionary ?: [[self class] defaultMapping];
        NSMutableArray *meds = [NSMutableArray new];
        for (NSDictionary * dictionary in mapping[@"items"]) {
            [meds addObject:[[APHMedication alloc] initWithDictionaryRepresentation:dictionary]];
        }
        _medications = [meds copy];
        
        // Create the ordered set
        _steps = [NSMutableArray new];
        _stepIdentifiers = @[APCDataGroupsStepIdentifier,
                             APHMedicationTrackerSelectionStepIdentifier,
                             APHMedicationTrackerFrequencyStepIdentifier,
                             APHMedicationTrackerConclusionStepIdentifier];
        
        // attach data groups manager
        _dataGroupsManager = dataGroupsManager ?: [[APCAppDelegate sharedAppDelegate] dataGroupsManagerForUser:nil];
    }
    return self;
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

- (ORKStep*)createConclusionStep {
    ORKInstructionStep *step = [ORKInstructionStep completionStep];
    // Replace the language in the last step
    step.title = [[APHActivityManager defaultManager] completionStepTitle];
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

#pragma mark - ORKTask

- (nullable ORKStep *)stepAfterStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    
    // If this is a data groups step then save result to the data groups manager
    if ([step.identifier isEqualToString:APCDataGroupsStepIdentifier]) {
        ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:APCDataGroupsStepIdentifier];
        [self.dataGroupsManager setSurveyAnswerWithStepResult:stepResult];
    }
    
    // Remove any steps after the current step
    if (step != nil) {
        NSUInteger orderedIdx = [self.steps indexOfObject:step] + 1;
        if (orderedIdx < self.steps.count) {
            [self.steps removeObjectsInRange:NSMakeRange(orderedIdx, self.steps.count-orderedIdx)];
        }
    }
    
    // Get the next step identifier in the ordered list of identifiers
    NSUInteger nextIdx = 0;
    if (step.identifier != nil) {
        nextIdx = [self.stepIdentifiers indexOfObject:step.identifier];
        if (nextIdx == NSNotFound) {
            NSAssert(NO, @"Step identifier not recognized.");
            return nil;
        }
        nextIdx++;
    }
    
    // Get the next step using a while loop in case the frequency step is nil for this result
    ORKStep *nextStep = nil;
    while ((nextStep == nil) && (nextIdx < self.stepIdentifiers.count)) {

        NSString *nextStepIdentifier = self.stepIdentifiers[nextIdx];
        if ([nextStepIdentifier isEqualToString:APCDataGroupsStepIdentifier]) {
            // Nest the if statement so that we don't hit the assert
            if ([self.dataGroupsManager needsUserInfoDataGroups]) {
                nextStep = [self.dataGroupsManager surveyStep];
            }
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier]) {
            // If the data groups have been changed and the data group is now control, then
            // don't ask the question about selecting medication
            if (!self.dataGroupsManager.hasChanges || ![self.dataGroupsManager isStudyControlGroup]) {
                nextStep = [self createMedicationSelectionStep];
            }
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
            nextStep = [self createFrequencyStepFromResult:result];
        }
        else if ([nextStepIdentifier isEqualToString:APHMedicationTrackerConclusionStepIdentifier]) {
            nextStep = [self createConclusionStep];
        }
        else {
            NSAssert1(NO, @"Medication Tracker Task for next step with identifier %@ is not recognized.", nextStepIdentifier);
        }

        nextIdx++;
    }
    
    // If the next step is not nil, then add to the tracking array
    if (nextStep != nil) {
        [self.steps addObject:nextStep];
    }
    
    return nextStep;
}

- (nullable ORKStep *)stepBeforeStep:(nullable ORKStep *)step withResult:(ORKTaskResult *)result {
    NSUInteger idx = [self.steps indexOfObject:step];
    if ((idx != NSNotFound) && (idx > 0) && (idx < self.steps.count)) {
        return self.steps[idx - 1];
    }
    return nil;
}

- (nullable ORKStep *)stepWithIdentifier:(NSString *)identifier {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), identifier];
    return [[self.steps filteredArrayUsingPredicate:predicate] firstObject];
}

@end
