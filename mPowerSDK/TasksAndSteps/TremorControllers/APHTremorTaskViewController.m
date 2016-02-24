//
//  APHTremorTaskViewController.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHTremorTaskViewController.h"

NSString * const kTremorScoreKey = @"TremorScoreKey";

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
    ORKTaskResult *taskResult = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext *context) {
        
        // TODO: calculate tremor score from results (Jake Krog - 2/23/2016)
        NSDictionary *summary = @{ kTremorScoreKey: @0 };
        
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


#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    self.preferStatusBarShouldBeHidden = NO;
}

@end
