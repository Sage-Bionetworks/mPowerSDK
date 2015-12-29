//
//  APHParkinsonActivityViewControllerTests.m
//  mPowerSDK
//
//  Created by Shannon Young on 12/28/15.
//  Copyright © 2015 Sage Bionetworks. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <mPowerSDK/mPowerSDK.h>


NSString *const kNoMedication = @"I don't take Parkinson medications";

@interface APHParkinsonActivityViewControllerTests : XCTestCase

@end

@interface APHActivityManager (PrivateTest)
@property (nonatomic) NSUserDefaults *storedDefaults;
@property (nonatomic) NSDate *lastCompletionDate;
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

#pragma mark - test modification of task if required

- (void)testModifyTaskWithPreSurveyStep_Required
{
    APHActivityManager *manager = [self managerWithStoredResult:nil];
    
    ORKOrderedTask  *inputTask = [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                    intendedUseDescription:nil
                                                       numberOfStepsPerLeg:20
                                                              restDuration:10
                                                                   options:ORKPredefinedTaskOptionNone];
    
    ORKOrderedTask *outputTask = [manager modifyTaskWithPreSurveyStepIfRequired:inputTask andTitle:@"Title"];
    
    XCTAssertNotNil(outputTask);
    XCTAssertNotEqualObjects(inputTask, outputTask);
    XCTAssertNotNil([outputTask stepWithIdentifier:kMomentInDayStepIdentifier]);
}

- (void)testModifyTaskWithPreSurveyStep_NotRequired
{
    APHActivityManager *manager = [self managerWithStoredResult:@"1234abc"];
    manager.lastCompletionDate = [NSDate dateWithTimeIntervalSinceNow:-60];
    
    ORKOrderedTask  *inputTask = [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                      intendedUseDescription:nil
                                                         numberOfStepsPerLeg:20
                                                                restDuration:10
                                                                     options:ORKPredefinedTaskOptionNone];
    
    ORKOrderedTask *outputTask = [manager modifyTaskWithPreSurveyStepIfRequired:inputTask andTitle:@"Title"];
    
    XCTAssertNotNil(outputTask);
    XCTAssertEqualObjects(inputTask, outputTask);
    XCTAssertNil([outputTask stepWithIdentifier:kMomentInDayStepIdentifier]);
}

#pragma mark - test validation of when to ask question again

- (void)testShouldIncludeMomentInDayStep_LastCompletionNil
{
    APHActivityManager *manager = [self managerWithStoredResult:@"1234abc"];
    
    // For a nil date, the moment in day step should be included
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:nil]);
}

- (void)testShouldIncludeMomentInDayStep_StashNil
{
    APHActivityManager *manager = [self managerWithStoredResult:nil];
    
    // Even if the time is very recent, should include moment in day step
    // if the stashed result is nil.
    NSDate *now = [NSDate date];
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:now]);
}

- (void)testShouldIncludeMomentInDayStep_TakesMedication
{
    APHActivityManager *manager = [self managerWithStoredResult:@"1234abc"];
    
    // For a recent time, should NOT include step
    XCTAssertFalse([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-2*60]]);
    
    // If it has been more than 30 minutes, should ask the question again
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-30*60]]);
}

- (void)testShouldIncludeMomentInDayStep_NoMedication
{
    APHActivityManager *manager = [self managerWithStoredResult:kNoMedication];
    
    // If asked today, should NOT include step
    XCTAssertFalse([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-8*60*60]]);
    
    // If it has been more than 30 days, should ask the question again
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-35*24*60*60]]);
}

#pragma mark - test of creation of moment in day step

- (void)testCreateMomentInDayStep_English
{
    // set to the English bundle
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    ORKFormStep *step = [manager createMomentInDayStep];
    
    XCTAssertNotNil(step);
    XCTAssertEqualObjects(step.identifier, kMomentInDayStepIdentifier);
    XCTAssertEqualObjects(step.text, @"We would like to understand how your performance on this activity could be affected by the timing of your medication.");
    
    ORKFormItem  *item = [step.formItems firstObject];
    XCTAssertEqual(step.formItems.count, 1);
    XCTAssertEqualObjects(item.identifier, @"momentInDayFormat");
    XCTAssertEqualObjects(item.text, @"When was the last time you took any of your PARKINSON MEDICATIONS?");
    XCTAssertTrue([item.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]);
    
    NSArray <ORKTextChoice *> *choices = ((ORKTextChoiceAnswerFormat*)item.answerFormat).textChoices;
    XCTAssertEqual(choices.count, 8);
    
    XCTAssertEqualObjects(choices[0].text, @"0-30 minutes ago");
    XCTAssertEqualObjects(choices[0].value, @"0-30 minutes ago");
    
    XCTAssertEqualObjects(choices[1].text, @"30-60 minutes ago");
    XCTAssertEqualObjects(choices[1].value, @"30-60 minutes ago");
    
    XCTAssertEqualObjects(choices[2].text, @"1-2 hours ago");
    XCTAssertEqualObjects(choices[2].value, @"1-2 hours ago");
    
    XCTAssertEqualObjects(choices[3].text, @"2-4 hours ago");
    XCTAssertEqualObjects(choices[3].value, @"2-4 hours ago");
    
    XCTAssertEqualObjects(choices[4].text, @"4-8 hours ago");
    XCTAssertEqualObjects(choices[4].value, @"4-8 hours ago");
    
    XCTAssertEqualObjects(choices[5].text, @"More than 8 hours ago");
    XCTAssertEqualObjects(choices[5].value, @"More than 8 hours ago");

    XCTAssertEqualObjects(choices[6].text, @"Not sure");
    XCTAssertEqualObjects(choices[6].value, @"Not sure");
    
    XCTAssertEqualObjects(choices[7].text, @"I don't take Parkinson medications");
    XCTAssertEqualObjects(choices[7].value, kNoMedication);
}

#pragma mark - test stashing survey

- (void)testStashedSurvey
{
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // Create a choice question result
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-60.0];
    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:-20.0];
    
    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[uuid copy]];
    input.startDate = [startDate copy];
    input.endDate = [endDate copy];
    input.questionType = ORKQuestionTypeSingleChoice;
    input.choiceAnswers = @[@"1234abc"];
    NSString *stepId = [[NSUUID UUID] UUIDString];
    ORKStepResult *inStepResult = [[ORKStepResult alloc] initWithStepIdentifier:stepId results:@[input]];
    
    // --- test save/recover methods
    [manager saveMomentInDayResult:inStepResult];
    ORKStepResult *outStepResult = [manager stashedMomentInDayResult];
    ORKChoiceQuestionResult *output = (ORKChoiceQuestionResult *)[outStepResult.results firstObject];
    
    XCTAssertNotNil(output);
    XCTAssertEqualObjects(output.identifier, uuid);
    XCTAssertEqualObjects(output.startDate, startDate);
    XCTAssertEqualObjects(output.endDate, endDate);
    XCTAssertEqualObjects(output.choiceAnswers, @[@"1234abc"]);
    XCTAssertEqual(output.questionType, ORKQuestionTypeSingleChoice);
}

#pragma mark - Test view controller munging of results to include step if not there initially

- (void)testDidFinish_WithMomentInDay
{
    APHParkinsonActivityViewController *vc = [self viewControllerIncludingMomentInDay:YES];
    
    // Verify assumptions - If these fail then look to tests above for failures
    XCTAssertEqual(vc.result.results.count, 2);
    XCTAssertNil([vc.activityManager stashedMomentInDayResult]);
    
    // Call delegate method on self (as per AppCore architecture)
    [vc taskViewController:vc didFinishWithReason:ORKTaskViewControllerFinishReasonCompleted error:nil];
    
    XCTAssertEqual(vc.result.results.count, 2);
    XCTAssertEqualObjects(vc.result.results[0].identifier, @"momentInDay");
    XCTAssertEqualObjects(vc.result.results[1].identifier, @"abc123");
    XCTAssertNotNil([vc.activityManager stashedMomentInDayResult]);
}

- (void)testDidFinish_StashedMomentInDay
{
    APHParkinsonActivityViewController *vc = [self viewControllerIncludingMomentInDay:NO];
    
    // Verify assumptions - If these fail then look to tests above for failures
    XCTAssertEqual(vc.result.results.count, 1);
    XCTAssertNotNil([vc.activityManager stashedMomentInDayResult]);
    
    // Call delegate method on self (as per AppCore architecture)
    [vc taskViewController:vc didFinishWithReason:ORKTaskViewControllerFinishReasonCompleted error:nil];
    
    XCTAssertEqual(vc.result.results.count, 2);
    XCTAssertEqualObjects(vc.result.results[0].identifier, @"momentInDay");
    XCTAssertEqualObjects(vc.result.results[1].identifier, @"abc123");
}

#pragma mark - helper methods

- (APHActivityManager *)managerWithStoredResult:(NSString*)storedAnswer
{
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    
    // initialize a new user defaults
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // Setup the manager with a saved result that is *not* the "no medication" result
    if (storedAnswer != nil) {
        [manager saveMomentInDayResult:[self momentInDayStepResult:storedAnswer]];
    }
    
    return manager;
}

- (ORKStepResult *)momentInDayStepResult:(NSString*)storedAnswer
{
    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    input.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    input.endDate = [input.startDate dateByAddingTimeInterval:30];
    input.questionType = ORKQuestionTypeSingleChoice;
    input.choiceAnswers = @[storedAnswer];
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"momentInDay" results:@[input]];
    return stepResult;
}

- (APHParkinsonActivityViewController *)viewControllerIncludingMomentInDay:(BOOL)includeMomentInDay {

    ORKOrderedTask  *task = [ORKOrderedTask shortWalkTaskWithIdentifier:@"abc123"
                                                 intendedUseDescription:nil
                                                    numberOfStepsPerLeg:20
                                                           restDuration:10
                                                                options:ORKPredefinedTaskOptionNone];
    if (includeMomentInDay) {
        task = [[APHActivityManager defaultManager] modifyTaskWithPreSurveyStepIfRequired:task andTitle:@"Title"];
    }
    
    APHParkinsonActivityViewController_Test *vc = [[APHParkinsonActivityViewController_Test alloc] initWithTask:task taskRunUUID:[NSUUID UUID]];
    
    // Create task result
    ORKFileResult *fileResult = [[ORKFileResult alloc] initWithIdentifier:@"abc"];
    fileResult.fileURL = [NSURL URLWithString:@"http://test.org/12345"];
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"abc123" results:@[fileResult]];
    
    if (includeMomentInDay) {
        vc.activityManager = [self managerWithStoredResult:nil];
        vc.initialResults = @[[self momentInDayStepResult:@"momentInDay"], stepResult];
    }
    else {
        vc.activityManager = [self managerWithStoredResult:@"momentInDay"];
        vc.initialResults = @[stepResult];
    }
    
    return vc;
}


@end

@implementation APHParkinsonActivityViewController_Test

- (NSArray *)managedResults {
    return self.initialResults;
}

@end

