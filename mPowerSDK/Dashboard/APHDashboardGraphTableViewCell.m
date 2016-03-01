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

#pragma mark - Accessors

- (void)setShowMedicationLegend:(BOOL)showMedicationLegend
{
    _showMedicationLegend = showMedicationLegend;
    self.medicationLegendContainerHeightConstraint.constant = showMedicationLegend ? [[self class] medicationLegendContainerHeight] : 0.0f;
    self.medicationLegendContainerView.hidden = !showMedicationLegend;
    [self setNeedsLayout];
}

@end
