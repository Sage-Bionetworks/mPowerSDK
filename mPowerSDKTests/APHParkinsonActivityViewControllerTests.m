//
//  APHParkinsonActivityViewControllerTests.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/27/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <mPowerSDK/mPowerSDK.h>
#import "MockAPHMedicationTrackerTask.h"
#import "MockAPCUser.h"
#import "MockAPCTaskResultArchiver.h"

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
        task.mockDataStore.skippedSelectMedicationsSurveyQuestion = YES;
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
        task.mockDataStore.skippedSelectMedicationsSurveyQuestion = YES;
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
            APHMedication *med = [APHMedication new];
            med.name = name;
            med.tracking = YES;
            [meds addObject:med];
        }
        task.mockDataStore.selectedMedications = meds;
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



//#pragma mark - Test view controller munging of results to include step if not there initially
//
//- (void)testDidFinish_WithMomentInDay
//{
//    APHParkinsonActivityViewController *vc = [self viewControllerIncludingMomentInDay:YES];
//
//    // Verify assumptions - If these fail then look to tests above for failures
//    XCTAssertEqual(vc.result.results.count, 2);
//    XCTAssertNil([vc.activityManager stashedMomentInDayResult]);
//
//    // Call delegate method on self (as per AppCore architecture)
//    [vc taskViewController:vc didFinishWithReason:ORKTaskViewControllerFinishReasonCompleted error:nil];
//
//    XCTAssertEqual(vc.result.results.count, 2);
//    XCTAssertEqualObjects(vc.result.results[0].identifier, @"momentInDay");
//    XCTAssertEqualObjects(vc.result.results[1].identifier, @"abc123");
//    XCTAssertNotNil([vc.activityManager stashedMomentInDayResult]);
//}
//
//- (void)testDidFinish_StashedMomentInDay
//{
//    APHParkinsonActivityViewController *vc = [self viewControllerIncludingMomentInDay:NO];
//
//    // Verify assumptions - If these fail then look to tests above for failures
//    XCTAssertEqual(vc.result.results.count, 1);
//    XCTAssertNotNil([vc.activityManager stashedMomentInDayResult]);
//
//    // Call delegate method on self (as per AppCore architecture)
//    [vc taskViewController:vc didFinishWithReason:ORKTaskViewControllerFinishReasonCompleted error:nil];
//
//    XCTAssertEqual(vc.result.results.count, 2);
//    XCTAssertEqualObjects(vc.result.results[0].identifier, @"momentInDay");
//    XCTAssertEqualObjects(vc.result.results[1].identifier, @"abc123");
//}
//
//#pragma mark - helper methods
//
//- (APHActivityManager *)managerWithStoredResult:(NSString*)storedAnswer {
//    // Setup the manager with Levodopa by default if answer isn't I don't take meds
//    NSArray *meds = [storedAnswer isEqualToString:kNoMedication] ? @[] : @[[[APHMedication alloc] initWithDictionaryRepresentation:@{@"name": @"Levodopa"}]];
//    return [self managerWithStoredResult:storedAnswer trackedMedications:meds];
//}
//
//- (APHActivityManager *)managerWithStoredResult:(NSString*)storedAnswer trackedMedications:(NSArray <APHMedication*> *)trackedMedications
//{
//    APHActivityManager *manager = [[APHActivityManager alloc] init];
//
//    // initialize a new user defaults
//    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
//
//    // Setup the manager with a saved result
//    if (storedAnswer != nil) {
//        [manager saveMomentInDayResult:[self momentInDayStepResult:storedAnswer]];
//    }
//
//    // Setup the manager with the Parkinson's data group by default
//    MockAPCDataGroupsManager *mockManager = [MockAPCDataGroupsManager new];
//    mockManager.surveyStepResult = [MockPDResult new];
//    manager.dataGroupsManager = mockManager;
//
//    // Save the tracked medications
//    [manager saveTrackedMedications:trackedMedications];
//
//    return manager;
//}
//
//- (APHActivityManager *)managerWithNoDataGroupsOrMedSurvey
//{
//    APHActivityManager *manager = [[APHActivityManager alloc] init];
//
//    // initialize a new user defaults
//    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
//
//    // Setup the manager with no saved data groups
//    MockAPCDataGroupsManager *mockManager = [MockAPCDataGroupsManager new];
//    manager.dataGroupsManager = mockManager;
//
//    return manager;
//}
//
//- (ORKStepResult *)momentInDayStepResult:(NSString*)storedAnswer
//{
//    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
//    input.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
//    input.endDate = [input.startDate dateByAddingTimeInterval:30];
//    input.questionType = ORKQuestionTypeSingleChoice;
//    input.choiceAnswers = @[storedAnswer];
//    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[input]];
//    return stepResult;
//}
//
//- (APHParkinsonActivityViewController *)viewControllerIncludingMomentInDay:(BOOL)includeMomentInDay {
//
//    APHActivityManager *manager = includeMomentInDay ? [self managerWithStoredResult:nil] : [self managerWithStoredResult:@"momentInDay"];
//    ORKOrderedTask  *task = (ORKOrderedTask *)[manager createOrderedTaskForSurveyId:APHWalkingActivitySurveyIdentifier];
//
//    APHParkinsonActivityViewController_Test *vc = [[APHParkinsonActivityViewController_Test alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
//
//    // Create task result
//    ORKFileResult *fileResult = [[ORKFileResult alloc] initWithIdentifier:@"abc"];
//    fileResult.fileURL = [NSURL URLWithString:@"http://test.org/12345"];
//    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"abc123" results:@[fileResult]];
//
//    vc.activityManager = manager;
//    vc.initialResults = includeMomentInDay ? @[[self momentInDayStepResult:@"momentInDay"], stepResult] : @[stepResult];
//
//    return vc;
//}