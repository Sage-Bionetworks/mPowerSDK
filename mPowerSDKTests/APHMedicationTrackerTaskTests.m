//
//  APHMedicationTrackerTaskTests.m
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

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <mPowerSDK/mPowerSDK.h>

#import "MockAPHMedicationTrackerTask.h"
#import "MockORKTask.h"

@interface APHMedicationTrackerTaskTests : XCTestCase

@end

@implementation APHMedicationTrackerTaskTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test step creation methods

- (void)testCreateIntroductionStep_Default_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHMedicationTrackerTask *task = [self createTask];

    ORKStep *step = [task createStepFromMappingDictionary:@{@"identifier" : APHMedicationTrackerIntroductionStepIdentifier}];
    XCTAssertNotNil(step);
    
    XCTAssertEqualObjects(step.title,  @"Medication Survey");
    XCTAssertNotNil(step.text);
}

- (void)testCreateIntroductionStep_Custom
{
    APHMedicationTrackerTask *task = [self createTask];
    
    ORKStep *step = [task createStepFromMappingDictionary:@{@"identifier" : APHMedicationTrackerIntroductionStepIdentifier,
                                                            @"title" : @"foo",
                                                            @"text" : @"bar"}];
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.identifier, APHMedicationTrackerIntroductionStepIdentifier);
    XCTAssertEqualObjects(step.title,  @"foo");
    XCTAssertEqualObjects(step.text, @"bar");
}

- (void)testCreateMedicationChangedStep_Custom
{
    APHMedicationTrackerTask *task = [self createTask];
    
    ORKStep *step = [task createStepFromMappingDictionary:@{@"identifier" : APHMedicationTrackerChangedStepIdentifier,
                                                            @"title" : @"foo",
                                                            @"text" : @"bar"}];
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.identifier, APHMedicationTrackerChangedStepIdentifier);
    XCTAssertEqualObjects(step.title,  @"foo");
    XCTAssertEqualObjects(step.text, @"bar");
}

- (void)testCreateMedicationSelectionStep_Custom_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHMedicationTrackerTask *task = [self createTask];
    
    ORKStep *step = [task createStepFromMappingDictionary:@{@"identifier" : APHMedicationTrackerSelectionStepIdentifier,
                                                            @"title" : @"foo",
                                                            @"text" : @"bar",
                                                            @"optional" : @(YES)}];
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.title,  @"foo");
    XCTAssertEqualObjects(step.text, @"bar");
    XCTAssertFalse(step.optional);
    
    ORKFormStep *formStep = (ORKFormStep*)step;
    XCTAssertTrue([step isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqual(formStep.formItems.count, 1);
    
    ORKFormItem *formItem = [formStep.formItems firstObject];
    ORKTextChoiceAnswerFormat *answerFormat = (ORKTextChoiceAnswerFormat *)formItem.answerFormat;
    XCTAssertEqual(answerFormat.style, ORKChoiceAnswerStyleMultipleChoice);
    XCTAssertTrue([formItem.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]);
    NSArray *expectedChoices = @[@"Levodopa",
                                 @"Carbidopa",
                                 @"Carbidopa/Levodopa (Rytary)",
                                 @"Carbidopa/Levodopa (Sinemet)",
                                 @"Carbidopa/Levodopa (Atamet)",
                                 @"Carbidopa/Levodopa/Entacapone (Stalevo)",
                                 @"Amantadine (Symmetrel)",
                                 @"Rotigotine (Neupro)",
                                 @"Selegiline (Eldepryl)",
                                 @"Selegiline (Carbex)",
                                 @"Selegiline (Atapryl)",
                                 @"Pramipexole (Mirapex)",
                                 @"Ropinirole (Requip)",
                                 @"Apomorphine (Apokyn)",
                                 @"Carbidopa/Levodopa Continuous Infusion (Duopa)",
                                 @"None of the above",
                                 @"Prefer not to answer"];
    NSArray *actualChoices = [answerFormat.textChoices valueForKey:@"text"];
    XCTAssertEqualObjects(actualChoices, expectedChoices);
    XCTAssertEqual(actualChoices.count, expectedChoices.count);
    for (NSUInteger idx=0; idx < actualChoices.count && idx < expectedChoices.count; idx++) {
        XCTAssertEqualObjects(actualChoices[idx], expectedChoices[idx], @"idx=%@", @(idx));
        
        // Last two choices should be exclusive (Cannot select in combination with other choices)
        BOOL exclusive = (idx >= expectedChoices.count - 2);
        XCTAssertEqual(answerFormat.textChoices[idx].exclusive, exclusive);
    }
}

- (void)testCreateMedicationSelectionStep_Default_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHMedicationTrackerTask *task = [self createTask];
    
    ORKStep *step = [task createStepFromMappingDictionary:@{@"identifier" : APHMedicationTrackerSelectionStepIdentifier}];
    XCTAssertNotNil(step);
    XCTAssertFalse(step.optional);
    XCTAssertNil(step.title);
    XCTAssertNotNil(step.text);
    
    // Check that prefer not to answer is *not* included
    ORKFormStep *formStep = (ORKFormStep*)step;
    ORKFormItem *formItem = [formStep.formItems firstObject];
    ORKTextChoiceAnswerFormat *answerFormat = (ORKTextChoiceAnswerFormat *)formItem.answerFormat;
    NSString *lastChoice = [[answerFormat.textChoices valueForKey:@"text"] lastObject];
    XCTAssertEqualObjects(lastChoice, @"None of the above");
}

- (void)testCreateFrequencyStepWithSelectedMedication_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHMedicationTrackerTask *task = [self createTask];
    
    task.dataStore.selectedMedications = @[[[APHMedication alloc] initWithDictionaryRepresentation:@{@"name" : @"Levodopa",
                                                                                 @"tracking" : @(true)}],
                                           [[APHMedication alloc] initWithDictionaryRepresentation:@{@"name" : @"Amantadine",
                                                                                @"brand" : @"Symmetrel",
                                                                                @"tracking" : @(true)}]];
    
    ORKStep *step = [task stepWithIdentifier:APHMedicationTrackerFrequencyStepIdentifier];

    
    
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    
    BOOL shouldInclude = [task shouldUpdateAndIncludeStep:step];
    XCTAssertTrue(shouldInclude);
    
    XCTAssertFalse(step.optional);
    XCTAssertTrue([step isKindOfClass:[ORKFormStep class]]);
    
    ORKFormStep *frequencyStep = (ORKFormStep*)step;
    XCTAssertEqualObjects(frequencyStep.text, @"How many times a day do you take each of the following medications?");
    XCTAssertEqual(frequencyStep.formItems.count, 2);
    
    NSArray *expectedText = @[@"Levodopa", @"Amantadine (Symmetrel)"];
    NSArray *expectedIdentifier = @[@"Levodopa", @"Symmetrel"];
    for (NSUInteger idx=0; idx < frequencyStep.formItems.count; idx++) {
        ORKFormItem *item = frequencyStep.formItems[idx];
        XCTAssertEqualObjects(item.text, expectedText[idx]);
        XCTAssertEqualObjects(item.identifier, expectedIdentifier[idx]);
        XCTAssertTrue([item.answerFormat isKindOfClass:[ORKScaleAnswerFormat class]]);
        ORKScaleAnswerFormat *answerFormat = (ORKScaleAnswerFormat *)item.answerFormat;
        XCTAssertEqual(answerFormat.minimum, 1);
        XCTAssertEqual(answerFormat.maximum, 12);
        XCTAssertEqual(answerFormat.step, 1);
    }
}

- (void)testCreateActivityTimingStep_English
{
    // set to the English bundle
    [APHLocalization setLocalization:@"en"];
    
    // Get the medication tracking step
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa"]];
    ORKFormStep *step = (ORKFormStep *)[task stepWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier];
    BOOL shouldInclude = [task shouldUpdateAndIncludeStep:step];
    
    // Check assumptions
    XCTAssertFalse(step.optional);
    XCTAssertNotNil(step);
    XCTAssertTrue([step isKindOfClass:[ORKFormStep class]]);
    XCTAssertTrue(shouldInclude);
    XCTAssertEqualObjects(step.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    
    // Check the language
    XCTAssertNil(step.text);
    
    ORKFormItem  *item = [step.formItems firstObject];
    XCTAssertEqual(step.formItems.count, 1);
    XCTAssertEqualObjects(item.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa?");
    XCTAssertTrue([item.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]);
    
    NSArray <NSString *> *expected = @[@"0-30 minutes ago",
                                      @"30-60 minutes ago",
                                      @"1-2 hours ago",
                                      @"2-4 hours ago",
                                      @"4-8 hours ago",
                                      @"More than 8 hours ago",
                                      @"Not sure"];
    
    NSArray <ORKTextChoice *> *choices = ((ORKTextChoiceAnswerFormat*)item.answerFormat).textChoices;
    XCTAssertEqual(choices.count, expected.count);
    
    for (int ii=0; ii < expected.count && ii < choices.count; ii++) {
        XCTAssertEqualObjects(choices[ii].text, expected[ii]);
        XCTAssertEqualObjects(choices[ii].value, expected[ii]);
    }
}

- (void)testCreateMomentInDayStep_NameOnly_English
{
    // Get the medication tracking step
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa"]];
    ORKFormStep *step = (ORKFormStep *)[task stepWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier];
    [task shouldUpdateAndIncludeStep:step];
    ORKFormItem  *item = [step.formItems firstObject];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa?");
}

- (void)testCreateMomentInDayStep_2x_English
{
    // Get the medication tracking step
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa", @"Sinemet"]];
    ORKFormStep *step = (ORKFormStep *)[task stepWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier];
    [task shouldUpdateAndIncludeStep:step];
    ORKFormItem  *item = [step.formItems firstObject];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa or Sinemet?");
}

- (void)testCreateMomentInDayStep_3x_English
{
    // Get the medication tracking step
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa", @"Rytary", @"Sinemet"]];
    ORKFormStep *step = (ORKFormStep *)[task stepWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier];
    [task shouldUpdateAndIncludeStep:step];
    ORKFormItem  *item = [step.formItems firstObject];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa, Rytary, or Sinemet?");
}

- (void)testCreateMomentInDayStep_4x_English
{
    // Get the medication tracking step
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa", @"Rytary", @"Sinemet", @"Stalevo"]];
    ORKFormStep *step = (ORKFormStep *)[task stepWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier];
    [task shouldUpdateAndIncludeStep:step];
    ORKFormItem  *item = [step.formItems firstObject];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa, Rytary, Sinemet, or Stalevo?");
}

- (void)testCreateConclusionStep {
    [APHLocalization setLocalization:@"en"];
    
    APHMedicationTrackerTask *task = [self createTask];
    ORKStep *step = [task stepWithIdentifier:APHMedicationTrackerConclusionStepIdentifier];
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.title, @"Thank You!");
}

#pragma mark - Test step order w/o subtask

- (void)testStepsUpToSelection_NoDataGroup_ThenPD {
    [self createAndStepToSelectionWithSubTask:nil initialDataGroup:nil selectedDataGroup:[MockPDResult new]];
}

- (void)testStepsUpToSelection_NoDataGroup_ThenControl {
    [self createAndStepToSelectionWithSubTask:nil initialDataGroup:nil selectedDataGroup:[MockControlResult new]];
}

- (void)testStepsUpToSelection_NoDataGroup_ThenSkipped {
    [self createAndStepToSelectionWithSubTask:nil initialDataGroup:nil selectedDataGroup:[MockSkipResult new]];
}

- (void)testStepsUpToSelection_WithInitialDataGroup_ThenControl {
    [self createAndStepToSelectionWithSubTask:nil
                             initialDataGroup:[MockPDResult new]
                            selectedDataGroup:[MockControlResult new]];
}

- (void)testFollowUpSteps_NoMedicationSelected {
    APHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask:nil
                                                              initialDataGroup:nil
                                                             selectedDataGroup:[MockPDResult new]];
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // For the case where there is no subtask and no medication was selected,
    // the survey is complete
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier]];
    ORKStep *nextStep = [task stepAfterStep:selectionStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertEqualObjects(nextStep.identifier, APHMedicationTrackerConclusionStepIdentifier);
    
    // And the results from the selection should be stored back to the data store
    XCTAssertEqual(task.dataStore.selectedMedications.count, 0);
    XCTAssertTrue(task.dataStore.hasChanges);
    XCTAssertFalse(task.dataStore.skippedSelectMedicationsSurveyQuestion);
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testFollowUpSteps_MedicationSkipped {
    APHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask:nil
                                                              initialDataGroup:nil
                                                             selectedDataGroup:[MockPDResult new]];
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // For the case where there is no subtask and no medication was selected,
    // the survey is complete
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[APHMedicationTrackerSkipAnswerIdentifier]];
    ORKStep *nextStep = [task stepAfterStep:selectionStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertEqualObjects(nextStep.identifier, APHMedicationTrackerConclusionStepIdentifier);
    
    // And the results from the selection should be stored back to the data store
    XCTAssertEqual(task.dataStore.selectedMedications.count, 0);
    XCTAssertTrue(task.dataStore.hasChanges);
    XCTAssertTrue(task.dataStore.skippedSelectMedicationsSurveyQuestion);
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testFollowUpSteps_InjectionSelected {
    APHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask:nil
                                                              initialDataGroup:nil
                                                             selectedDataGroup:[MockPDResult new]];
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // Next step should be for frequency
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[@"Apokyn"]];
    ORKStep *nextStep = [task stepAfterStep:selectionStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertEqualObjects(nextStep.identifier, APHMedicationTrackerConclusionStepIdentifier);
    
    // And the results from the selection should be stored back to the data store
    XCTAssertEqual(task.dataStore.selectedMedications.count, 1);
    XCTAssertEqualObjects(task.dataStore.selectedMedications.firstObject.identifier, @"Apokyn");
    XCTAssertTrue(task.dataStore.hasChanges);
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testFollowUpSteps_PillsSelected {
    APHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask:nil
                                                              initialDataGroup:nil
                                                             selectedDataGroup:[MockPDResult new]];
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // Next step should be for frequency
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[@"Levodopa", @"Symmetrel", @"Apokyn"]];
    ORKFormStep *frequencyStep = (ORKFormStep*)[task stepAfterStep:selectionStep withResult:result];
    XCTAssertNotNil(frequencyStep);
    XCTAssertTrue([frequencyStep isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqualObjects(frequencyStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertTrue([frequencyStep isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqual(frequencyStep.formItems.count, 2);
    
    // And the results from the selection should be stored back to the data store
    XCTAssertEqual(task.dataStore.selectedMedications.count, 3);
    XCTAssertTrue(task.dataStore.hasChanges);
    
    // Add frequency question result
    ORKScaleQuestionResult *levodopaResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Levodopa"];
    levodopaResult.scaleAnswer = @(4);
    ORKScaleQuestionResult *symmetrelResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Symmetrel"];
    symmetrelResult.scaleAnswer = @(7);
    ORKStepResult *frequencyStepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerFrequencyStepIdentifier
                                                                               results:@[levodopaResult, symmetrelResult]];
    result.results = [result.results arrayByAddingObject:frequencyStepResult];

    // Next step should be for thank you
    ORKStep *nextStep = [task stepAfterStep:frequencyStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertEqualObjects(nextStep.identifier, APHMedicationTrackerConclusionStepIdentifier);
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
    
    // The selected medication list should now include the frequency
    NSArray <APHMedication *> *selectedMeds = task.dataStore.selectedMedications;
    APHMedication *levodopa = [selectedMeds objectWithIdentifier:@"Levodopa"];
    XCTAssertNotNil(levodopa);
    XCTAssertEqual(levodopa.frequency, 4);
    APHMedication *symmetrel = [selectedMeds objectWithIdentifier:@"Symmetrel"];
    XCTAssertNotNil(symmetrel);
    XCTAssertEqual(symmetrel.frequency, 7);
    APHMedication *apokyn = [selectedMeds objectWithIdentifier:@"Apokyn"];
    XCTAssertNotNil(apokyn);
    XCTAssertEqual(apokyn.frequency, 0);
}

- (void)testStepBackAndForward {
    
    APHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask:nil
                                                              initialDataGroup:nil
                                                             selectedDataGroup:[MockPDResult new]];
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // Get the second step
    ORKFormStep *frequencyStep = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa", @"Carbidopa"]]];
    
    // Check assumptions
    XCTAssertEqualObjects(selectionStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    XCTAssertEqualObjects(frequencyStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqual(frequencyStep.formItems.count, 2);
    
    // The step before the frequency step should be the selection step (and does not depend upon result)
    ORKTaskResult *blankResult = [[ORKTaskResult alloc] initWithIdentifier:task.identifier];
    ORKStep *backOnceFromFrequencyStep = [task stepBeforeStep:frequencyStep withResult:blankResult];
    XCTAssertEqualObjects(backOnceFromFrequencyStep, selectionStep);
    
    // With a different result from the selection step, the frenquency step should change
    ORKFormStep *frequencyStepB = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa"]]];
    XCTAssertNotNil(frequencyStepB);
    XCTAssertEqualObjects(frequencyStepB.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertTrue([frequencyStepB isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqual(frequencyStepB.formItems.count, 1);
    
    // The step before the new frequency step should still be the selection step
    ORKStep *stepBeforeFrequencyB = [task stepBeforeStep:frequencyStepB withResult:blankResult];
    XCTAssertEqualObjects(stepBeforeFrequencyB, selectionStep);
    
    // With No medication selected result from the selection step, the frequency step should not be included
    ORKTaskResult *noneResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier]];
    ORKFormStep *afterSelectionNoMedsStep = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                      withResult:noneResult];
    XCTAssertEqualObjects(afterSelectionNoMedsStep.identifier, APHMedicationTrackerConclusionStepIdentifier);
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:afterSelectionNoMedsStep withResult:noneResult]);
}

#pragma mark - Series of tests for showing Data groups step and/or medication tracking steps prior to another task


- (void)testPrefixToOrderedTask_NeedsChangeQuestion_ThenNo {

    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[]];
    ORKOrderedTask *subtask = (ORKOrderedTask *)task.subTask;
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:nil];
    
    // Setup to need to ask about changed meds
    task.dataStore.lastMedicationSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-32*24*60*60];
    
    // If there is a subtask then the first step should be the step from the subtask
    ORKStep *preStep =[task stepAfterStep:nil withResult:taskResult];
    XCTAssertNotNil(preStep);
    XCTAssertEqualObjects(preStep, subtask.steps.firstObject);
    
    // Next step should be the changed meds step
    ORKStep *changedStep = [task stepAfterStep:preStep withResult:taskResult];
    XCTAssertNotNil(changedStep);
    XCTAssertEqualObjects(changedStep.identifier, APHMedicationTrackerChangedStepIdentifier);
    
    // If the answer to the question is "NO" then continue to the task
    ORKBooleanQuestionResult *changedResult = [[ORKBooleanQuestionResult alloc] initWithIdentifier:APHMedicationTrackerChangedStepIdentifier];
    changedResult.booleanAnswer = @NO;
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerChangedStepIdentifier results:@[changedResult]];
    taskResult.results = @[stepResult];
    
    [self checkStepOrder:task taskResult:taskResult startStep:changedStep startIndex:1 addedStepCount:1];
}

- (void)testPrefixToOrderedTask_NeedsChangeQuestion_ThenYes {
    
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[]];
    ORKOrderedTask *subtask = (ORKOrderedTask *)task.subTask;
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:nil];
    
    // Setup to need to ask about changed meds
    task.dataStore.lastMedicationSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-32*24*60*60];
    
    // If there is a subtask then the first step should be the step from the subtask
    ORKStep *preStep =[task stepAfterStep:nil withResult:taskResult];
    XCTAssertNotNil(preStep);
    XCTAssertEqualObjects(preStep, subtask.steps.firstObject);
    
    // Next step should be the changed meds step
    ORKStep *changedStep = [task stepAfterStep:preStep withResult:taskResult];
    XCTAssertNotNil(changedStep);
    XCTAssertEqualObjects(changedStep.identifier, APHMedicationTrackerChangedStepIdentifier);
    
    // If the answer to the question is "YES" then ask med questions
    ORKBooleanQuestionResult *changedResult = [[ORKBooleanQuestionResult alloc] initWithIdentifier:APHMedicationTrackerChangedStepIdentifier];
    changedResult.booleanAnswer = @YES;
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerChangedStepIdentifier results:@[changedResult]];
    taskResult.results = @[stepResult];
    
    // Next step should be the data groups step
    ORKStep *dataGroupsStep = [task stepAfterStep:changedStep withResult:taskResult];
    XCTAssertNotNil(dataGroupsStep);
    XCTAssertEqualObjects(dataGroupsStep.identifier, APCDataGroupsStepIdentifier);
    
    // Next step after data groups should be medication selection
    taskResult.results = [taskResult.results arrayByAddingObject:[MockPDResult new]];
    ORKStep *selectionStep = [task stepAfterStep:dataGroupsStep withResult:taskResult];
    XCTAssertNotNil(selectionStep);
    XCTAssertEqualObjects(selectionStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
}

- (void)testPrefixToOrderedTask_NoMedTrackingInfoStored_ThenNoneSelected
{
    MockAPHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Get the selection step
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // If the meds selection step result is "none" then the remaining steps should be
    // the steps from the inputTask
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier] dataGroup:[MockPDResult new]];
    [self checkStepOrder:task taskResult:taskResult startStep:selectionStep startIndex:1 addedStepCount:3];
}

- (void)testPrefixToOrderedTask_NoMedTrackingInfoStored_ThenSkipSelected
{
    MockAPHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Get the selection step
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // If the meds selection step result is "none" then the remaining steps should be
    // the steps from the inputTask
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerSkipAnswerIdentifier] dataGroup:[MockPDResult new]];
    [self checkStepOrder:task taskResult:taskResult startStep:selectionStep startIndex:1 addedStepCount:3];
}

- (void)testPrefixToOrderedTask_NoMedTrackingInfoStored_ThenInjectionSelected
{
    MockAPHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Get the selection step
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // If the meds selection step result is "none" then the remaining steps should be
    // the steps from the inputTask
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:@[@"Apokyn"] dataGroup:[MockPDResult new]];
    [self checkStepOrder:task taskResult:taskResult startStep:selectionStep startIndex:1 addedStepCount:3];
}

- (void)testPrefixToOrderedTask_NoMedTrackingInfoStored_ThenTrackedMedSelected
{
    MockAPHMedicationTrackerTask *task = [self createAndStepToSelectionWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Get the selection step
    ORKStep *selectionStep = [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    // If the user indicates that they are taking a medication that is being tracked
    // then the next step should be frequency step
    ORKTaskResult *taskResult = [self createTaskResultWithAnswers:@[@"Levodopa"] dataGroup:[MockPDResult new]];
    ORKStep *frequencyStep = [task stepAfterStep:selectionStep withResult:taskResult];
    XCTAssertEqualObjects(frequencyStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    
    // After the frequency step, the user should be asked the moment in day step
    ORKStep *momentInDayStep = [task stepAfterStep:frequencyStep withResult:taskResult];
    XCTAssertEqualObjects(momentInDayStep.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKStep *activityTimingStep = [task stepAfterStep:momentInDayStep withResult:taskResult];
    XCTAssertEqualObjects(activityTimingStep.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    
    // Finally, the user should be directed to the steps associated with the input task
    [self checkStepOrder:task taskResult:taskResult startStep:activityTimingStep startIndex:1 addedStepCount:6];
}

- (void)testPrefixToOrderedTask_WithTrackedMedsPreviouslySelected
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa"]];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Check assumptions
    XCTAssertFalse(task.dataStore.hasChanges);
    XCTAssertTrue(task.dataStore.hasSelectedMedicationOrSkipped);
    
    // The first step should be the intro step from the inputTask
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    XCTAssertEqualObjects(firstStep, [inputTask.steps firstObject]);
    
    // If the user indicates that they are taking a medication that is being tracked
    // then the next step should be the moment in day step
    ORKStep *momentInDayStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(momentInDayStep.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKStep *activityTimingStep = [task stepAfterStep:momentInDayStep withResult:taskResult];
    XCTAssertEqualObjects(activityTimingStep.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    
    // Finally, the user should be directed to the steps associated with the input task
    [self checkStepOrder:task taskResult:taskResult startStep:activityTimingStep startIndex:1 addedStepCount:2];
}

- (void)testPrefixToOrderedTask_WithNoMedsPreviouslySelected
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[]];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Check assumptions
    XCTAssertFalse(task.dataStore.hasChanges);
    XCTAssertTrue(task.dataStore.hasSelectedMedicationOrSkipped);
    
    // If the user indicates that they are *not* taking any tracked medication, then
    // all the medication tracking questions should be excluded
    ORKTaskResult *taskResult = [self createTaskResult];
    [self checkStepOrder:task taskResult:taskResult startStep:nil startIndex:0 addedStepCount:0];
}

- (void)checkStepOrder:(MockAPHMedicationTrackerTask*)task taskResult:(ORKTaskResult *)taskResult startStep:(ORKStep*)startStep startIndex:(NSUInteger)startIndex addedStepCount:(NSUInteger)addedStepCount
{
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    ORKStep *nextStep = startStep;
    NSUInteger idx = startIndex;
    
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        
        // CHeck progress
        ORKTaskProgress progress = [task progressOfCurrentStep:nextStep withResult:taskResult];
        if (idx != 0) {
            XCTAssertEqual(progress.current, idx + addedStepCount);
            XCTAssertEqual(progress.total, inputTask.steps.count + addedStepCount);
        }
        
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}


#pragma mark - Test optional ORKTask methods

- (void)testOptionalORKTaskMethodsArePassedThrough_NotIncluded
{
    MockORKTask *subtask = [MockORKTask new];
    APHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] initWithDictionaryRepresentation:nil subTask:subtask];
    
    XCTAssertNoThrow([task validateParameters]);
    XCTAssertNil(task.requestedHealthKitTypesForReading);
    XCTAssertNil(task.requestedHealthKitTypesForWriting);
    XCTAssertEqual(task.requestedPermissions, ORKPermissionNone);
    XCTAssertFalse(task.providesBackgroundAudioPrompts);
}

- (void)testOptionalORKTaskMethodsArePassedThrough_Included
{
    MockORKTaskWithOptionals *subtask = [MockORKTaskWithOptionals new];
    APHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] initWithDictionaryRepresentation:nil subTask:subtask];
    
    XCTAssertNoThrow([task validateParameters]);
    XCTAssertTrue(subtask.validateParameters_called);
    
    XCTAssertEqualObjects(task.requestedHealthKitTypesForReading, subtask.requestedHealthKitTypesForReading);
    XCTAssertEqualObjects(task.requestedHealthKitTypesForWriting, subtask.requestedHealthKitTypesForWriting);
    XCTAssertEqual(task.requestedPermissions, subtask.requestedPermissions);
    XCTAssertTrue(task.providesBackgroundAudioPrompts);
}

#pragma mark - ORKTaskResultSource tests

- (void)testDefaultDataGroupsResult {
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:nil trackedMedications:nil surveyStepResult:[MockPDResult new]];
    ORKStepResult *result = [task stepResultForStepIdentifier:APCDataGroupsStepIdentifier];
    
    XCTAssertNotNil(result);
}

- (void)testDefaultMedicationSelectionResult {
    NSArray *answers = @[@"Levodopa", @"Sinemet"];
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:nil trackedMedications:answers surveyStepResult:[MockPDResult new]];
    ORKStepResult *result = [task stepResultForStepIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.identifier, APHMedicationTrackerSelectionStepIdentifier);
    XCTAssertEqual(result.results.count, 1);
    
    ORKChoiceQuestionResult *questionResult = (ORKChoiceQuestionResult*)[result.results firstObject];
    XCTAssertTrue([questionResult isKindOfClass:[ORKChoiceQuestionResult class]]);
    XCTAssertEqualObjects(questionResult.identifier, APHMedicationTrackerSelectionStepIdentifier);
    XCTAssertEqualObjects(questionResult.choiceAnswers, answers);
}

- (void)testDefaultMedicationFrequencyResult {
    NSArray *answers = @[@"Levodopa", @"Sinemet", @"Apokyn"];
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:nil trackedMedications:answers surveyStepResult:[MockPDResult new]];
    
    // Set the frequency for meds that aren't injection
    NSMutableArray *selectedMeds = [task.mockDataStore.selectedMedications mutableCopy];
    for (APHMedication *med in selectedMeds) {
        if (!med.injection) {
            med.frequency = med.identifier.length;
        }
    }
    task.dataStore.selectedMedications = selectedMeds;
    [task.dataStore commitChanges];
    
    ORKStepResult *result = [task stepResultForStepIdentifier:APHMedicationTrackerFrequencyStepIdentifier];
    
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqual(result.results.count, 2);
    
    ORKScaleQuestionResult *levodopa = (ORKScaleQuestionResult *)[result.results firstObject];
    XCTAssertTrue([levodopa isKindOfClass:[ORKScaleQuestionResult class]]);
    XCTAssertEqualObjects(levodopa.identifier, @"Levodopa");
    XCTAssertEqual(levodopa.scaleAnswer.integerValue, 8);
    
    ORKScaleQuestionResult *sinemet = (ORKScaleQuestionResult *)[result.results lastObject];
    XCTAssertTrue([sinemet isKindOfClass:[ORKScaleQuestionResult class]]);
    XCTAssertEqualObjects(sinemet.identifier, @"Sinemet");
    XCTAssertEqual(sinemet.scaleAnswer.integerValue, 7);
}

#pragma mark - helper methods - create TrackerTask

- (MockAPHMedicationTrackerTask*)createTask {
    return [self createTaskWithSubTask:nil trackedMedications:nil surveyStepResult:[MockPDResult new]];
}

- (MockAPHMedicationTrackerTask*)createTaskWithSubTask {
    return [self createTaskWithSubTaskAndTrackedMedications:nil];
}

- (MockAPHMedicationTrackerTask*)createTaskWithSubTaskAndTrackedMedications:(NSArray*)trackedMedications {
    ORKOrderedTask  *inputTask = [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                      intendedUseDescription:nil
                                                         numberOfStepsPerLeg:20
                                                                restDuration:10
                                                                     options:ORKPredefinedTaskOptionNone];
    return [self createTaskWithSubTask:inputTask trackedMedications:trackedMedications surveyStepResult:[MockPDResult new]];
}

- (MockAPHMedicationTrackerTask*)createTaskWithSubTask:(ORKOrderedTask*)subTask trackedMedications:(NSArray*)trackedMedications surveyStepResult:(ORKStepResult*)surveyStepResult {

    MockAPHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] initWithDictionaryRepresentation:nil subTask:subTask];
    
    // Default to being in the parkinsons group
    task.mockDataGroupsManager.surveyStepResult = surveyStepResult;
    
    // If the tracked meds is non-nil, then set the value to the data store
    if (trackedMedications) {
        task.mockDataStore.selectedMedications = [task.medications filteredArrayWithIdentifiers:trackedMedications];
        [task.mockDataStore commitChanges];
    }
    
    return task;
}

- (MockAPHMedicationTrackerTask *)createAndStepToSelectionWithSubTask
{
    ORKOrderedTask  *inputTask = [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                      intendedUseDescription:nil
                                                         numberOfStepsPerLeg:20
                                                                restDuration:10
                                                                     options:ORKPredefinedTaskOptionNone];
    return [self createAndStepToSelectionWithSubTask:inputTask initialDataGroup:nil selectedDataGroup:[MockPDResult new]];
}

- (MockAPHMedicationTrackerTask *)createAndStepToSelectionWithSubTask:(ORKOrderedTask*)subtask initialDataGroup:(ORKStepResult*)initialResult selectedDataGroup:(ORKStepResult*)selectedResult
{
    // This method does not test step order for the case where there is a subtask and an initial data group
    if (subtask) {
        XCTAssertNil(initialResult, @"This method is not setup to test step order for the case where there is a subtask and an initial data group");
    }
    XCTAssertNotNil(selectedResult, @"This method is setup assuming that the data groups will be answered with something.");
    
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:subtask trackedMedications:nil surveyStepResult:initialResult];
    ORKTaskResult *result = [self createTaskResultWithAnswers:nil];
    
    // If there is a subtask then the first step should be the step from the subtask
    ORKStep *preStep = nil;
    if (subtask != nil) {
        preStep = [task stepAfterStep:nil withResult:result];
        XCTAssertNotNil(preStep);
        XCTAssertEqualObjects(preStep, subtask.steps.firstObject);
    }
    
    // First step should be the intro step
    ORKStep *firstStep = [task stepAfterStep:preStep withResult:result];
    XCTAssertNotNil(firstStep);
    XCTAssertEqualObjects(firstStep.identifier, APHMedicationTrackerIntroductionStepIdentifier);
    
    // Next step should be the data groups step
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:result];
    XCTAssertNotNil(secondStep);
    XCTAssertEqualObjects(secondStep.identifier, APCDataGroupsStepIdentifier);
    
    // Next step after data groups should be medication selection
    result = [self createTaskResultWithAnswers:nil dataGroup:selectedResult];
    ORKStep *thirdStep = [task stepAfterStep:secondStep withResult:result];
    XCTAssertNotNil(thirdStep);
    XCTAssertEqualObjects(thirdStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    
    // Changes were recorded
    XCTAssertTrue(task.dataGroupsManager.hasChanges);
    XCTAssertEqualObjects(task.mockDataGroupsManager.surveyStepResult, selectedResult);
    
    // Test assumption of recoverablity
    XCTAssertEqualObjects(thirdStep, [task stepWithIdentifier:APHMedicationTrackerSelectionStepIdentifier]);
    
    // Return the task stepped forward to the selection point
    return task;
}

#pragma mark - helper methods - create task result

- (ORKTaskResult *)createTaskResult {
    return [self createTaskResultWithAnswers:nil dataGroup:nil];
}

- (ORKTaskResult *)createTaskResultWithAnswers:(NSArray*)answers {
    return [self createTaskResultWithAnswers:answers dataGroup:nil];
}

- (ORKTaskResult *)createTaskResultWithAnswers:(NSArray*)answers dataGroup:(ORKResult*)dataGroup {
    
    NSMutableArray *results = [NSMutableArray new];
    
    if (answers) {
        ORKChoiceQuestionResult *questionResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
        questionResult.choiceAnswers = answers;
        ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerSelectionStepIdentifier results:@[questionResult]];
        [results addObject:stepResult];
        
        // Since the data groups step is always included for a case where there are selected meds, then
        // create a result if it was nil
        if (dataGroup == nil) {
            dataGroup = [MockPDResult new];
        }
    }
    
    if (dataGroup) {
        [results addObject:dataGroup];
    }
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:APHMedicationTrackerTaskIdentifier];
    result.results = [results copy];
    
    return result;
}

@end
