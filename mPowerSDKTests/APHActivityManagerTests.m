//
//  APHParkinsonActivityViewControllerTests.m
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

@interface APHParkinsonActivityViewControllerTests : XCTestCase

@end


@interface APHParkinsonActivityViewController (PrivateTest)
@property (nonatomic, strong) ORKTaskResult * _Nullable stashedResult;
@property (nonatomic, strong) APHActivityManager *activityManager;
@end

@interface APHParkinsonActivityViewController_Test : APHParkinsonActivityViewController
@property (nonatomic) NSArray *initialResults;
@end

@implementation APHParkinsonActivityViewControllerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - test factory to create task

- (void)testCreateOrderedTask_Tapping_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createOrderedTaskForSurveyId:APHTappingActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"tapping.right"]);
    XCTAssertNotNil([task stepWithIdentifier:@"tapping.left"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard");
}

- (void)testCreateOrderedTask_Voice_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createOrderedTaskForSurveyId:APHVoiceActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"audio"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard");
}

- (void)testCreateOrderedTask_Memory_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createOrderedTaskForSurveyId:APHMemoryActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"cognitive.memory.spatialspan"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard");
}

- (void)testCreateOrderedTask_Walking_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createOrderedTaskForSurveyId:APHWalkingActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"walking.outbound"]);
    XCTAssertNotNil([task stepWithIdentifier:@"walking.rest"]);
    
    // Return step should be removed
    XCTAssertNil([task stepWithIdentifier:@"walking.return"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard");
}


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


@end

@implementation APHParkinsonActivityViewController_Test

- (NSArray *)managedResults {
    return self.initialResults;
}

@end

