//
//  APHScoreCalculatorTests.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/5/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
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
