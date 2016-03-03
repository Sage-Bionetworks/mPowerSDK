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
- (void)dashboardTableViewCellDidChangeCorrelationSegment:(NSInteger) selectedIndex;

@end


@interface APHDashboardGraphTableViewCell : APCDashboardGraphTableViewCell

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *tintViews;
@property (weak, nonatomic) IBOutlet APHScatterGraphView *scatterGraphView;
@property (weak, nonatomic) IBOutlet APCLineGraphView *sparkLineGraphView;

@property (weak, nonatomic) IBOutlet UIView *correlationSelectorView;
@property (weak, nonatomic) IBOutlet UIButton *correlationButton1;
@property (weak, nonatomic) IBOutlet UIButton *correlationButton2;
@property (weak, nonatomic) IBOutlet UILabel *correlationVSLabel;
@property (weak, nonatomic) IBOutlet UIImageView *button1DownCarrot;
@property (weak, nonatomic) IBOutlet UIImageView *button2DownCarrot;

@property (weak, nonatomic) IBOutlet UISegmentedControl *correlationSegmentControl;

@property (weak, nonatomic) NSString *button1Title;
@property (weak, nonatomic) NSString *button2Title;
@property (weak, nonatomic) UIColor *correlationButton1TitleColor;
@property (weak, nonatomic) UIColor *correlationButton2TitleColor;

@property (nonatomic) BOOL hideTintBar;
@property (nonatomic) BOOL showCorrelationSelectorView;
@property (nonatomic) BOOL showCorrelationSegmentControl;
@property (nonatomic) BOOL showMedicationLegend;
@property (nonatomic) BOOL showSparkLineGraph;

@property (weak, nonatomic) id <APHDashboardGraphTableViewCellDelegate> correlationDelegate;

+ (CGFloat)medicationLegendContainerHeight;
+ (CGFloat)sparkLineGraphContainerHeight;
+ (CGFloat)correlationSelectorHeight;

@end