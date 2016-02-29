// 
//  ConverterForPDScores.m 
//  mPower 
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
 
#import "APHScoreCalculator.h"
#import "APHAppDelegate.h"
#import <PDScores/PDScores.h>

NSString *const kTappingViewSizeKey   = @"TappingViewSize";
NSString *const kStartDateKey         = @"startDate";
NSString *const kEndDateKey           = @"endDate";

NSString *const kButtonRectLeftKey    = @"ButtonRectLeft";
NSString *const kButtonRectRightKey   = @"ButtonRectRight";
NSString *const kTapTimeStampKey      = @"TapTimeStamp";
NSString *const kTapCoordinateKey     = @"TapCoordinate";

NSString *const kTappedButtonNoneKey  = @"TappedButtonNone";
NSString *const kTappedButtonLeftKey  = @"TappedButtonLeft";
NSString *const kTappedButtonRightKey = @"TappedButtonRight";

NSString *const  kTappedButtonIdKey   = @"TappedButtonId";

NSString *const kQuestionTypeKey      = @"questionType";
NSString *const kQuestionTypeNameKey  = @"questionTypeName";
NSString *const kUserInfoKey          = @"userInfo";
NSString *const kIdentifierKey        = @"identifier";

NSString *const kTaskRunKey           = @"taskRun";
NSString *const kItemKey              = @"item";

static  NSString  *kTappingSamplesKey = @"TappingSamples";

@implementation APHScoreCalculator

+ (APHScoreCalculator *)sharedCalculator
{
    static id __defaultInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultInstance = [[self alloc] init];
    });
    return __defaultInstance;
}

- (NSArray*)convertTappings:(ORKTappingIntervalResult *)result
{
    NSMutableDictionary  *rawTappingResults = [NSMutableDictionary dictionary];
    
    NSString  *tappingViewSize = NSStringFromCGSize(result.stepViewSize);
    rawTappingResults[kTappingViewSizeKey] = tappingViewSize;
    
    rawTappingResults[kStartDateKey] = result.startDate;
    rawTappingResults[kEndDateKey]   = result.endDate;
    
    NSString  *leftButtonRect = NSStringFromCGRect(result.buttonRect1);
    rawTappingResults[kButtonRectLeftKey] = leftButtonRect;
    
    NSString  *rightButtonRect = NSStringFromCGRect(result.buttonRect2);
    rawTappingResults[kButtonRectRightKey] = rightButtonRect;
    
    NSArray  *samples = result.samples;
    NSMutableArray  *sampleResults = [NSMutableArray array];
    for (ORKTappingSample *sample  in  samples) {
        NSMutableDictionary  *aSampleDictionary = [NSMutableDictionary dictionary];
        
        aSampleDictionary[kTapTimeStampKey]     = @(sample.timestamp);
        
        aSampleDictionary[kTapCoordinateKey]   = NSStringFromCGPoint(sample.location);
        
        if (sample.buttonIdentifier == ORKTappingButtonIdentifierNone) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonNoneKey;
        } else if (sample.buttonIdentifier == ORKTappingButtonIdentifierLeft) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonLeftKey;
        } else if (sample.buttonIdentifier == ORKTappingButtonIdentifierRight) {
            aSampleDictionary[kTappedButtonIdKey] = kTappedButtonRightKey;
        }
        [sampleResults addObject:aSampleDictionary];
    }
    return sampleResults;
}

- (NSArray*)convertPostureOrGain:(NSURL *)url
{
    NSArray  *gaitItems = nil;
    if (url != nil) {
        NSData  *jsonData = [NSData dataWithContentsOfURL:url];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
        gaitItems = [json objectForKey:@"items"];
    }
    return  gaitItems;
}

- (double)scoreFromTappingResult:(ORKTappingIntervalResult *)result
{
    NSArray *data = [self convertTappings:result];
    if (data.count == 0) {
        return 0.0;
    }
    else {
        return [self scoreFromTappingTest:data];
    }
}

- (double)scoreFromGaitURL:(NSURL *)url
{
    NSArray *data = [self convertPostureOrGain:url];
    if (data.count == 0) {
        return 0.0;
    }
    else {
        return [self scoreFromGaitTest:data];
    }
}

- (double)scoreFromPostureURL:(NSURL *)url
{
    NSArray *data = [self convertPostureOrGain:url];
    if (data.count == 0) {
        return 0.0;
    }
    else {
        return [self scoreFromPostureTest:data];
    }
}

- (double)scoreFromTremorAccelerometerURL:(NSURL *)accelerometerURL motionURL:(NSURL *)motionURL
{
    NSArray *accelerometerData = [self convertPostureOrGain:accelerometerURL];
    NSArray *motionData = [self convertPostureOrGain:motionURL];
    if (accelerometerData.count == 0 || motionData.count == 0) {
        return 0.0;
    } else {
        return [self scoreFromTremorTestAccelerometerData:accelerometerData motionData:motionData];
    }
}

- (double)scoreFromTappingTest:(NSArray *)tappingData
{
    return [PDScores scoreFromTappingTest:tappingData];
}

- (double)scoreFromPhonationTest:(NSURL *)phonationAudioFile
{
    return [PDScores scoreFromPhonationTest:phonationAudioFile];
}

- (double)scoreFromGaitTest:(NSArray *)gaitData
{
    return [PDScores scoreFromGaitTest:gaitData];
}

- (double)scoreFromPostureTest:(NSArray *)postureData
{
    return [PDScores scoreFromPostureTest:postureData];
}

- (double)scoreFromTremorTestAccelerometerData:(NSArray *)tremorAccelerometerData motionData:(NSArray *)tremorMotionData
{
    // TODO: implement tremor calculation support in PDScores (Jake Krog - 2/29/2016)
    // return [PDScores scoreFromTremorTestAccelerometerData:tremorAccelerometerData motionData:tremorMotionData];
    
    return 0.0;
}

@end
