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

@interface APHMomentInDayStepManager (PrivateTest)
@property (nonatomic) NSUserDefaults *storedDefaults;
@end

@implementation APHParkinsonActivityViewControllerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateMomentInDayStep_English
{
    // set to the English bundle
    [APHLocalization setLocalization:@"en"];
    
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
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

- (void)testStashedSurvey
{
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
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
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:stepId results:@[input]];
    
    // --- test save/recover methods
    [manager saveMomentInDayResult:stepResult];
    ORKChoiceQuestionResult *output = [manager stashedMomentInDayResult];
    
    XCTAssertNotNil(output);
    XCTAssertEqualObjects(output.identifier, uuid);
    XCTAssertEqualObjects(output.startDate, startDate);
    XCTAssertEqualObjects(output.endDate, endDate);
    XCTAssertEqualObjects(output.choiceAnswers, @[@"1234abc"]);
    XCTAssertEqual(output.questionType, ORKQuestionTypeSingleChoice);
}

- (void)testShouldIncludeMomentInDayStep_LastCompletionNil
{
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // For a nil date, the moment in day step should be included
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:nil]);
}

- (void)testShouldIncludeMomentInDayStep_StashNil
{
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // Even if the time is very recent, should include moment in day step
    // if the stashed result is nil.
    NSDate *now = [NSDate date];
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:now]);
}

- (void)testShouldIncludeMomentInDayStep_TakesMedication
{
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // Setup the manager with a saved result that is *not* the "no medication" result
    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"abc123"];
    input.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    input.endDate = [input.startDate dateByAddingTimeInterval:30];
    input.questionType = ORKQuestionTypeSingleChoice;
    input.choiceAnswers = @[@"1234abc"];
    NSString *stepId = [[NSUUID UUID] UUIDString];
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:stepId results:@[input]];
    [manager saveMomentInDayResult:stepResult];
    
    // For a recent time, should NOT include step
    XCTAssertFalse([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-2*60]]);
    
    // If it has been more than 30 minutes, should ask the question again
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-30*60]]);
}

- (void)testShouldIncludeMomentInDayStep_NoMedication
{
    APHMomentInDayStepManager *manager = [[APHMomentInDayStepManager alloc] init];
    manager.storedDefaults = [[NSUserDefaults alloc] initWithSuiteName:[[NSUUID UUID] UUIDString]];
    
    // Setup the manager with a saved result that is *not* the "no medication" result
    ORKChoiceQuestionResult *input = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"abc123"];
    input.startDate = [NSDate dateWithTimeIntervalSinceNow:-2*60];
    input.endDate = [input.startDate dateByAddingTimeInterval:30];
    input.questionType = ORKQuestionTypeSingleChoice;
    input.choiceAnswers = @[kNoMedication];
    NSString *stepId = [[NSUUID UUID] UUIDString];
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:stepId results:@[input]];
    [manager saveMomentInDayResult:stepResult];
    
    // If asked today, should NOT include step
    XCTAssertFalse([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-8*60*60]]);
    
    // If it has been more than 30 days, should ask the question again
    XCTAssertTrue([manager shouldIncludeMomentInDayStep:[NSDate dateWithTimeIntervalSinceNow:-35*24*60*60]]);
}


@end

