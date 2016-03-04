//
//  APHGraphViewController.m
//  mPowerSDK
//
//  Created by Andy Yeung on 3/3/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHGraphViewController.h"
#import "APHLineGraphView.h"

@interface APHGraphViewController ()

@end

@implementation APHGraphViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateViews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initilization Functions

- (void)updateViews
{
    self.subTitleLabel.hidden = self.shouldHideAverageLabel;
    
    if ([self.lineGraphView isKindOfClass:[APHLineGraphView class]]) {
        ((APHLineGraphView *)self.lineGraphView).shouldDrawLastPoint = YES;
        ((APHLineGraphView *)self.lineGraphView).colorForFirstCorrelationLine = [UIColor appTertiaryRedColor];
        ((APHLineGraphView *)self.lineGraphView).colorForSecondCorrelationLine = [UIColor appTertiaryYellowColor];
        
        self.lineGraphView.hidesDataPoints = YES;
    }
}

@end
