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

@interface APHActivityManagerTests : XCTestCase

@end

@implementation APHActivityManagerTests

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
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createTaskForSurveyId:APHTappingActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"tapping.right"]);
    XCTAssertNotNil([task stepWithIdentifier:@"tapping.left"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard.");
}

- (void)testCreateOrderedTask_Voice_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createTaskForSurveyId:APHVoiceActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"audio"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard.");
}

- (void)testCreateOrderedTask_Memory_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createTaskForSurveyId:APHMemoryActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"cognitive.memory.spatialspan"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Good Job!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard.");
}

- (void)testCreateOrderedTask_Walking_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createTaskForSurveyId:APHWalkingActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"walking.outbound"]);
    XCTAssertNotNil([task stepWithIdentifier:@"walking.rest"]);
    
    // Return step should be removed
    XCTAssertNil([task stepWithIdentifier:@"walking.return"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard.");
}

- (void)testCreateOrderedTask_Tremor_English
{
    [APHLocalization setLocalization:@"en"];
    
    APHActivityManager *manager = [[APHActivityManager alloc] init];
    APHMedicationTrackerTask *medTask = (APHMedicationTrackerTask *)[manager createTaskForSurveyId:APHTremorActivitySurveyIdentifier];
    ORKOrderedTask *task  = (ORKOrderedTask *)medTask.subTask;
    XCTAssertNotNil(task);
    XCTAssertNotNil([task stepWithIdentifier:@"tremor.handInLap"]);
    XCTAssertNotNil([task stepWithIdentifier:@"tremor.handAtShoulderLength"]);
    //XCTAssertNotNil([task stepWithIdentifier:@"tremor.handAtShoulderLengthWithElbowBent"]);
    XCTAssertNotNil([task stepWithIdentifier:@"tremor.handToNose"]);
    //XCTAssertNotNil([task stepWithIdentifier:@"tremor.handQueenWave"]);
    
    // Check that the final step uses the expected language
    ORKStep *finalStep = task.steps.lastObject;
    XCTAssertEqualObjects(finalStep.title, @"Thank You!");
    XCTAssertEqualObjects(finalStep.text, @"The results of this activity can be viewed on the dashboard.");
}

@end


