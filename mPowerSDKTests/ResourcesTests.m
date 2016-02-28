//
//  ResourcesTests.m
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
#import <APCAppCore/APCAppCore.h>
#import <mPowerSDK/mPowerSDK.h>
@import BridgeAppSDK;

@interface ResourcesTests : XCTestCase

@end

@implementation ResourcesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDataGroupsMapping
{
    id json = [self jsonForResource:@"DataGroupsMapping"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
    
    // Verify that the json is correct
    APCDataGroupsManager *dataGroupsManager = [[APCDataGroupsManager alloc] initWithDataGroups:nil mapping:json];
    
    // Currently the data groups are NOT required
    XCTAssertFalse(dataGroupsManager.needsUserInfoDataGroups);
    
    ORKFormStep *step = [dataGroupsManager surveyStep];
    XCTAssertEqual(step.formItems.count, 1);
    
    ORKFormItem *question = [step.formItems firstObject];
    ORKTextChoiceAnswerFormat *answerFormat = (ORKTextChoiceAnswerFormat *)question.answerFormat;
    XCTAssertEqual(answerFormat.textChoices.count, 2);
    
    // First answer yes
    ORKChoiceQuestionResult *choiceResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:question.identifier];
    choiceResult.choiceAnswers = @[@YES];
    ORKStepResult *result = [[ORKStepResult alloc] initWithStepIdentifier:step.identifier
                                                                  results:@[choiceResult]];
    [dataGroupsManager setSurveyAnswerWithStepResult:result];
    
    XCTAssertEqual(dataGroupsManager.dataGroups.count, 1);
    XCTAssertFalse(dataGroupsManager.isStudyControlGroup);
    
    
    // Next answer No
    choiceResult.choiceAnswers = @[@NO];
    result.results = @[choiceResult];
    [dataGroupsManager setSurveyAnswerWithStepResult:result];
    
    XCTAssertEqual(dataGroupsManager.dataGroups.count, 1);
    XCTAssertTrue(dataGroupsManager.isStudyControlGroup);
    
}

- (void)testMedicationTracking
{
    id json = [self jsonForResource:@"MedicationTracking"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
}

- (void)testConsentSection
{
    id json = [self jsonForResource:@"APHConsentSection"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
    
    NSArray <ORKStep *> *steps = [[[SBASurveyFactory alloc] initWithDictionary:json] steps];
    XCTAssertNotNil(steps);
    
    NSArray *expectedIdentifiers = @[@"consentVisual",
                                    @"consentQuiz",
                                    @"consentFailedQuiz",
                                    @"consentPassedQuiz",
                                    @"consentSharingOptions",
                                    @"consentReview",
                                    @"consentCompletion"];
    XCTAssertEqual(steps.count, expectedIdentifiers.count);
    for (NSInteger ii=0; ii < steps.count && ii < expectedIdentifiers.count; ii++) {
        XCTAssertEqualObjects(steps[ii].identifier, expectedIdentifiers[ii]);
    }
    
    if (steps.count < expectedIdentifiers.count) { return; }
    
    ORKStep *comprehensionStep = [[(id)[(id)steps[1] subtask] steps] firstObject];
    XCTAssertEqualObjects(comprehensionStep.title, @"Comprehension");
    
    ORKStep *subtaskStep = steps[1];
    XCTAssertTrue([subtaskStep isKindOfClass:[SBASurveySubtaskStep class]]);
    if ([subtaskStep isKindOfClass:[SBASurveySubtaskStep class]]) {
        NSArray <ORKStep *> *substeps = [(ORKOrderedTask*)[(SBASurveySubtaskStep*)subtaskStep subtask] steps];
        for (ORKStep *step in substeps) {
            XCTAssertNotEqual(step.title.length + step.text.length, 0, @"%@", step);
            if ([step isKindOfClass:[ORKFormStep class]]) {
                ORKFormStep *formStep = (ORKFormStep *)step;
                XCTAssertEqual(formStep.formItems.count, 1, @"%@", step);
                ORKFormItem *item = formStep.formItems.firstObject;
                XCTAssertNotNil(item, @"%@", step);
                XCTAssertNotNil(item.answerFormat, @"%@", step);
                if ([item.answerFormat isKindOfClass:[ORKTextChoiceAnswerFormat class]]) {
                    ORKTextChoiceAnswerFormat *answerFormat = (ORKTextChoiceAnswerFormat*)item.answerFormat;
                    XCTAssertNotEqual(answerFormat.textChoices.count, 0, @"%@", step);
                }
            }
            else {
                XCTAssertTrue([step isKindOfClass:[ORKInstructionStep class]], @"%@", step);
            }
        }
    }
    
    // Check that the navigation step returns to the start
    ORKStep *failedStep = steps[2];
    XCTAssertTrue([failedStep isKindOfClass:[SBADirectNavigationStep class]]);
    if (![failedStep isKindOfClass:[SBADirectNavigationStep class]]) {
        NSString *nextIdentifier = [(SBADirectNavigationStep*)failedStep nextStepIdentifier];
        XCTAssertEqualObjects(nextIdentifier, expectedIdentifiers.firstObject);
    }
    
}

- (void)testEligibilityRequirements
{
    id json = [self jsonForResource:@"EligibilityRequirements"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
}

- (id)jsonForResource:(NSString*)resourceName
{
    APHAppDelegate *appDelegate = [[APHAppDelegate alloc] init];
    NSString *path = [appDelegate pathForResource:resourceName ofType:@"json"];
    
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(jsonData);
    
    if (jsonData) {
        NSError *parseError;
        id json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseError];
        XCTAssertNil(parseError);
        XCTAssertNotNil(json);
        
        return json;
    }
    
    return nil;
}

@end
