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

NSString  *const kSelectedMedicationsKey                        = @"selectedMedications";
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

- (void)testSetTrackedMedications_NoMeds
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Setting to empty set if no tracked meds are taken
    [dataStore setSelectedItems:@[]];
    
    XCTAssertTrue(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.trackedItems);
    XCTAssertEqual(dataStore.trackedItems.count, 0);
    
    // Nothing saved yet to defaults
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedMedicationsKey]);
    
    // The momentInDay should now have a default result set
    NSArray <ORKStepResult *> *stepResults = dataStore.momentInDayResults;
    
    ORKStepResult *momentInDayStepResult = stepResults.firstObject;
    XCTAssertNotNil(momentInDayStepResult);
    XCTAssertEqualObjects(momentInDayStepResult.identifier, APHMedicationTrackerMomentInDayStepIdentifier);
    
    ORKChoiceQuestionResult *midResult = (ORKChoiceQuestionResult *)[momentInDayStepResult.results firstObject];
    XCTAssertNotNil(midResult);
    XCTAssertEqualObjects(midResult.identifier, APHMedicationTrackerMomentInDayFormItemIdentifier);
    XCTAssertNotNil(midResult.startDate);
    XCTAssertNotNil(midResult.endDate);
    XCTAssertEqualObjects(midResult.choiceAnswers, @[@"No Tracked Medication"]);
    XCTAssertEqual(midResult.questionType, ORKQuestionTypeSingleChoice);
    
    ORKStepResult *timingStepResult = stepResults.lastObject;
    XCTAssertNotNil(timingStepResult);
    XCTAssertEqualObjects(timingStepResult.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    
    ORKChoiceQuestionResult *atResult = (ORKChoiceQuestionResult *)[timingStepResult.results firstObject];
    XCTAssertNotNil(atResult);
    XCTAssertEqualObjects(atResult.identifier, APHMedicationTrackerActivityTimingStepIdentifier);
    XCTAssertNotNil(atResult.startDate);
    XCTAssertNotNil(atResult.endDate);
    XCTAssertEqualObjects(atResult.choiceAnswers, @[@"No Tracked Medication"]);
    XCTAssertEqual(atResult.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testSetMomentInDayResult
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    NSArray <ORKStepResult *> *stepResult = [self createMomentInDayStepResult];
    
    [dataStore setMomentInDayResults:[stepResult copy]];
    
    XCTAssertEqualObjects(dataStore.momentInDayResults, stepResult);
    XCTAssertTrue([dataStore hasChanges]);
}

- (void)testCommitChanges_NoMedication
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and commit
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    
    // Changes have been saved and does not have changes
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSelectedMedicationsKey]);
    
    XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate.timeIntervalSinceNow, 0.0, 2);
}

- (void)testCommitChanges_WithTrackedMedicationAndMomentInDayResult
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Set the selected medications and moment in day
    SBAMedication *med = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                  @"tracking" : @(YES)}];
    dataStore.selectedItems = @[med];
    NSArray <ORKStepResult *> *momentInDayResult = [self createMomentInDayStepResult];
    dataStore.momentInDayResults = momentInDayResult;
    
    // commit the changes
    [dataStore commitChanges];
    
    // Changes have been saved and does not have changes
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil([dataStore.storedDefaults objectForKey:kSelectedMedicationsKey]);
    XCTAssertEqual(dataStore.selectedItems.count, 1);
    XCTAssertEqualObjects(dataStore.selectedItems.firstObject, med);
    XCTAssertNotNil(dataStore.momentInDayResults);
    XCTAssertEqualObjects(dataStore.momentInDayResults, momentInDayResult);
    
    XCTAssertEqualWithAccuracy(dataStore.lastTrackingSurveyDate.timeIntervalSinceNow, 0.0, 2);
    XCTAssertEqualWithAccuracy(dataStore.lastCompletionDate.timeIntervalSinceNow, 0.0, 2);
}

- (void)testReset
{
    APHMedicationTrackerDataStore *dataStore = [self createDataStore];
    
    // Set tracked medication and reset
    [dataStore setSelectedItems:@[]];
    [dataStore reset];
    
    // Changes have been cleared
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedMedicationsKey]);
}

- (void)testShouldIncludeMomentInDayStep_LastCompletionNil
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                                @"tracking" : @(YES)}]];
    dataStore.momentInDayResults = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    dataStore.mockLastCompletionDate = nil;
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResults);
    XCTAssertNil(dataStore.lastCompletionDate);

    // For a nil date, the moment in day step should be included
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_StashNil
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                                @"tracking" : @(YES)}]];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil(dataStore.momentInDayResults);
    
    // Even if the time is very recent, should include moment in day step
    // if the stashed result is nil.
    dataStore.mockLastCompletionDate = [NSDate date];
    XCTAssertTrue([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMomentInDayStep_TakesMedication
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa",
                                                                                                @"tracking" : @(YES)}]];
    dataStore.momentInDayResults = [self createMomentInDayStepResult];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertNotEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNotNil(dataStore.momentInDayResults);

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
    dataStore.selectedItems = @[[[SBAMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Carbidopa"}]];
    [dataStore commitChanges];
    
    // Check assumptions
    XCTAssertEqual(dataStore.trackedItems.count, 0);
    XCTAssertFalse(dataStore.hasChanges);

    // If no meds, should not be asked the moment in day question
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
    dataStore.mockLastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-30*60];
    XCTAssertFalse([dataStore shouldIncludeMomentInDayStep]);
}

- (void)testShouldIncludeMedicationChangedQuestion_NO
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    dataStore.lastTrackingSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-24*60*60];
    
    XCTAssertFalse(dataStore.shouldIncludeChangedQuestion);
}

- (void)testShouldIncludeMedicationChangedQuestion_YES
{
    MockAPHMedicationTrackerDataStore *dataStore = [self createDataStore];
    [dataStore setSelectedItems:@[]];
    [dataStore commitChanges];
    dataStore.lastTrackingSurveyDate = [NSDate dateWithTimeIntervalSinceNow:-32*24*60*60];
    
    XCTAssertTrue(dataStore.shouldIncludeChangedQuestion);
}

#pragma mark - helper methods

- (MockAPHMedicationTrackerDataStore *)createDataStore
{
    MockAPHMedicationTrackerDataStore *dataStore = [MockAPHMedicationTrackerDataStore new];
    
    // Check assumptions
    XCTAssertFalse(dataStore.hasChanges);
    XCTAssertNil(dataStore.trackedItems);
    XCTAssertNil(dataStore.momentInDayResults);
    XCTAssertNil([dataStore.storedDefaults objectForKey:kSelectedMedicationsKey]);
    
    return dataStore;
}

- (NSArray <ORKStepResult *> *)createMomentInDayStepResult
{
    ORKChoiceQuestionResult *inputA = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    inputA.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    inputA.endDate = [inputA.startDate dateByAddingTimeInterval:30];
    inputA.questionType = ORKQuestionTypeSingleChoice;
    inputA.choiceAnswers = @[@"Immediately before Parkinson medication"];
    ORKStepResult *stepResultA = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[inputA]];
    
    ORKChoiceQuestionResult *inputB = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    inputB.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    inputB.endDate = [inputB.startDate dateByAddingTimeInterval:30];
    inputB.questionType = ORKQuestionTypeSingleChoice;
    inputB.choiceAnswers = @[@"0-30 minutes"];
    ORKStepResult *stepResultB = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[inputB]];
    
    return @[stepResultA, stepResultB];
}

@end
