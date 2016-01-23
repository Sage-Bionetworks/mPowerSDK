//
//  APHMedicationTrackerDataStoreTests.m
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
#import "MockAPHMedicationTrackerDataStore.h"

NSString  *const kTrackedMedicationsKey                         = @"trackedMedications";
NSString  *const kSkippedSelectMedicationsSurveyQuestionKey     = @"skippedSelectMedicationsSurveyQuestion";
NSString  *const kMomentInDayResultKey                          = @"momentInDayResult";

@interface APHMedicationTrackerDataStoreTests : XCTestCase

@end

@implementation APHMedicationTrackerDataStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetTrackedMedications_Skipped
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Setting to nil if the question was skipped
    [dataStore setSkippedSelectMedicationsSurveyQuestion:YES];
    
    // After setting a nil value to the tracked medication, this indicates that
    // the question has been skipped
    XCTAssertTrue(dataStore.hasChanges);
    XCTAssertTrue(dataStore.skippedSelectMedicationsSurveyQuestion);
    XCTAssertNil(dataStore.trackedMedications);
    
    // Nothing saved yet to defaults
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectMedicationsSurveyQuestionKey]);
    
    // The momentInDay should now have a default result set
    ORKStepResult *outStepResult = dataStore.momentInDayResult;
    XCTAssertNotNil(outStepResult);
    XCTAssertEqualObjects(outStepResult.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *output = (ORKChoiceQuestionResult *)[outStepResult.results firstObject];
    XCTAssertNotNil(output);
    XCTAssertEqualObjects(output.identifier, APHMedicationTrackerMomentInDayFormItemIdentifier);
    XCTAssertNotNil(output.startDate);
    XCTAssertNotNil(output.endDate);
    XCTAssertEqualObjects(output.choiceAnswers, @[@"Medication Unknown"]);
    XCTAssertEqual(output.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testSetTrackedMedications_NoMeds
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Setting to empty set if no tracked meds are taken
    [dataStore setTrackedMedications:@[]];
    
    // After setting a nil value to the tracked medication, this indicates that
    // the question has been skipped
    XCTAssertTrue(dataStore.hasChanges);
    XCTAssertFalse(dataStore.skippedSelectMedicationsSurveyQuestion);
    XCTAssertNotNil(dataStore.trackedMedications);
    XCTAssertEqual(dataStore.trackedMedications.count, 0);
    
    // Nothing saved yet to defaults
    XCTAssertNil([dataStore.storedDefaults objectForKey:kTrackedMedicationsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectMedicationsSurveyQuestionKey]);
    
    // The momentInDay should now have a default result set
    ORKStepResult *outStepResult = dataStore.momentInDayResult;
    XCTAssertNotNil(outStepResult);
    XCTAssertEqualObjects(outStepResult.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *output = (ORKChoiceQuestionResult *)[outStepResult.results firstObject];
    XCTAssertNotNil(output);
    XCTAssertEqualObjects(output.identifier, APHMedicationTrackerMomentInDayFormItemIdentifier);
    XCTAssertNotNil(output.startDate);
    XCTAssertNotNil(output.endDate);
    XCTAssertEqualObjects(output.choiceAnswers, @[@"No Tracked Medication"]);
    XCTAssertEqual(output.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testIsStudyControlGroup
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockControlResult new];

    // The momentInDay should now have a default result set for the control group
    ORKStepResult *outStepResult = dataStore.momentInDayResult;
    XCTAssertNotNil(outStepResult);
    XCTAssertEqualObjects(outStepResult.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *output = (ORKChoiceQuestionResult *)[outStepResult.results firstObject];
    XCTAssertNotNil(output);
    XCTAssertEqualObjects(output.identifier, APHMedicationTrackerMomentInDayFormItemIdentifier);
    XCTAssertNotNil(output.startDate);
    XCTAssertNotNil(output.endDate);
    XCTAssertEqualObjects(output.choiceAnswers, @[@"Control Group"]);
    XCTAssertEqual(output.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testSetMomentInDayResult
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    ORKStepResult *stepResult = [self createMomentInDayStepResult];
    
    [dataStore setMomentInDayResult:stepResult];
    
    XCTAssertEqualObjects(dataStore.momentInDayResult, stepResult);
    XCTAssertTrue([dataStore hasChanges]);
}

- (void)testCommitChanges
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and commit
    [dataStore setTrackedMedications:@[]];
    [dataStore commitChanges];
    
    // Changes have been saved and does not have changes
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kTrackedMedicationsKey]);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSkippedSelectMedicationsSurveyQuestionKey]);
}

- (void)testReset
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and commit
    [dataStore setTrackedMedications:@[]];
    [dataStore reset];
    
    // Changes have been cleared
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kTrackedMedicationsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectMedicationsSurveyQuestionKey]);
}

- (void)testShouldIncludeMomentInDayStep_LastCompletionNil
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    dataStore.trackedMedications = @[@"Levodopa"];
    dataStore.momentInDayResult = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    dataStore.mockLastCompletionDate = nil;
    
    // Check assumptions
    XCTAssertFalse(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertNotEqual(dataStore.trackedMedications.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResult);
    XCTAssertNil(dataStore.lastCompletionDate);

    // For a nil date, the moment in day step should be included
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_StashNil
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    dataStore.trackedMedications = @[@"Levodopa"];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertFalse(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertNotEqual(dataStore.trackedMedications.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil(dataStore.momentInDayResult);
    
    // Even if the time is very recent, should include moment in day step
    // if the stashed result is nil.
    dataStore.mockLastCompletionDate = [NSDate date];
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_TakesMedication
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    dataStore.trackedMedications = @[@"Levodopa"];
    dataStore.momentInDayResult = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertFalse(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertNotEqual(dataStore.trackedMedications.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResult);

    // For a recent time, should NOT include step
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);

    // If it has been more than 30 minutes, should ask the question again
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_NoMedication
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    dataStore.trackedMedications = @[];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertFalse(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertEqual(dataStore.trackedMedications.count, 0);
    XCTAssertFalse(dataStore.hasChanges);

    // If no meds, should not be asked the moment in day question
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_ControlGroup
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.mockDataGroupsManager.surveyStepResult = [MockControlResult new];
    
    // Check assumptions
    XCTAssertTrue(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertFalse(dataStore.hasSelectedMedicationOrSkipped);
    XCTAssertFalse(dataStore.hasChanges);
    
    // For control group, the moment in day step should not be included
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_SkipMedsQuestion
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.skippedSelectMedicationsSurveyQuestion = YES;
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertFalse(dataStore.dataGroupsManager.isStudyControlGroup);
    XCTAssertEqual(dataStore.trackedMedications.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    
    // If the medication survey question was skipped, then skip the moment in day step
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

#pragma mark - helper methods

- (MockAPHMedicationTrackerDataStore *)createDataStore
{
    MockAPHMedicationTrackerDataStore *dataStore = [MockAPHMedicationTrackerDataStore new];
    
    // Check assumptions
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertFalse(dataStore.skippedSelectMedicationsSurveyQuestion);
    XCTAssertNil(dataStore.trackedMedications);
    XCTAssertNil(dataStore.momentInDayResult);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kTrackedMedicationsKey]);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSkippedSelectMedicationsSurveyQuestionKey]);
    
    return dataStore;
}

- (ORKStepResult *)createMomentInDayStepResult
{
    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    input.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    input.endDate = [input.startDate dateByAddingTimeInterval:30];
    input.questionType = ORKQuestionTypeSingleChoice;
    input.choiceAnswers = @[@"0-30 minutes"];
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[input]];
    return stepResult;
}

@end
