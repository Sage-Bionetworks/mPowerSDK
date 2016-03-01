//
//  APHDashboardGraphTableViewCell.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHDashboardGraphTableViewCell.h"

const CGFloat kMedicationSurveyPromptContainerHeight = 128.f;
const CGFloat kMedicationLegendContainerHeight = 80.f;

@interface APHDashboardGraphTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *medicationSurveyPromptContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *medicationLegendContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *medicationLegendContainerView;
@property (weak, nonatomic) IBOutlet UIView *medicationSurveyPromptContainerView;

@end

@implementation APHDashboardGraphTableViewCell

+ (CGFloat)medicationLegendContainerHeight
{
    return kMedicationLegendContainerHeight;
}

+ (CGFloat)medicationSurveyPromptContainerHeight
{
    return kMedicationSurveyPromptContainerHeight;
}


#pragma mark - Accessors

- (void)setShowMedicationLegend:(BOOL)showMedicationLegend
{
    _showMedicationLegend = showMedicationLegend;
    self.medicationLegendContainerHeightConstraint.constant = showMedicationLegend ? [[self class] medicationLegendContainerHeight] : 0.0f;
    self.medicationLegendContainerView.hidden = !showMedicationLegend;
    [self setNeedsLayout];
}

- (void)setShowMedicationSurveyPrompt:(BOOL)showMedicationSurveyPrompt
{
    _showMedicationSurveyPrompt = showMedicationSurveyPrompt;
    self.medicationSurveyPromptContainerHeightConstraint.constant = showMedicationSurveyPrompt ? [[self class] medicationSurveyPromptContainerHeight] : 0.0f;
    self.medicationSurveyPromptContainerView.hidden = !showMedicationSurveyPrompt;
    [self setNeedsLayout];
}


#pragma mark - IBActions

- (IBAction)enterMedicationsTapped:(id)__unused sender
{
    if ([self.medicationDelegate respondsToSelector:@selector(dashboardGraphTableViewCellDidTapEnterMedications:)]) {
        [self.medicationDelegate dashboardGraphTableViewCellDidTapEnterMedications:self];
    }
}

- (IBAction)notTakingMedicationsTapped:(id)__unused sender
{
    if ([self.medicationDelegate respondsToSelector:@selector(dashboardGraphTableViewCellDidTapNotTakingMedications:)]) {
        [self.medicationDelegate dashboardGraphTableViewCellDidTapNotTakingMedications:self];
    }
}

- (IBAction)doNotShowMedicationSurveyTapped:(id)__unused sender
{
    if ([self.medicationDelegate respondsToSelector:@selector(dashboardGraphTableViewCellDidTapDoNotShowMedicationSurvey:)]) {
        [self.medicationDelegate dashboardGraphTableViewCellDidTapDoNotShowMedicationSurvey:self];
    }
}


#pragma mark - APCDashboardGraphTableViewCell Overrides

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.enterMedicationsButton.backgroundColor = tintColor;
    self.notTakingMedicationsButton.backgroundColor = tintColor;
}

@end
