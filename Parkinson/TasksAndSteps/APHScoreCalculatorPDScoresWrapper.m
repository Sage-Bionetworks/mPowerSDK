//
//  ConverterForPDScores+PDScoresLib.m
//  Parkinson
//
//  Created by Shannon Young on 12/22/15.
//  Copyright © 2015 Apple, Inc. All rights reserved.
//

#import "APHScoreCalculatorPDScoresWrapper.h"
#import <PDScores/PDScores.h>

@implementation APHScoreCalculatorPDScoresWrapper

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

@end
