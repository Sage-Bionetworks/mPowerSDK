//
//  APHGraphViewController.h
//  mPowerSDK
//
//  Created by Andy Yeung on 3/3/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import "APHScatterGraphView.h"
#import "APHMedTimingLegendView.h"

@interface APHGraphViewController : APCGraphViewController

@property (nonatomic) IBOutletCollection(UIView) NSArray *keyShapeViewsArray;

@property (weak, nonatomic) IBOutlet APHScatterGraphView *scatterGraphView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *correlationSegmentControl;
@property (weak, nonatomic) IBOutlet APHMedTimingLegendView *medicationLegendContainerView;

@property (nonatomic) UIColor *tintColor;

@property (nonatomic) BOOL isForCorrelation;
@property (nonatomic) BOOL shouldHideCorrelationSegmentControl;
@property (nonatomic) BOOL shouldHideAverageLabel;
@property (nonatomic) NSInteger selectedCorrelationTimeTab;

@end