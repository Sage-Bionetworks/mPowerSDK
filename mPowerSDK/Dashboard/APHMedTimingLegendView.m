//
//  APHMedTimingLegendView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHMedTimingLegendView.h"
#import "APHCircleView.h"
#import "APHLocalization.h"

@interface APHMedTimingLegendView ()

@property (nonatomic) IBOutlet UILabel *afterMedicationLabel;
@property (nonatomic) IBOutlet UILabel *beforeMedicationLabel;
@property (nonatomic) IBOutlet UILabel *notSureLabel;
@property (nonatomic) IBOutlet APHCircleView *notSureCircleView;
@property (nonatomic) IBOutlet APHCircleView *beforeMedicationCircleView;
@property (nonatomic) IBOutlet APHCircleView *afterMedicationCircleView;
@property (nonatomic) IBOutlet APHCircleView *correlatedAfterMedicationCircleView;

@property (nonatomic) IBOutlet NSLayoutConstraint *correlatedAfterMedicationCircleViewWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *correlatedAfterMedicationCircleViewLeadingSpaceConstraint;

@property (nonatomic) CGFloat defaultCorrelatedCircleViewWidth;
@property (nonatomic) CGFloat defaultCorrelatedCircleViewLeadingSpace;

@end

@implementation APHMedTimingLegendView

+ (CGFloat)defaultHeight;
{
    return 84.f;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.notSureCircleView.tintColor = [UIColor colorWithRed:167.f / 255.f
                                                       green:169.f / 255.f
                                                        blue:172.f / 255.f
                                                       alpha:1.f];
}

- (void)updateLabels
{
    if (self.showExpandedView) {
        self.afterMedicationLabel.text = NSLocalizedStringWithDefaultValue(@"APH_AFTER_MEDICATION_SHORT", nil, APHLocaleBundle(), @"After med", @"");
        self.beforeMedicationLabel.text = NSLocalizedStringWithDefaultValue(@"APH_BEFORE_MEDICATION_SHORT", nil, APHLocaleBundle(), @"Before med", @"");
    } else {
        self.afterMedicationLabel.text = NSLocalizedStringWithDefaultValue(@"APH_AFTER_MEDICATION", nil, APHLocaleBundle(), @"After medication", @"");
        self.beforeMedicationLabel.text = NSLocalizedStringWithDefaultValue(@"APH_BEFORE_MEDICATION", nil, APHLocaleBundle(), @"Before medication", @"");
    }
    
    self.notSureLabel.text = NSLocalizedStringWithDefaultValue(@"APH_NOT_SURE", nil, APHLocaleBundle(), @"Not sure", @"");
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.showCorrelationLegend) {
        self.correlatedAfterMedicationCircleViewLeadingSpaceConstraint.constant = 2.f;
        self.correlatedAfterMedicationCircleViewWidthConstraint.constant = 16.f;
    } else {
        self.correlatedAfterMedicationCircleViewLeadingSpaceConstraint.constant = 0.f;
        self.correlatedAfterMedicationCircleViewWidthConstraint.constant = 0.f;
    }
}

#pragma mark - Accessors

- (void)setShowCorrelationLegend:(BOOL)showCorrelationLegend
{
    _showCorrelationLegend = showCorrelationLegend;
    
    [self setNeedsUpdateConstraints];
}

- (void)setShowExpandedView:(BOOL)showExpandedView
{
    _showExpandedView = showExpandedView;
    
    [self updateLabels];
}

- (void)setSecondaryTintColor:(UIColor *)secondaryTintColor
{
    _secondaryTintColor = secondaryTintColor;
    
    self.correlatedAfterMedicationCircleView.tintColor = secondaryTintColor;
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.afterMedicationCircleView.tintColor = tintColor;
}

@end
