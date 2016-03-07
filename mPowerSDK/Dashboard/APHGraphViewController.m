//
//  APHGraphViewController.m
//  mPowerSDK
//
//  Created by Andy Yeung on 3/3/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHGraphViewController.h"
#import "APHLineGraphView.h"
#import "APHScoring.h"
#import "APHTableViewDashboardGraphItem.h"
#import "APHRegularShapeView.h"

@interface APCGraphViewController (Private)
@property (strong, nonatomic) APCSpinnerViewController *spinnerController;
- (void)reloadCharts;
- (void)segmentControlChanged:(UISegmentedControl *)sender;
- (void)setSubTitleText;
@end

@interface APHGraphViewController ()

@end

@implementation APHGraphViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    APCBaseGraphView *graphView;
    if (self.graphItem.graphType == (APCDashboardGraphType)kAPHDashboardGraphTypeScatter) {
        graphView = self.scatterGraphView;
        self.scatterGraphView.dataSource = (APHScoring *)self.graphItem.graphData;
        
        self.scatterGraphView.showsVerticalReferenceLines = YES;
        self.scatterGraphView.showsHorizontalReferenceLines = NO;

        for (APHRegularShapeView *shapeView in self.keyShapeViewsArray) {
            shapeView.tintColor = self.graphItem.tintColor;
        }
        
        self.discreteGraphView.hidden = YES;
        self.lineGraphView.hidden = YES;
    } else {
        self.scatterGraphView.hidden = YES;
        self.medicationLegendContainerView.hidden = YES;
    }
    
    if (self.graphItem.graphType == kAPCDashboardGraphTypeDiscrete) {
        APHDiscreteGraphView *discreteGraph = (APHDiscreteGraphView *)self.discreteGraphView;
        discreteGraph.showsHorizontalReferenceLines = NO;
        discreteGraph.primaryLineColor = [UIColor colorWithRed:236.f / 255.f
                                                         green:237.f / 255.f
                                                          blue:237.f / 255.f
                                                         alpha:1.f];
    }
    
    graphView.tintColor = self.graphItem.tintColor;
    graphView.landscapeMode = YES;
    
    graphView.minimumValueImage = self.graphItem.minimumImage;
    graphView.maximumValueImage = self.graphItem.maximumImage;
    
    [self updateViews];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.graphItem.graphType == (APCDashboardGraphType)kAPHDashboardGraphTypeScatter) {
        [self.scatterGraphView refreshGraph];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initilization Functions

- (void)updateViews
{
    self.subTitleLabel.hidden = self.shouldHideAverageLabel;
    self.correlationSegmentControl.hidden = self.shouldHideCorrelationSegmentControl;
    self.segmentedControl.hidden = !self.shouldHideCorrelationSegmentControl;
    
    if (!self.shouldHideCorrelationSegmentControl) {
        [self.correlationSegmentControl setSelectedSegmentIndex:self.selectedCorrelationTimeTab];
    }
    
    if ([self.lineGraphView isKindOfClass:[APHLineGraphView class]]
            && self.isForCorrelation) {
        ((APHLineGraphView *)self.lineGraphView).shouldDrawLastPoint = YES;
        ((APHLineGraphView *)self.lineGraphView).colorForFirstCorrelationLine = [UIColor appTertiaryRedColor];
        ((APHLineGraphView *)self.lineGraphView).colorForSecondCorrelationLine = [UIColor appTertiaryYellowColor];
        
        self.lineGraphView.hidesDataPoints = YES;
    }
}

#pragma mark - APCGraphViewController Overrides

- (void)reloadCharts
{
    if (self.graphItem.graphType != (APCDashboardGraphType)kAPHDashboardGraphTypeScatter) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf.scatterGraphView layoutSubviews];
        [weakSelf.scatterGraphView refreshGraph];
        
        [weakSelf setSubTitleText];
    });
    
    [super reloadCharts];
}

- (void)segmentControlChanged:(UISegmentedControl *)sender
{
    APHScoring *graphScoring = (APHScoring *)self.graphItem.graphData;
    graphScoring.providesExpandedScatterPlotData = sender.selectedSegmentIndex > 1;
    
    [super segmentControlChanged:sender];
}

#pragma mark - IBActions

- (IBAction)correlationSegmentChanged:(UISegmentedControl *)sender {
    
}


@end
