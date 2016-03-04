//
//  APHGraphViewController.h
//  mPowerSDK
//
//  Created by Andy Yeung on 3/3/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import "APHScatterGraphView.h"

@interface APHGraphViewController : APCGraphViewController

@property (nonatomic) IBOutletCollection(UIView) NSArray *keyShapeViewsArray;

@property (weak, nonatomic) IBOutlet UISegmentedControl *correlationSegmentControl;
@property (weak, nonatomic) IBOutlet APHScatterGraphView *scatterGraphView;

@property (nonatomic) NSInteger selectedCorrelationTimeTab;

@property (nonatomic) BOOL isForCorrelation;
@property (nonatomic) BOOL shouldHideCorrelationSegmentControl;
@property (nonatomic) BOOL shouldHideAverageLabel;

@end
