//
//  APHDashboardGraphTableViewCell.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHDashboardGraphTableViewCell.h"

const CGFloat kMedicationLegendContainerHeight = 80.f;

@interface APHDashboardGraphTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *medicationLegendContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *medicationLegendContainerView;

@end

@implementation APHDashboardGraphTableViewCell

+ (CGFloat)medicationLegendContainerHeight
{
    return kMedicationLegendContainerHeight;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self giveButtonDownCarrot:self.correlationButton1];
    [self giveButtonDownCarrot:self.correlationButton2];
}

#pragma mark - Helper Methods

- (void)giveButtonDownCarrot:(UIButton *)button
{
    CGFloat buttonWidth = button.frame.size.width;
    CGFloat offset = buttonWidth - 20;
    
    [button setImage:[UIImage imageNamed:@"down_carrot"] forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -offset, 0, 0)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(5, offset - 5, 5, 5)];
    
    [button.imageView setTintColor:[UIColor lightGrayColor]];
}

#pragma mark - Accessors

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

- (void)setShowMedicationLegend:(BOOL)showMedicationLegend
{
    _showMedicationLegend = showMedicationLegend;
    self.medicationLegendContainerHeightConstraint.constant = showMedicationLegend ? [[self class] medicationLegendContainerHeight] : 0.0f;
    self.medicationLegendContainerView.hidden = !showMedicationLegend;
    [self setNeedsLayout];
}

- (void)setShowCorrelationSelectorView:(BOOL)showCorrelationSelectorView
{
    _showCorrelationSelectorView = showCorrelationSelectorView;
    self.correlationSelectorView.hidden = !showCorrelationSelectorView;
    self.legendButton.userInteractionEnabled = !showCorrelationSelectorView;
}

#pragma mark - Outlets

- (IBAction)correlationButton1Pressed:(UIButton *)sender {
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation1:self];
}

- (IBAction)correlationButton2Pressed:(UIButton *)sender {
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation2:self];
}

@end
