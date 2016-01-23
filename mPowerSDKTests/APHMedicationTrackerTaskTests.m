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

#pragma mark - Test step order w/o subtask

- (void)testFirstStep {
    APHMedicationTrackerTask *task = [self createTask];
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:task.identifier];
    ORKStep *step = [task stepAfterStep:nil withResult:result];
    
    XCTAssertNotNil(step);
    XCTAssertFalse(step.optional);
    XCTAssertTrue([step isKindOfClass:[ORKFormStep class]]);
    
    ORKFormStep *formStep = (ORKFormStep*)step;
    XCTAssertEqual(formStep.formItems.count, 1);
    
    ORKFormItem *formItem = [formStep.formItems firstObject];
    XCTAssertEqualObjects(formItem.text, @"Select all the Parkinson's Medications that you are currently taking.");
    
    XCTAssertTrue([formItem.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]);
    ORKTextChoiceAnswerFormat *answerFormat = (ORKTextChoiceAnswerFormat *)formItem.answerFormat;
    
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
                                 @"None of the above"];
    NSArray *actualChoices = [answerFormat.textChoices valueForKey:@"text"];
    XCTAssertEqualObjects(actualChoices, expectedChoices);
    XCTAssertEqual(actualChoices.count, expectedChoices.count);
    for (NSUInteger idx=0; idx < actualChoices.count && idx < expectedChoices.count; idx++) {
        XCTAssertEqualObjects(actualChoices[idx], expectedChoices[idx], @"idx=%@", @(idx));
    }
}

- (void)testFollowUpSteps_NoneSelected {
    APHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step and check assuptions
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil withResult:[self createTaskResultWithAnswers:nil]];
    
    // Next step should be for frequency
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier]];
    
    // If no medications are selected, then the next step should be nil
    ORKStep *nextStep = [task stepAfterStep:firstStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertNotEqualObjects(nextStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqualObjects(nextStep.title, @"Thank You!");
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testFollowUpSteps_InjectionSelected {
    APHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step and check assuptions
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil withResult:[self createTaskResultWithAnswers:nil]];
    
    // Next step should be for frequency
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[@"Apomorphine (Apokyn)"]];
    ORKStep *nextStep = [task stepAfterStep:firstStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertNotEqualObjects(nextStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqualObjects(nextStep.title, @"Thank You!");
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testFollowUpSteps_PillsSelected {
    APHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step and check assuptions
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil withResult:[self createTaskResultWithAnswers:nil]];
    
    // Next step should be for frequency
    ORKTaskResult *result = [self createTaskResultWithAnswers:@[@"Levodopa", @"Carbidopa"]];
    ORKFormStep *frequencyStep = (ORKFormStep*)[task stepAfterStep:firstStep withResult:result];
    XCTAssertNotNil(frequencyStep);
    XCTAssertTrue([frequencyStep isKindOfClass:[ORKFormStep class]]);
    XCTAssertTrue(frequencyStep.optional);
    XCTAssertEqualObjects(frequencyStep.text, @"How many times a day do you take each of the following medications?");
    XCTAssertEqual(frequencyStep.formItems.count, 2);
    
    NSArray *expectedText = @[@"Levodopa", @"Carbidopa"];
    NSArray *expectedIdentifier = @[@"Levodopa", @"Carbidopa"];
    for (NSUInteger idx=0; idx < frequencyStep.formItems.count; idx++) {
        ORKFormItem *item = frequencyStep.formItems[idx];
        XCTAssertEqualObjects(item.text, expectedText[idx]);
        XCTAssertEqualObjects(item.identifier, expectedIdentifier[idx]);
        XCTAssertTrue([item.answerFormat isKindOfClass:[ORKScaleAnswerFormat class]]);
        XCTAssertEqual(((ORKScaleAnswerFormat *)item.answerFormat).minimum, 1);
        XCTAssertEqual(((ORKScaleAnswerFormat *)item.answerFormat).maximum, 12);
        XCTAssertEqual(((ORKScaleAnswerFormat *)item.answerFormat).step, 1);
    }
    
    // Next step should be for thank you
    ORKStep *nextStep = [task stepAfterStep:frequencyStep withResult:result];
    XCTAssertNotNil(nextStep);
    XCTAssertNotEqualObjects(nextStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqualObjects(nextStep.title, @"Thank You!");
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:nextStep withResult:result]);
}

- (void)testStepBackAndForward_NoSubtask {
    
    APHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step
    ORKFormStep *selectionStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResultWithAnswers:nil]];
    
    // Get the second step
    ORKFormStep *frequencyStep = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa", @"Carbidopa"]]];
    
    // Check assumptions
    XCTAssertEqualObjects(selectionStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    XCTAssertEqualObjects(frequencyStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqual(frequencyStep.formItems.count, 2);
    
    // The step before the second step should be the first step (and does not depend upon result)
    ORKTaskResult *blankResult = [[ORKTaskResult alloc] initWithIdentifier:task.identifier];
    ORKStep *backOnceFromFrequencyStep = [task stepBeforeStep:frequencyStep withResult:blankResult];
    XCTAssertEqualObjects(backOnceFromFrequencyStep, selectionStep);
    
    // The step before the first step should be nil
    ORKStep *beforeSelectionStep = [task stepBeforeStep:selectionStep withResult:blankResult];
    XCTAssertNil(beforeSelectionStep);
    
    // With a different result from the first step, the second step should change
    ORKFormStep *frequencyStepB = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa"]]];
    XCTAssertNotNil(frequencyStepB);
    XCTAssertEqualObjects(frequencyStepB.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertTrue([frequencyStepB isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqual(frequencyStepB.formItems.count, 1);
    
    // The step before the new second step should still be the first step
    ORKStep *stepBeforeFrequencyB = [task stepBeforeStep:frequencyStepB withResult:blankResult];
    XCTAssertEqualObjects(stepBeforeFrequencyB, selectionStep);
    
    // With No medication selected result from the first step, the second step should now be nil
    ORKTaskResult *noneResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier]];
    ORKFormStep *afterSelectionNoMedsStep = (ORKFormStep*)[task stepAfterStep:selectionStep
                                                      withResult:noneResult];
    XCTAssertNotNil(afterSelectionNoMedsStep);
    
    XCTAssertNotEqualObjects(afterSelectionNoMedsStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqualObjects(afterSelectionNoMedsStep.title, @"Thank You!");
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:afterSelectionNoMedsStep withResult:noneResult]);
}

- (void)testFirstStepIfDataGroupsNeeded {
    
    // Nil the survey step result to force to unknown data group
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:nil trackedMedications:nil surveyStepResult:nil];
    
    // Get the first step
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResult]];
    XCTAssertEqualObjects(firstStep.identifier, APCDataGroupsStepIdentifier);
}

- (void)testSecondStepIfDataGroupsNeeded_ControlGroup {
    
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask:nil trackedMedications:nil surveyStepResult:nil];
    
    // Get the first step
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResult]];

    // Get the second step
    ORKStepResult *stepResult = [MockControlResult new];
    ORKStep *secondStep = (ORKStep*)[task stepAfterStep:firstStep
                                             withResult:[self createTaskResultWithAnswers:nil dataGroup:stepResult]];
    
    // If this is a control group then the answer to the question about meds is irrelevant
    // and the user should be directed to thanks step
    XCTAssertNotNil(secondStep);
    XCTAssertEqualObjects(secondStep.identifier, @"conclusion");
    XCTAssertEqualObjects(secondStep.title, @"Thank You!");
    
    // The data groups manager should have been set with the step result
    XCTAssertTrue(task.mockDataGroupsManager.hasChanges);
    XCTAssertEqualObjects(task.mockDataGroupsManager.surveyStepResult, stepResult);
}

- (void)testSecondStepIfDataGroupsNeeded_ParkinsonGroup {
    
    MockAPHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step
    task.mockDataGroupsManager.surveyStepResult = nil;
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResult]];
    
    // Get the second step
    ORKStepResult *stepResult = [MockPDResult new];
    ORKStep *secondStep = (ORKStep*)[task stepAfterStep:firstStep
                                             withResult:[self createTaskResultWithAnswers:nil dataGroup:stepResult]];
    
    // If this is in the parkinson group then the next question should be the meds selection
    XCTAssertEqualObjects(secondStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    
    // The data groups manager should have been set with the step result
    XCTAssertTrue(task.mockDataGroupsManager.hasChanges);
    XCTAssertEqualObjects(task.mockDataGroupsManager.surveyStepResult, stepResult);
}

#pragma mark - Series of tests for showing Data groups step and/or medication tracking steps prior to another task

- (void)testPrefixToOrderedTask_NoDataGroup_ThenControl
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Set the data groups to not yet assigned
    task.mockDataGroupsManager.surveyStepResult = nil;
    
    // The first step should be the intro step from the inputTask
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    XCTAssertEqualObjects(firstStep, [inputTask.steps firstObject]);
    
    // CHeck progress
    ORKTaskProgress progress = [task progressOfCurrentStep:firstStep withResult:taskResult];
    XCTAssertEqual(progress.current, 0);
    XCTAssertEqual(progress.total, 0);
    
    // The second step should be to ask about the data groups
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(secondStep.identifier, APCDataGroupsStepIdentifier);
    
    // CHeck progress
    progress = [task progressOfCurrentStep:secondStep withResult:taskResult];
    XCTAssertEqual(progress.current, 1);
    XCTAssertEqual(progress.total, 0);
    
    // If the data groups responds with control then the remaining steps should be
    // the steps from the inputTask
    taskResult = [self createTaskResultWithAnswers:nil dataGroup:[MockControlResult new]];
    ORKStep *nextStep = secondStep;
    NSUInteger idx = 1;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        
        // CHeck progress
        progress = [task progressOfCurrentStep:nextStep withResult:taskResult];
        XCTAssertEqual(progress.current, idx + 1);
        XCTAssertEqual(progress.total, inputTask.steps.count + 1);
        
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testPrefixToOrderedTask_NoDataGroup_ThenParkinsons_ThenNoMeds
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // Set the data groups to not yet assigned
    task.mockDataGroupsManager.surveyStepResult = nil;
    
    // The first step should be the intro step from the inputTask
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    XCTAssertEqualObjects(firstStep, [inputTask.steps firstObject]);
    
    // The second step should be to ask about the data groups
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(secondStep.identifier, APCDataGroupsStepIdentifier);
    
    // If the data groups response is parkinsons group then the next question should be
    // about which meds the user is taking.
    taskResult = [self createTaskResultWithAnswers:nil dataGroup:[MockPDResult new]];
    ORKStep *thirdStep = [task stepAfterStep:secondStep withResult:taskResult];
    XCTAssertEqualObjects(thirdStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    
    // If the meds selection step result is "none" then the remaining steps should be
    // the steps from the inputTask
    taskResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier] dataGroup:[MockPDResult new]];
    ORKStep *nextStep = thirdStep;
    NSUInteger idx = 1;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        
        // CHeck progress
        ORKTaskProgress progress = [task progressOfCurrentStep:nextStep withResult:taskResult];
        XCTAssertEqual(progress.current, idx + 2);
        XCTAssertEqual(progress.total, inputTask.steps.count + 2);
        
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testPrefixToOrderedTask_Parkinsons_ThenTrackedMed
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);
    
    // The first step should be the intro step from the inputTask
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    XCTAssertEqualObjects(firstStep, [inputTask.steps firstObject]);
    
    // The second step should be about which meds the user is taking.
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(secondStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    
    // If the user indicates that they are taking a medication that is being tracked
    // then the next step should be frequency step
    taskResult = [self createTaskResultWithAnswers:@[@"Levodopa"] dataGroup:[MockPDResult new]];
    ORKStep *thirdStep = [task stepAfterStep:secondStep withResult:taskResult];
    XCTAssertEqualObjects(thirdStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    
    // After the frequency step, the user should be asked the moment in day step
    ORKStep *fourthStep = [task stepAfterStep:thirdStep withResult:taskResult];
    XCTAssertEqualObjects(fourthStep.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    // Finally, the user should be directed to the steps associated with the input task
    ORKStep *nextStep = fourthStep;
    NSUInteger idx = 1;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testPrefixToOrderedTask_Parkinsons_WithTrackedMedsPreviouslySelected
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
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(secondStep.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    // Finally, the user should be directed to the steps associated with the input task
    ORKStep *nextStep = secondStep;
    NSUInteger idx = 1;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        
        // CHeck progress
        ORKTaskProgress progress = [task progressOfCurrentStep:nextStep withResult:taskResult];
        XCTAssertEqual(progress.current, idx + 1);
        XCTAssertEqual(progress.total, inputTask.steps.count + 1);
        
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testPrefixToOrderedTask_Parkinsons_WithNoMedsPreviouslySelected
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
    ORKStep *nextStep = nil;
    NSUInteger idx = 0;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testPrefixToOrderedTask_Control
{
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask];
    ORKOrderedTask *inputTask = (ORKOrderedTask  *)task.subTask;
    XCTAssertEqualObjects(task.identifier, inputTask.identifier);

    // Assign to control group
    task.mockDataGroupsManager.surveyStepResult = [MockControlResult new];
    
    // If the user indicates that they do not have Parkinsons, then
    // all the medication tracking questions should be excluded
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *nextStep = nil;
    NSUInteger idx = 0;
    do {
        nextStep = [task stepAfterStep:nextStep withResult:taskResult];
        XCTAssertEqualObjects(nextStep, inputTask.steps[idx]);
        idx++;
    } while (idx < inputTask.steps.count && nextStep != nil);
    
    // After checking all the steps of the input task, then should be no more steps
    XCTAssertNotNil(nextStep);
    nextStep = [task stepAfterStep:nextStep withResult:taskResult];
    XCTAssertNil(nextStep);
}

- (void)testCreateMomentInDayStep_English
{
    // set to the English bundle
    [APHLocalization setLocalization:@"en"];

    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTaskAndTrackedMedications:@[@"Levodopa"]];
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    
    // Get the medication tracking step
    ORKFormStep *step = (ORKFormStep *)[task stepAfterStep:firstStep withResult:taskResult];
    
    // Check assumptions
    XCTAssertNotNil(step);
    XCTAssertTrue([step isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqualObjects(step.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    // Check the language
    XCTAssertEqualObjects(step.text, @"We would like to understand how your performance on this activity could be affected by the timing of your medication.");

    ORKFormItem  *item = [step.formItems firstObject];
    XCTAssertEqual(step.formItems.count, 1);
    XCTAssertEqualObjects(item.identifier, @"momentInDayFormat");
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa?");
    XCTAssertTrue([item.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]);

    NSArray <ORKTextChoice *> *choices = ((ORKTextChoiceAnswerFormat*)item.answerFormat).textChoices;
    XCTAssertEqual(choices.count, 5);

    XCTAssertEqualObjects(choices[0].text, @"0-30 minutes ago");
    XCTAssertEqualObjects(choices[0].value, @"0-30 minutes ago");

    XCTAssertEqualObjects(choices[1].text, @"30-60 minutes ago");
    XCTAssertEqualObjects(choices[1].value, @"30-60 minutes ago");

    XCTAssertEqualObjects(choices[2].text, @"1-2 hours ago");
    XCTAssertEqualObjects(choices[2].value, @"1-2 hours ago");

    XCTAssertEqualObjects(choices[3].text, @"More than 2 hours ago");
    XCTAssertEqualObjects(choices[3].value, @"More than 2 hours ago");

    XCTAssertEqualObjects(choices[4].text, @"Not sure");
    XCTAssertEqualObjects(choices[4].value, @"Not sure");
}

- (void)testCreateMomentInDayStep_NameOnly_English
{
    ORKFormItem *item = [self createMomentInDayStepWithAnswers: @[@"Levodopa"]];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa?");
}

- (void)testCreateMomentInDayStep_2x_English
{
    ORKFormItem *item = [self createMomentInDayStepWithAnswers: @[@"Levodopa", @"Carbidopa/Levodopa (Sinemet)"]];

    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa or Sinemet?");
}

- (void)testCreateMomentInDayStep_3x_English
{
    ORKFormItem *item = [self createMomentInDayStepWithAnswers:@[@"Levodopa",
                                                                 @"Carbidopa/Levodopa (Rytary)",
                                                                 @"Carbidopa/Levodopa (Sinemet)"]];
    
    XCTAssertEqualObjects(item.text, @"When was the last time you took your Levodopa, Rytary or Sinemet?");
}

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

#pragma mark - helper methods

- (ORKTaskResult *)createTaskResult {
    return [self createTaskResultWithAnswers:nil dataGroup:nil];
}

- (ORKTaskResult *)createTaskResultWithAnswers:(NSArray*)answers {
    return [self createTaskResultWithAnswers:answers dataGroup:nil];
}

- (ORKTaskResult *)createTaskResultWithAnswers:(NSArray*)answers dataGroup:(ORKResult*)dataGroup {
    
    NSMutableArray *results = [NSMutableArray new];
    
    if (dataGroup) {
        [results addObject:dataGroup];
    }
    
    if (answers) {
        ORKChoiceQuestionResult *questionResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
        questionResult.choiceAnswers = answers;
        ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerSelectionStepIdentifier results:@[questionResult]];
        [results addObject:stepResult];
    }
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:APHMedicationTrackerTaskIdentifier];
    result.results = [results copy];
    
    return result;
}

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
    task.mockDataGroupsManager.surveyStep = [[ORKFormStep alloc] initWithIdentifier:APCDataGroupsStepIdentifier];
    
    // If the tracked meds is non-nil, then set the value to the data store
    if (trackedMedications != nil) {
        task.mockDataStore.trackedMedications = trackedMedications;
        [task.mockDataStore commitChanges];
    }
    
    return task;
}

- (ORKFormItem*)createMomentInDayStepWithAnswers:(NSArray*)answers {
    // set to the English bundle
    [APHLocalization setLocalization:@"en"];
    
    MockAPHMedicationTrackerTask *task = [self createTaskWithSubTask];
    
    ORKTaskResult *taskResult = [self createTaskResult];
    ORKStep *firstStep = [task stepAfterStep:nil withResult:taskResult];
    ORKStep *secondStep = [task stepAfterStep:firstStep withResult:taskResult];
    XCTAssertEqualObjects(secondStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    
    // If the user indicates that they are taking a medication that is being tracked
    // then the next step should be frequency step
    taskResult = [self createTaskResultWithAnswers:answers dataGroup:[MockPDResult new]];
    ORKStep *thirdStep = [task stepAfterStep:secondStep withResult:taskResult];
    XCTAssertEqualObjects(thirdStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    
    // After the frequency step, the user should be asked the moment in day step
    ORKStep *fourthStep = [task stepAfterStep:thirdStep withResult:taskResult];
    XCTAssertEqualObjects(fourthStep.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    XCTAssertTrue([fourthStep isKindOfClass:[ORKFormStep class]]);
    
    ORKFormItem  *item = [((ORKFormStep *)fourthStep).formItems firstObject];
    return item;
}

@end
