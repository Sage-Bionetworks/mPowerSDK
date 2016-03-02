//
//  APHDashboardGraphTableViewCell.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@class APHScatterGraphView;

@protocol APHDashboardGraphTableViewCellDelegate <NSObject>

- (void)dashboardTableViewCellDidTapCorrelation1:(APCDashboardTableViewCell *)cell;
- (void)dashboardTableViewCellDidTapCorrelation2:(APCDashboardTableViewCell *)cell;

@end


@interface APHDashboardGraphTableViewCell : APCDashboardGraphTableViewCell

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *tintViews;
@property (weak, nonatomic) IBOutlet APHScatterGraphView *scatterGraphView;
@property (weak, nonatomic) IBOutlet APCLineGraphView *sparkLineGraphView;

@property (weak, nonatomic) IBOutlet UIView *correlationSelectorView;
@property (weak, nonatomic) IBOutlet UIButton *correlationButton1;
@property (weak, nonatomic) IBOutlet UIButton *correlationButton2;
@property (weak, nonatomic) IBOutlet UILabel *correlationVSLabel;

@property (weak, nonatomic) UIColor *correlationButton1TitleColor;
@property (weak, nonatomic) UIColor *correlationButton2TitleColor;

@property (nonatomic) BOOL showCorrelationSelectorView;
@property (nonatomic) BOOL showMedicationLegend;
@property (nonatomic) BOOL showSparkLineGraph;

@property (weak, nonatomic) id <APHDashboardGraphTableViewCellDelegate> correlationDelegate;

+ (CGFloat)medicationLegendContainerHeight;
+ (CGFloat)sparkLineGraphContainerHeight;

@end