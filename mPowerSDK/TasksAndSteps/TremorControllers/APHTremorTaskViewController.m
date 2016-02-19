//
//  APHTremorTaskViewController.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHTremorTaskViewController.h"

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
    // TODO: implement this
    return nil;
}


/*
- (BOOL)preferStatusBarShouldBeHiddenForStep:(ORKStep*)step {
    return [step.identifier hasPrefix:APCTapTappingStepIdentifier];
}
 */


#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    self.preferStatusBarShouldBeHidden = NO;
}

@end
