//
//  APHMedicationTrackerTaskResultArchiverTests.m
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
#import <mPowerSDK/mPowerSDK.h>
#import "MockAPHMedicationTrackerTask.h"

@interface APHMedicationTrackerTaskResultArchiverTests : XCTestCase

@end

@interface MockDataArchive : APCDataArchive
@property (nonatomic) NSMutableArray <NSDictionary*> *insertObjects;
@end

@implementation APHMedicationTrackerTaskResultArchiverTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testArchiveResultWithMedicationSelected {
    
    MockAPHMedicationTrackerTask *task = [[MockAPHMedicationTrackerTask alloc] init];
    APHMedicationTrackerTaskResultArchiver *taskArchiver = [[APHMedicationTrackerTaskResultArchiver alloc] initWithTask:task];
    
    MockDataArchive *mockArchive = [[MockDataArchive alloc] init];
    ORKTaskResult *taskResult = [self createTaskResult];
    // use a nil for the filename translation dictionary to ensure that the results are archived as desired
    taskArchiver.filenameTranslationDictionary = @{};
    
    // archive the result
    [taskArchiver appendArchive:mockArchive withTaskResult:taskResult];
    
    XCTAssertEqual(mockArchive.insertObjects.count, 2);
    
    // Check the data group result
    NSDictionary *dataGroup = [mockArchive.insertObjects firstObject];
    XCTAssertEqualObjects(dataGroup[@"filename"], @"hasParkinsons.json");
    NSDictionary *dataGroupJson = dataGroup[@"dictionary"];
    XCTAssertNotNil(dataGroupJson);
    XCTAssertEqualObjects(dataGroupJson[@"answer"], @[@1]);

    // Check the selected medication result
    NSDictionary *selectedMedsObj = mockArchive.insertObjects[1];
    XCTAssertEqualObjects(selectedMedsObj[@"filename"], @"medicationSelection.json");
    NSDictionary *selectedMedsJson = selectedMedsObj[@"dictionary"];
    XCTAssertNotNil(selectedMedsJson);
    XCTAssertNotNil(selectedMedsJson[@"startDate"]);
    XCTAssertNotNil(selectedMedsJson[@"endDate"]);
    
    NSArray *selectedMeds = selectedMedsJson[@"items"];
    XCTAssertNotNil(selectedMeds);
    NSUInteger expectedCount = 3;
    XCTAssertEqual(selectedMeds.count, expectedCount);
        
    NSDictionary *levodopa = [selectedMeds objectWithIdentifier:@"Levodopa"];
    XCTAssertEqualObjects(levodopa[@"identifier"], @"Levodopa");
    XCTAssertEqualObjects(levodopa[@"name"], @"Levodopa");
    XCTAssertEqualObjects(levodopa[@"brand"], [NSNull null]);
    XCTAssertEqualObjects(levodopa[@"tracking"], @YES);
    XCTAssertEqualObjects(levodopa[@"injection"], @NO);
    XCTAssertEqualObjects(levodopa[@"frequency"], @4);
    
    NSDictionary *symmetrel = [selectedMeds objectWithIdentifier:@"Symmetrel"];
    XCTAssertEqualObjects(symmetrel[@"identifier"], @"Symmetrel");
    XCTAssertEqualObjects(symmetrel[@"name"], @"Amantadine");
    XCTAssertEqualObjects(symmetrel[@"brand"], @"Symmetrel");
    XCTAssertEqualObjects(symmetrel[@"tracking"], @NO);
    XCTAssertEqualObjects(symmetrel[@"injection"], @NO);
    XCTAssertEqualObjects(symmetrel[@"frequency"], @7);
    
    NSDictionary *apokyn = [selectedMeds objectWithIdentifier:@"Apokyn"];
    XCTAssertEqualObjects(apokyn[@"identifier"], @"Apokyn");
    XCTAssertEqualObjects(apokyn[@"name"], @"Apomorphine");
    XCTAssertEqualObjects(apokyn[@"brand"], @"Apokyn");
    XCTAssertEqualObjects(apokyn[@"tracking"], @NO);
    XCTAssertEqualObjects(apokyn[@"injection"], @YES);
    XCTAssertEqualObjects(apokyn[@"frequency"], @0);
}

#pragma mark - helper method

- (ORKTaskResult *)createTaskResult {

    // Add data group result
    ORKChoiceQuestionResult *controlResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"hasParkinsons"];
    controlResult.choiceAnswers = @[@(1)];
    ORKStepResult *dataGroupsStepResult = [[ORKStepResult alloc] initWithStepIdentifier:APCDataGroupsStepIdentifier results:@[controlResult]];
    
    // Add medication selection result
    ORKChoiceQuestionResult *medResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:APHMedicationTrackerSelectionStepIdentifier];
    medResult.choiceAnswers = @[@"Levodopa", @"Symmetrel", @"Apokyn"];
    ORKStepResult *medStepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerSelectionStepIdentifier results:@[medResult]];
    
    // Add frequency result
    // Add frequency question result
    ORKScaleQuestionResult *levodopaResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Levodopa"];
    levodopaResult.scaleAnswer = @(4);
    ORKScaleQuestionResult *symmetrelResult = [[ORKScaleQuestionResult alloc] initWithIdentifier:@"Symmetrel"];
    symmetrelResult.scaleAnswer = @(7);
    ORKStepResult *frequencyStepResult = [[ORKStepResult alloc] initWithStepIdentifier:APHMedicationTrackerFrequencyStepIdentifier
                                                                               results:@[levodopaResult, symmetrelResult]];
    
    ORKTaskResult *result = [[ORKTaskResult alloc] initWithIdentifier:APHMedicationTrackerTaskIdentifier];
    result.results = @[dataGroupsStepResult, medStepResult, frequencyStepResult];
    
    return result;
}


@end

@implementation MockDataArchive

- (NSMutableArray *)insertObjects {
    if (!_insertObjects) {
        _insertObjects = [NSMutableArray new];
    }
    return _insertObjects;
}

- (void)insertJSONDataIntoArchive:(NSData *)jsonData filename:(NSString *)filename
{
    [self.insertObjects addObject: @{ @"filename": filename,
                                      @"jsonData": jsonData}];
}

- (void)insertDictionaryIntoArchive:(NSDictionary *)dictionary filename: (NSString *)filename
{
    [self.insertObjects addObject: @{ @"filename": filename,
                                      @"dictionary": dictionary}];
}

- (void)insertDataAtURLIntoArchive: (NSURL*) url fileName: (NSString *) filename
{
    [self.insertObjects addObject: @{ @"filename": filename,
                                      @"url": url}];
}

- (void)insertDataIntoArchive :(NSData *)data filename: (NSString *)filename
{
    [self.insertObjects addObject: @{ @"filename": filename,
                                      @"data": data}];
}


@end
