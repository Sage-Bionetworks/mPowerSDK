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

@interface APCGraphViewController (Private)
@property (strong, nonatomic) APCSpinnerViewController *spinnerController;
- (void)reloadCharts;
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
        self.discreteGraphView.hidden = YES;
        self.lineGraphView.hidden = YES;
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
    [super reloadCharts];
    
    if (self.graphItem.graphType != (APCDashboardGraphType)kAPHDashboardGraphTypeScatter) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (weakSelf.spinnerController) {
            [weakSelf.spinnerController dismissViewControllerAnimated:YES completion:nil];
            weakSelf.spinnerController = nil;
        }
        
        [weakSelf.scatterGraphView layoutSubviews];
        [weakSelf.scatterGraphView refreshGraph];
        
        [weakSelf setSubTitleText];
    });
}

#pragma mark - IBActions

- (IBAction)correlationSegmentChanged:(UISegmentedControl *)sender {
    
}


@end
