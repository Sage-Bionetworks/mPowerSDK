//
//  APHTremorTaskViewController.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHTremorTaskViewController.h"

NSString * const kTremorScoreKey = @"tremor.score";
NSString * const kHandInLapScoreKey = @"tremor.handInLap.score";
NSString * const kHandAtShoulderLengthScoreKey = @"tremor.handAtShoulderLength.score";
NSString * const kHandAtShoulderLengthWithElbowBentScoreKey = @"tremor.handAtShoulderLengthWithElbowBent.score";
NSString * const kHandToNoseScoreKey = @"tremor.handToNose.score";
NSString * const kHandQueenWaveScoreKey = @"tremor.handQueenWave.score";

@interface APHTremorTaskViewController ()

@end

@implementation APHTremorTaskViewController

#pragma  mark  -  Task Creation Methods

+ (id<ORKTask>)createOrkTask:(APCTask *) __unused scheduledTask
{
    return  [[APHActivityManager defaultManager] createTaskForSurveyId:APHTremorActivitySurveyIdentifier];
}


#pragma  mark  -  Results For Dashboard

- (NSString *)createResultSummary
{
    __weak APHTremorTaskViewController *weakSelf = self;
    ORKTaskResult *taskResult = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext *context) {
        
        double handInLapScore;
        {
            // handInLap
            ORKStepResult *stepResult = (ORKStepResult *)[taskResult resultForIdentifier:@"tremor.handInLap"];
            handInLapScore = [weakSelf scoreForTremorStepResult:stepResult
                                        accelerometerIdentifier:@"ac1_acc"
                                               motionIdentifier:@"ac1_motion"];
        }
        
        double handAtShoulderLengthScore;
        {
            // handAtShoulderLength
            ORKStepResult *stepResult = (ORKStepResult *)[taskResult resultForIdentifier:@"tremor.handAtShoulderLength"];
            handAtShoulderLengthScore = [weakSelf scoreForTremorStepResult:stepResult
                                                   accelerometerIdentifier:@"ac2_acc"
                                                          motionIdentifier:@"ac2_motion"];
        }
        
        double handAtShoulderLengthWithElbowBentScore;
        {
            // handAtShoulderLengthWithElbowBent
            ORKStepResult *stepResult = (ORKStepResult *)[taskResult resultForIdentifier:@"tremor.handAtShoulderLengthWithElbowBent"];
            handAtShoulderLengthWithElbowBentScore = [weakSelf scoreForTremorStepResult:stepResult
                                                                accelerometerIdentifier:@"ac3_acc"
                                                                       motionIdentifier:@"ac3_motion"];
        }
        
        double handToNoseScore;
        {
            // handToNose
            ORKStepResult *stepResult = (ORKStepResult *)[taskResult resultForIdentifier:@"tremor.handToNose"];
            handToNoseScore = [weakSelf scoreForTremorStepResult:stepResult
                                         accelerometerIdentifier:@"ac4_acc"
                                                motionIdentifier:@"ac4_motion"];
        }

        double handQueenWaveScore;
        {
            // handQueenWave
            ORKStepResult *stepResult = (ORKStepResult *)[taskResult resultForIdentifier:@"tremor.handQueenWave"];
            handQueenWaveScore = [weakSelf scoreForTremorStepResult:stepResult
                                            accelerometerIdentifier:@"ac5_acc"
                                                   motionIdentifier:@"ac5_motion"];
            
        }
        
        
        double tremorScore = (handInLapScore + handAtShoulderLengthScore + handAtShoulderLengthWithElbowBentScore + handToNoseScore + handQueenWaveScore) / 5.0;
        
        NSDictionary *summary = @{ kTremorScoreKey: @(tremorScore),
                                   kHandInLapScoreKey: @(handInLapScore),
                                   kHandAtShoulderLengthScoreKey: @(handAtShoulderLengthScore),
                                   kHandAtShoulderLengthWithElbowBentScoreKey: @(handAtShoulderLengthWithElbowBentScore),
                                   kHandToNoseScoreKey: @(handToNoseScore),
                                   kHandQueenWaveScoreKey: @(handQueenWaveScore) };
        
        NSError  *error = nil;
        NSData  *data = [NSJSONSerialization dataWithJSONObject:summary options:0 error:&error];
        NSString *contentString = nil;
        if (data == nil) {
            APCLogError2 (error);
        } else {
            contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        if (contentString.length > 0) {
            [APCResult updateResultSummary:contentString forTaskResult:taskResult inContext:context];
        }
    };
    return nil;
}

- (double)scoreForTremorStepResult:(ORKStepResult *)stepResult
           accelerometerIdentifier:(NSString *)accelerometerIdentifier
                  motionIdentifier:(NSString *)motionIdentifier
{
    ORKFileResult *accelerometerResult, *motionResult;
    for (ORKResult *result in stepResult.results) {
        if (![result isKindOfClass:[ORKFileResult class]]) {
            continue;
        }
        
        if ([result.identifier isEqualToString:accelerometerIdentifier]) {
            accelerometerResult = (ORKFileResult *)result;
        } else if ([result.identifier isEqualToString:motionIdentifier]) {
            motionResult = (ORKFileResult *)result;
        }
    }
    
    return [[APHScoreCalculator sharedCalculator] scoreFromTremorAccelerometerURL:accelerometerResult.fileURL
                                                                        motionURL:motionResult.fileURL];
}


#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    self.preferStatusBarShouldBeHidden = NO;
}

@end
