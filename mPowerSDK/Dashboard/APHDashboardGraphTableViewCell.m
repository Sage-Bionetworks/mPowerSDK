//
//  APHDashboardGraphTableViewCell.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHDashboardGraphTableViewCell.h"

const CGFloat kMedicationLegendContainerHeight = 80.f;
const CGFloat kSparkLineGraphContainerHeight = 172.f;
const CGFloat kCorrelationSelectorHeight = 48.f;

@interface APHDashboardGraphTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *medicationLegendContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sparkLineGraphContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *correlationSelectorHeight;

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

+ (CGFloat)correlationSelectorHeight
{
    return kCorrelationSelectorHeight;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self giveImageViewDownCarrotImage:self.button1DownCarrot];
    [self giveImageViewDownCarrotImage:self.button2DownCarrot];
    
    [self updateSegmentColors];
}

#pragma mark - Helper Methods

- (void)giveImageViewDownCarrotImage:(UIImageView *)button
{
    [button setImage:[UIImage imageNamed:@"down_carrot"]];
    [button setTintColor:[UIColor lightGrayColor]];
}

// From: http://stackoverflow.com/questions/1196679/customizing-the-colors-of-a-uisegmentedcontrol
- (void) updateSegmentColors
{
    NSUInteger numSegments = [self.correlationSegmentControl.subviews count];
    
    // Reset segment's color
    for( int i = 0; i < numSegments; i++ ) {
        [[self.correlationSegmentControl.subviews objectAtIndex:i] setTintColor:nil];
        [[self.correlationSegmentControl.subviews objectAtIndex:i] setTintColor:[UIColor appTertiaryGrayColor]];
        
        UIView *segmentView = [self.correlationSegmentControl.subviews objectAtIndex:i];
        for (UIImageView *imageView in segmentView.subviews) {
            [imageView setTintColor:[UIColor appTertiaryGrayColor]];
        }
    }
    
    // Sort Segments from left to right
    NSArray *sortedViews = [self.correlationSegmentControl.subviews sortedArrayUsingFunction:compareViewsByOrigin context:NULL];
    
    // Set selected segment color
    NSInteger selectedIdx = self.correlationSegmentControl.selectedSegmentIndex;
    [[sortedViews objectAtIndex:selectedIdx] setTintColor:[UIColor appTertiaryBlueColor]];
    
    // Remove all original segments from the control
    for (id view in self.correlationSegmentControl.subviews) {
        [view removeFromSuperview];
    }
    
    // Append sorted and colored segments to the control
    for (id view in sortedViews) {
        [self.correlationSegmentControl addSubview:view];
    }
}


NSInteger static compareViewsByOrigin(id sp1, id sp2, void *context)
{
    float v1 = ((UIView *)sp1).frame.origin.x;
    float v2 = ((UIView *)sp2).frame.origin.x;
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

#pragma mark - Accessors

- (void)setButton1Title:(NSString *)button1Title
{
    _button1Title = button1Title;
    self.button1Label.text = button1Title;
}

- (void)setButton2Title:(NSString *)button2Title
{
    _button2Title = button2Title;
    self.button2Label.text = button2Title;
}

- (void)setCorrelationButton1TitleColor:(UIColor *)correlationButton1TitleColor
{
    _correlationButton1TitleColor = correlationButton1TitleColor;
    self.button1Label.textColor = correlationButton1TitleColor;
}

- (void)setCorrelationButton2TitleColor:(UIColor *)correlationButton2TitleColor
{
    _correlationButton2TitleColor = correlationButton2TitleColor;
    self.button2Label.textColor = correlationButton2TitleColor;
}

- (void)setHideTintBar:(BOOL)hideTintBar
{
    _hideTintBar = hideTintBar;
    self.tintView.hidden = hideTintBar;
}

- (void)setShowCorrelationSelectorView:(BOOL)showCorrelationSelectorView
{
    _showCorrelationSelectorView = showCorrelationSelectorView;
    self.correlationSelectorView.hidden = !showCorrelationSelectorView;
    self.legendButton.userInteractionEnabled = !showCorrelationSelectorView;
}

- (void)setShowCorrelationSegmentControl:(BOOL)showCorrelationSegmentControl
{
    _showCorrelationSegmentControl = showCorrelationSegmentControl;
    self.correlationSelectorHeight.constant = showCorrelationSegmentControl ? [[self class] correlationSelectorHeight] : 0.f;
    self.correlationSegmentControlView.hidden = !showCorrelationSegmentControl;
    [self setNeedsLayout];
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

- (IBAction)correlationButton1Pressed:(UIButton *)sender
{
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation1:self];
}

- (IBAction)correlationButton2Pressed:(UIButton *)sender
{
    [self.correlationDelegate dashboardTableViewCellDidTapCorrelation2:self];
}

- (IBAction)correlationSegmentChanged:(UISegmentedControl *)sender
{
    [self updateSegmentColors];
    [self.correlationDelegate dashboardTableViewCellDidChangeCorrelationSegment:self.correlationSegmentControl.selectedSegmentIndex];
}


@end
