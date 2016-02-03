//
//  APHScoreCalculatorTests.m
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

@interface APHScoreCalculatorTests : XCTestCase

@end

@interface APHScoreCalculator_TestWrapper : APHScoreCalculator
@property (nonatomic) double score;
@property (nonatomic) NSArray *convertedData;
@property (nonatomic) NSString *scoreMethodCalled;
@end

@implementation APHScoreCalculatorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testScoreFromTappingResult_NoData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[];
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromTappingResult:[[ORKTappingIntervalResult alloc] init]];
    XCTAssertEqualWithAccuracy(result, 0.0, 0.000001);
    XCTAssertNil(calculator.scoreMethodCalled);
}

- (void)testScoreFromTappingResult_WithData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[@(12), @(13)];
    calculator.score = 12.5;
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromTappingResult:[[ORKTappingIntervalResult alloc] init]];
    XCTAssertEqualWithAccuracy(result, 12.5, 0.000001);
    XCTAssertEqualObjects(calculator.scoreMethodCalled, @"scoreFromTappingTest:");
}

- (void)testScoreFromGaitURL_NoData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[];
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromGaitURL:[NSURL URLWithString:@"file://test"]];
    XCTAssertEqualWithAccuracy(result, 0.0, 0.000001);
    XCTAssertNil(calculator.scoreMethodCalled);
}

- (void)testScoreFromGaitURL_WithData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[@(12), @(13)];
    calculator.score = 12.5;
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromGaitURL:[NSURL URLWithString:@"file://test"]];
    XCTAssertEqualWithAccuracy(result, 12.5, 0.000001);
    XCTAssertEqualObjects(calculator.scoreMethodCalled, @"scoreFromGaitTest:");
}

- (void)testScoreFromPostureURL_NoData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[];
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromPostureURL:[NSURL URLWithString:@"file://test"]];
    XCTAssertEqualWithAccuracy(result, 0.0, 0.000001);
    XCTAssertNil(calculator.scoreMethodCalled);
}

- (void)testScoreFromPostureURL_WithData
{
    APHScoreCalculator_TestWrapper *calculator = [[APHScoreCalculator_TestWrapper alloc] init];
    calculator.convertedData = @[@(12), @(13)];
    calculator.score = 12.5;
    
    // An empty data set should *not* call through to the score method and should return 0
    double result = [calculator scoreFromPostureURL:[NSURL URLWithString:@"file://test"]];
    XCTAssertEqualWithAccuracy(result, 12.5, 0.000001);
    XCTAssertEqualObjects(calculator.scoreMethodCalled, @"scoreFromPostureTest:");
}

@end

@implementation APHScoreCalculator_TestWrapper

- (NSArray*)convertTappings:(ORKTappingIntervalResult *)result
{
    return self.convertedData;
}

- (NSArray*)convertPostureOrGain:(NSURL *)url
{
    return self.convertedData;
}

- (double)scoreFromTappingTest:(NSArray *)tappingData
{
    self.scoreMethodCalled = @"scoreFromTappingTest:";
    return self.score;
}

- (double)scoreFromPhonationTest:(NSURL *)phonationAudioFile
{
    self.scoreMethodCalled = @"scoreFromPhonationTest:";
    return self.score;
}

- (double)scoreFromGaitTest:(NSArray *)gaitData
{
    self.scoreMethodCalled = @"scoreFromGaitTest:";
    return self.score;
}

- (double)scoreFromPostureTest:(NSArray *)postureData
{
    self.scoreMethodCalled = @"scoreFromPostureTest:";
    return self.score;
}

@end
