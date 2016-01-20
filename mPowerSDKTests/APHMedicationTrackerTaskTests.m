//
//  APHMedicationTrackerTaskTests.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/15/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <mPowerSDK/mPowerSDK.h>

#import "MockAPHMedicationTrackerTask.h"

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

- (void)testStepBackAndForward {
    
    APHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResultWithAnswers:nil]];
    
    // Get the second step
    ORKFormStep *secondStep = (ORKFormStep*)[task stepAfterStep:firstStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa", @"Carbidopa"]]];
    
    // Check assumptions
    XCTAssertEqualObjects(firstStep.identifier, APHMedicationTrackerSelectionStepIdentifier);
    XCTAssertEqualObjects(secondStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqual(secondStep.formItems.count, 2);
    
    // The step before the second step should be the first step (and does not depend upon result)
    ORKTaskResult *blankResult = [[ORKTaskResult alloc] initWithIdentifier:task.identifier];
    ORKStep *stepBefore2 = [task stepBeforeStep:secondStep withResult:blankResult];
    XCTAssertEqualObjects(stepBefore2, firstStep);
    
    // The step before the first step should be nil
    ORKStep *stepBefore1 = [task stepBeforeStep:firstStep withResult:blankResult];
    XCTAssertNil(stepBefore1);
    
    // With a different result from the first step, the second step should change
    ORKFormStep *secondStepB = (ORKFormStep*)[task stepAfterStep:firstStep
                                                     withResult:[self createTaskResultWithAnswers:@[@"Levodopa"]]];
    XCTAssertNotNil(secondStepB);
    XCTAssertEqualObjects(secondStepB.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertTrue([secondStepB isKindOfClass:[ORKFormStep class]]);
    XCTAssertEqual(secondStepB.formItems.count, 1);
    
    // The step before the new second step should still be the first step
    ORKStep *stepBefore2B = [task stepBeforeStep:secondStepB withResult:blankResult];
    XCTAssertEqualObjects(stepBefore2B, firstStep);
    
    // With No medication selected result from the first step, the second step should now be nil
    ORKTaskResult *noneResult = [self createTaskResultWithAnswers:@[APHMedicationTrackerNoneAnswerIdentifier]];
    ORKFormStep *secondStepC = (ORKFormStep*)[task stepAfterStep:firstStep
                                                      withResult:noneResult];
    XCTAssertNotNil(secondStepC);
    
    XCTAssertNotEqualObjects(secondStepC.identifier, APHMedicationTrackerFrequencyStepIdentifier);
    XCTAssertEqualObjects(secondStepC.title, @"Thank You!");
    
    // Step after the thank you should be nil
    XCTAssertNil([task stepAfterStep:secondStepC withResult:noneResult]);
}

- (void)testFirstStepIfDataGroupsNeeded {
    MockAPHMedicationTrackerTask *task = [self createTask];
    
    // Nil the survey step result to force to unknown data group
    task.mockDataGroupsManager.surveyStepResult = nil;
    
    // Get the first step
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResult]];
    XCTAssertEqualObjects(firstStep.identifier, APCDataGroupsStepIdentifier);
}

- (void)testSecondStepIfDataGroupsNeeded_ControlGroup {
    
    MockAPHMedicationTrackerTask *task = [self createTask];
    
    // Get the first step
    task.mockDataGroupsManager.surveyStepResult = nil;
    ORKFormStep *firstStep = (ORKFormStep*)[task stepAfterStep:nil
                                                    withResult:[self createTaskResult]];

    // Get the second step
    ORKStepResult *stepResult = [MockControlResult new];
    ORKStep *secondStep = (ORKStep*)[task stepAfterStep:firstStep
                                             withResult:[self createTaskResultWithAnswers:nil dataGroup:stepResult]];
    
    // If this is a control group then the answer to the question about meds is irrelevant
    // and the user should be directed to thanks step
    XCTAssertNotEqualObjects(secondStep.identifier, APHMedicationTrackerFrequencyStepIdentifier);
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
    MockAPHMedicationTrackerTask *task = [MockAPHMedicationTrackerTask new];
    // Default to being in the parkinsons group
    task.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    task.mockDataGroupsManager.surveyStep = [[ORKFormStep alloc] initWithIdentifier:APCDataGroupsStepIdentifier];
    return task;
}

@end
