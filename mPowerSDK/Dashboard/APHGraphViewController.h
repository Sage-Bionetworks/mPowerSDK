//
//  APHGraphViewController.h
//  mPowerSDK
//
//  Created by Andy Yeung on 3/3/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHGraphViewController : APCGraphViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *correlationSegmentControl;

@property (nonatomic) NSInteger selectedCorrelationTimeTab;

@property (nonatomic) BOOL shouldHideCorrelationSegmentControl;
@property (nonatomic) BOOL shouldHideAverageLabel;

@end
