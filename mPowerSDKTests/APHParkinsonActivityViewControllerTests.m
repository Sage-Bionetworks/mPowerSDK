//
//  APHParkinsonActivityViewControllerTests.m
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

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <mPowerSDK/mPowerSDK.h>
#import "MockAPHMedicationTrackerTask.h"
#import "MockAPCUser.h"
#import "MockAPCTaskResultArchiver.h"
@import BridgeAppSDK;

@interface APHParkinsonActivityViewControllerTests : XCTestCase

@end

@interface APCDataArchive (PrivateTest)
@property (nonatomic, strong) NSString *reference;
@property (nonatomic, strong) APCTask *task;
@property (nonatomic, strong) NSNumber *schemaRevision;
@end

@interface APHParkinsonActivityViewController_Test : APHParkinsonActivityViewController
@property (nonatomic) MockAPCUser *mockUser;
@property (nonatomic) ORKTaskResult *overrideTaskResult;
@end

@implementation APHParkinsonActivityViewControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDidFinishWithReason_SavedOrComplete
{
    NSArray *reasonsToSave = @[@(ORKTaskViewControllerFinishReasonSaved), @(ORKTaskViewControllerFinishReasonCompleted)];
    for (NSNumber *reason in reasonsToSave) {
    
        MockAPHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] init];
        APHParkinsonActivityViewController_Test *vc = [[APHParkinsonActivityViewController_Test alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
        [task.dataGroupsManager setSurveyAnswerWithStepResult:[MockPDResult new]];
        
        // verify assumptions
        XCTAssertTrue(task.dataStore.hasChanges);
        XCTAssertTrue(task.dataGroupsManager.hasChanges);
        XCTAssertNil(vc.user.dataGroups);
        
        // Setup an expectation that the user will be updated
        NSString *expectationName = [NSString stringWithFormat:@"expectation with reason %@", reason];
        XCTestExpectation *expectation = [self expectationWithDescription:expectationName];
        vc.mockUser.updateDataGroupsCompletionCalled = ^{
            [expectation fulfill];
        };

        // Expectation is that when the task is finished, if completed or saved that the results
        // Should be saved to the user and data store
        [vc taskViewController:vc didFinishWithReason:[reason unsignedIntegerValue] error:nil];
        
        // Wait for update to be called
        [self waitForExpectationsWithTimeout:1.0 handler:nil];
        
        // validated expectations
        XCTAssertFalse(task.dataStore.hasChanges, @"reason=%@", reason);
        XCTAssertTrue(task.mockDataStore.commitChanges_called, @"reason=%@", reason);
        XCTAssertTrue(vc.mockUser.updateDataGroups_called, @"reason=%@", reason);
        NSArray *expectedDataGroups = @[@"parkinsons"];
        XCTAssertEqualObjects(vc.user.dataGroups, expectedDataGroups, @"reason=%@", reason);
    }
}

- (void)testDidFinishWithReason_CancelOrFail
{
    NSArray *reasonsToSave = @[@(ORKTaskViewControllerFinishReasonDiscarded), @(ORKTaskViewControllerFinishReasonFailed)];
    for (NSNumber *reason in reasonsToSave) {
        
        MockAPHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] init];
        APHParkinsonActivityViewController_Test *vc = [[APHParkinsonActivityViewController_Test alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
        [task.dataGroupsManager setSurveyAnswerWithStepResult:[MockPDResult new]];
        
        // verify assumptions
        XCTAssertTrue(task.dataStore.hasChanges);
        XCTAssertTrue(task.dataGroupsManager.hasChanges);
        XCTAssertNil(vc.user.dataGroups);
        
        // Expectation is that when the task is finished, if completed or saved that the results
        // Should be saved to the user and data store
        NSError *err = [reason unsignedIntegerValue] == ORKTaskViewControllerFinishReasonFailed ? [NSError errorWithDomain:@"foo" code:1 userInfo:nil] : nil;
        [vc taskViewController:vc didFinishWithReason:[reason unsignedIntegerValue] error:err];
        
        // validated expectations
        XCTAssertFalse(task.dataStore.hasChanges, @"reason=%@", reason);
        XCTAssertTrue(task.mockDataStore.reset_called, @"reason=%@", reason);
        XCTAssertFalse(task.mockDataStore.commitChanges_called, @"reason=%@", reason);
        XCTAssertFalse(vc.mockUser.updateDataGroups_called, @"reason=%@", reason);
        XCTAssertNil(vc.user.dataGroups);
    }
}


- (void)testArchiveResults_NoSubTask
{
    APHParkinsonActivityViewController_Test *vc = [self createViewController:NO trackedMedications:nil];
    MockAPCTaskResultArchiver *mockArchiver = (MockAPCTaskResultArchiver *)vc.taskResultArchiver;
    
    // Setup results
    vc.overrideTaskResult = [[ORKTaskResult alloc] initWithIdentifier:APHMedicationTrackerTaskIdentifier];
    vc.overrideTaskResult.results = @[[[ORKStepResult alloc] initWithIdentifier:APCDataGroupsStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerFrequencyStepIdentifier]];
    
    // Run method under test
    [vc archiveResults];
    
    // For the case where the survey is the activity (not a subtask of another activity) then the base archive
    // should point at the medication survey results
    XCTAssertNil(vc.medicationTrackerArchive);
    XCTAssertNotNil(vc.archive);
    XCTAssertEqual(mockArchiver.archivedResults.count, 1);
    NSDictionary *archivedObjects = [[mockArchiver.archivedResults allValues] firstObject];
    XCTAssertEqualObjects(archivedObjects[@"archive"], vc.archive);
    XCTAssertEqualObjects(archivedObjects[@"result"], vc.overrideTaskResult);
    XCTAssertEqualObjects(vc.archive.reference, vc.overrideTaskResult.identifier);
    XCTAssertNotNil(vc.archive.task);
}

- (void)testArchiveResults_NoMedicationTracking_NoMomentInDayResult
{
    APHParkinsonActivityViewController_Test *vc = [self createViewController:YES trackedMedications:@[]];
    MockAPCTaskResultArchiver *mockArchiver = (MockAPCTaskResultArchiver *)vc.taskResultArchiver;
    
    // Setup results
    vc.overrideTaskResult = [[ORKTaskResult alloc] initWithIdentifier:@"Tapping Activity"];
    vc.overrideTaskResult.results = @[[[ORKStepResult alloc] initWithIdentifier:@"tapping.result"]];
    
    // Run method under test
    [vc archiveResults];
    
    // If there are no medication tracking results then the med archive is not created, but the
    // results should still include a moment in day result
    XCTAssertNil(vc.medicationTrackerArchive);
    XCTAssertNotNil(vc.archive);
    XCTAssertEqual(mockArchiver.archivedResults.count, 1);
    NSDictionary *archivedObjects = [[mockArchiver.archivedResults allValues] firstObject];
    XCTAssertEqualObjects(archivedObjects[@"archive"], vc.archive);
    
    ORKTaskResult *archivedResult = archivedObjects[@"result"];
    XCTAssertNotEqualObjects(archivedResult, vc.overrideTaskResult);
    XCTAssertNotNil([archivedResult resultForIdentifier:APHMedicationTrackerMomentInDayStepIdentifier]);
    XCTAssertNotNil([archivedResult resultForIdentifier:@"tapping.result"]);
    XCTAssertEqualObjects(vc.archive.reference, @"abc123");
    XCTAssertNotNil(vc.archive.task);
}

- (void)testArchiveResults_NoMedicationTracking_WithMomentInDayResult
{
    APHParkinsonActivityViewController_Test *vc = [self createViewController:YES trackedMedications:@[@"Levodopa"]];
    MockAPCTaskResultArchiver *mockArchiver = (MockAPCTaskResultArchiver *)vc.taskResultArchiver;
    
    // Setup results
    vc.overrideTaskResult = [[ORKTaskResult alloc] initWithIdentifier:@"Tapping Activity"];
    vc.overrideTaskResult.results = @[[[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerMomentInDayStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:@"tapping.result"]];
    
    // Run method under test
    [vc archiveResults];
    
    // If there are no medication tracking results then the med archive is not created, and
    // because there is a moment in day result, it should be included.
    XCTAssertNil(vc.medicationTrackerArchive);
    XCTAssertNotNil(vc.archive);
    XCTAssertEqual(mockArchiver.archivedResults.count, 1);
    NSDictionary *archivedObjects = [[mockArchiver.archivedResults allValues] firstObject];
    XCTAssertEqualObjects(archivedObjects[@"archive"], vc.archive);
    ORKTaskResult *archivedResult = archivedObjects[@"result"];
    XCTAssertEqualObjects(archivedResult, vc.overrideTaskResult);
    XCTAssertEqualObjects(vc.archive.reference,  @"abc123");
    XCTAssertNotNil(vc.archive.task);
}

- (void)testArchiveResults_WithMedicationTracking_NoMomentInDayResult
{
    APHParkinsonActivityViewController_Test *vc = [self createViewController:YES trackedMedications:@[]];
    MockAPCTaskResultArchiver *mockArchiver = (MockAPCTaskResultArchiver *)vc.taskResultArchiver;
    
    // Setup results
    vc.overrideTaskResult = [[ORKTaskResult alloc] initWithIdentifier:@"Tapping Activity"];
    vc.overrideTaskResult.results = @[[[ORKStepResult alloc] initWithIdentifier:APCDataGroupsStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:@"tapping.result"]];
    
    // Run method under test
    [vc archiveResults];
    
    // If there are medication tracking results then the med archive is created, and the
    // results should include a moment in day result
    XCTAssertNotNil(vc.medicationTrackerArchive);
    XCTAssertNotNil(vc.archive);
    XCTAssertEqual(mockArchiver.archivedResults.count, 2);
    
    NSDictionary *archivedObjects = mockArchiver.archivedResults[@"Tapping Activity"];
    XCTAssertEqualObjects(archivedObjects[@"archive"], vc.archive);
    ORKTaskResult *archivedResult = archivedObjects[@"result"];
    XCTAssertNotEqualObjects(archivedResult, vc.overrideTaskResult);
    XCTAssertNotNil([archivedResult resultForIdentifier:APHMedicationTrackerMomentInDayStepIdentifier]);
    XCTAssertNotNil([archivedResult resultForIdentifier:@"tapping.result"]);
    XCTAssertEqualObjects(vc.archive.reference,  @"abc123");
    XCTAssertNotNil(vc.archive.task);
    
    NSDictionary *medArchive = mockArchiver.archivedResults[APHMedicationTrackerTaskIdentifier];
    XCTAssertEqualObjects(medArchive[@"archive"], vc.medicationTrackerArchive);
    ORKTaskResult *medResult = medArchive[@"result"];
    XCTAssertNotNil([medResult resultForIdentifier:APCDataGroupsStepIdentifier]);
    XCTAssertNotNil([medResult resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier]);
    XCTAssertEqualObjects(vc.medicationTrackerArchive.reference,  APHMedicationTrackerTaskIdentifier);
    XCTAssertNil(vc.medicationTrackerArchive.task);
    XCTAssertEqualObjects(vc.medicationTrackerArchive.schemaRevision, @(1));
}

- (void)testArchiveResults_WithMedicationTracking_WithMomentInDayResult
{
    APHParkinsonActivityViewController_Test *vc = [self createViewController:YES trackedMedications:@[@"Levopdopa"]];
    MockAPCTaskResultArchiver *mockArchiver = (MockAPCTaskResultArchiver *)vc.taskResultArchiver;
    
    // Setup results
    vc.overrideTaskResult = [[ORKTaskResult alloc] initWithIdentifier:@"Tapping Activity"];
    vc.overrideTaskResult.results = @[[[ORKStepResult alloc] initWithIdentifier:APCDataGroupsStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerFrequencyStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerMomentInDayStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:APHMedicationTrackerActivityTimingStepIdentifier],
                                      [[ORKStepResult alloc] initWithIdentifier:@"tapping.result"]];
    
    // Run method under test
    [vc archiveResults];
    
    // If there are medication tracking results then the med archive is created, and the
    // results should include a moment in day result
    XCTAssertNotNil(vc.medicationTrackerArchive);
    XCTAssertNotNil(vc.archive);
    XCTAssertEqual(mockArchiver.archivedResults.count, 2);
    
    NSDictionary *archivedObjects = mockArchiver.archivedResults[@"Tapping Activity"];
    XCTAssertEqualObjects(archivedObjects[@"archive"], vc.archive);
    ORKTaskResult *archivedResult = archivedObjects[@"result"];
    XCTAssertNotEqualObjects(archivedResult, vc.overrideTaskResult);
    XCTAssertNotNil([archivedResult resultForIdentifier:APHMedicationTrackerMomentInDayStepIdentifier]);
    XCTAssertNotNil([archivedResult resultForIdentifier:@"tapping.result"]);
    XCTAssertEqualObjects(vc.archive.reference,  @"abc123");
    XCTAssertNotNil(vc.archive.task);
    
    NSDictionary *medArchive = mockArchiver.archivedResults[APHMedicationTrackerTaskIdentifier];
    XCTAssertEqualObjects(medArchive[@"archive"], vc.medicationTrackerArchive);
    ORKTaskResult *medResult = medArchive[@"result"];
    XCTAssertNotNil([medResult resultForIdentifier:APCDataGroupsStepIdentifier]);
    XCTAssertNotNil([medResult resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier]);
    XCTAssertNotNil([medResult resultForIdentifier:APHMedicationTrackerFrequencyStepIdentifier]);
    XCTAssertEqualObjects(vc.medicationTrackerArchive.reference,  APHMedicationTrackerTaskIdentifier);
    XCTAssertNil(vc.medicationTrackerArchive.task);
    XCTAssertEqualObjects(vc.medicationTrackerArchive.schemaRevision, @(1));
}

#pragma mark - helper methods

- (APHParkinsonActivityViewController_Test*)createViewController:(BOOL)hasSubTask trackedMedications:(NSArray*)trackedMedications {

    ORKOrderedTask  *inputTask = !hasSubTask ? nil : [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                      intendedUseDescription:nil
                                                         numberOfStepsPerLeg:20
                                                                restDuration:10
                                                                     options:ORKPredefinedTaskOptionNone];
    MockAPHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] initWithDictionaryRepresentation:nil subTask:inputTask];
    APHParkinsonActivityViewController_Test *vc = [[APHParkinsonActivityViewController_Test alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"APCTask" inManagedObjectContext:vc.mockUser.tempContext];
    vc.scheduledTask = [[APCTask alloc] initWithEntity:entity insertIntoManagedObjectContext:vc.mockUser.tempContext];
    MockAPCTaskResultArchiver *mockArchiver = [[MockAPCTaskResultArchiver alloc] init];
    vc.taskResultArchiver = mockArchiver;
    
    // If the tracked meds is non-nil, then set the value to the data store
    if (trackedMedications != nil) {
        NSMutableArray *meds = [NSMutableArray new];
        for (NSString *name in trackedMedications) {
            SBAMedication *med = [[SBAMedication alloc] initWithIdentifier:name];
            med.name = name;
            med.tracking = YES;
            [meds addObject:med];
        }
        task.mockDataStore.selectedItems = meds;
        [task.mockDataStore commitChanges];
        task.mockDataGroupsManager.surveyStepResult = [MockPDResult new];
    }
    
    return vc;
}

@end

@implementation APHParkinsonActivityViewController_Test

- (MockAPCUser *)mockUser {
    if (_mockUser == nil) {
        _mockUser = [[MockAPCUser alloc] init];
    }
    return _mockUser;
}

- (APCUser *)user {
    return (id)self.mockUser;
}

- (ORKTaskResult *)result {
    return self.overrideTaskResult ?: [super result];
}

@end
