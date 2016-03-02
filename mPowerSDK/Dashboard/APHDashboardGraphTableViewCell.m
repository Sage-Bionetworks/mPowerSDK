//
//  APHDashboardGraphTableViewCell.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHDashboardGraphTableViewCell.h"

const CGFloat kMedicationLegendContainerHeight = 80.f;
const CGFloat kSparkLineGraphContainerHeight = 142.f;

@interface APHDashboardGraphTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *medicationLegendContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sparkLineGraphContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *medicationLegendContainerView;
@property (weak, nonatomic) IBOutlet UIView *sparkLineGraphContainerView;

@end

@implementation APHDashboardGraphTableViewCell

+ (CGFloat)medicationLegendContainerHeight
{
    return kMedicationLegendContainerHeight;
}

+ (CGFloat)sparkLineGraphContainerHeight
{
    return kSparkLineGraphContainerHeight;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.button1DownCarrot setImage:[UIImage imageNamed:@"down_carrot"]];
    [self.button1DownCarrot setTintColor:[UIColor lightGrayColor]];
    
    [self.button2DownCarrot setImage:[UIImage imageNamed:@"down_carrot"]];
    [self.button2DownCarrot setTintColor:[UIColor lightGrayColor]];
}

#pragma mark - Accessors

- (void)setButton1Title:(NSString *)button1Title
{
    _button1Title = button1Title;
    [self.correlationButton1 setTitle:button1Title forState:UIControlStateNormal];
    
    CGRect frame = self.correlationButton1.titleLabel.frame;
    self.correlationButton1.titleLabel.frame = CGRectMake(0, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)setButton2Title:(NSString *)button2Title
{
    _button2Title = button2Title;
    [self.correlationButton2 setTitle:button2Title forState:UIControlStateNormal];
    
    CGRect frame = self.correlationButton2.titleLabel.frame;
    self.correlationButton2.titleLabel.frame = CGRectMake(0, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)setCorrelationButton1TitleColor:(UIColor *)correlationButton1TitleColor
{
    _correlationButton1TitleColor = correlationButton1TitleColor;
    self.correlationButton1.titleLabel.textColor = correlationButton1TitleColor;
}

- (void)setCorrelationButton2TitleColor:(UIColor *)correlationButton2TitleColor
{
    _correlationButton2TitleColor = correlationButton2TitleColor;
    self.correlationButton2.titleLabel.textColor = correlationButton2TitleColor;
}

- (void)setShowCorrelationSelectorView:(BOOL)showCorrelationSelectorView
{
    _showCorrelationSelectorView = showCorrelationSelectorView;
    self.correlationSelectorView.hidden = !showCorrelationSelectorView;
    self.legendButton.userInteractionEnabled = !showCorrelationSelectorView;
}

- (void)setShowMedicationLegend:(BOOL)showMedicationLegend
{
    _showMedicationLegend = showMedicationLegend;
    self.medicationLegendContainerHeightConstraint.constant = showMedicationLegend ? [[self class] medicationLegendContainerHeight] : 0.f;
    self.medicationLegendContainerView.hidden = !showMedicationLegend;
    [self setNeedsLayout];
}

- (void)setShowSparkLineGraph:(BOOL)showSparkLineGraph
{
    _showSparkLineGraph = showSparkLineGraph;
    self.sparkLineGraphContainerHeightConstraint.constant = showSparkLineGraph ? [[self class] sparkLineGraphContainerHeight] : 0.f;
    self.sparkLineGraphContainerView.hidden = !showSparkLineGraph;
    [self setNeedsLayout];
}

#pragma mark - IBActions

- (IBAction)correlationButton1Pressed:(UIButton *)sender {
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation1:self];
}

- (IBAction)correlationButton2Pressed:(UIButton *)sender {
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation2:self];
}

@end
