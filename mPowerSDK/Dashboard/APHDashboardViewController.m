// 
//  APHDashboardViewController.m 
//  mPower 
// 
// Copyright (c) 2015, Sage Bionetworks. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
/* Controllers */
#import "APHDashboardViewController.h"
#import "APHDashboardEditViewController.h"
#import "APHDataKeys.h"
#import "APHLocalization.h"
#import "APHSpatialSpanMemoryGameViewController.h"
#import "APHWalkingTaskViewController.h"


static NSString * const kAPCBasicTableViewCellIdentifier       = @"APCBasicTableViewCell";
static NSString * const kAPCRightDetailTableViewCellIdentifier = @"APCRightDetailTableViewCell";

@interface APHDashboardViewController ()<UIViewControllerTransitioningDelegate, APCCorrelationsSelectorDelegate>

@property (nonatomic, strong) NSMutableArray *rowItemsOrder;

@property (nonatomic, strong) APCScoring *tapRightScoring;
@property (nonatomic, strong) APCScoring *tapLeftScoring;
@property (nonatomic, strong) APCScoring *gaitScoring;
@property (nonatomic, strong) APCScoring *stepScoring;
@property (nonatomic, strong) APCScoring *memoryScoring;
@property (nonatomic, strong) APCScoring *phonationScoring;

@end

@implementation APHDashboardViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
        
        if (!_rowItemsOrder.count) {
            _rowItemsOrder = [[NSMutableArray alloc] initWithArray:@[
                                                                     @(kAPHDashboardItemTypeCorrelation),
                                                                     @(kAPHDashboardItemTypeSteps),
                                                                     @(kAPHDashboardItemTypeIntervalTappingRight),
                                                                     @(kAPHDashboardItemTypeIntervalTappingLeft),
                                                                     @(kAPHDashboardItemTypeSpatialMemory),@(kAPHDashboardItemTypePhonation),]];
                              
            if ([APCDeviceHardware isiPhone5SOrNewer]) {
                [_rowItemsOrder addObject:@(kAPHDashboardItemTypeGait)];
            }
            [defaults setObject:[NSArray arrayWithArray:_rowItemsOrder] forKey:kAPCDashboardRowItemsOrder];
            [defaults synchronize];
            
        }
        
        self.title = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_TITLE", nil, APHLocaleBundle(), @"Dashboard", @"Title for the Dashboard view controller.");
    }
    
    return self;
}

#pragma mark - LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareCorrelatedScoring) name:APCSchedulerUpdatedScheduledTasksNotification object:nil];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self prepareScoringObjects];
    [self prepareData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
    
    [self prepareScoringObjects];
    [self prepareData];
}

- (void)updateVisibleRowsInTableView:(NSNotification *) __unused notification
{
    [self prepareData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Data

- (void)prepareScoringObjects
{
    self.tapRightScoring = [[APCScoring alloc] initWithTask:APHTappingActivitySurveyIdentifier
                                          numberOfDays:-kNumberOfDaysToDisplay
                                              valueKey:APHRightSummaryNumberOfRecordsKey];
    self.tapRightScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_RIGHT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Right", @"Dashboard caption for results of right hand tapping activity.");

    self.tapLeftScoring = [[APCScoring alloc] initWithTask:APHTappingActivitySurveyIdentifier
                                          numberOfDays:-kNumberOfDaysToDisplay
                                              valueKey:APHLeftSummaryNumberOfRecordsKey];
    self.tapLeftScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_LEFT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Left", @"Dashboard caption for results of left hand tapping activity.");
    
    self.gaitScoring = [[APCScoring alloc] initWithTask:APHWalkingActivitySurveyIdentifier
                                           numberOfDays:-kNumberOfDaysToDisplay
                                               valueKey:kGaitScoreKey];
    self.gaitScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_WALKING_CAPTION", nil, APHLocaleBundle(), @"Gait", @"Dashboard caption for results of walking activity.");
    

    self.memoryScoring = [[APCScoring alloc] initWithTask:APHMemoryActivitySurveyIdentifier
                                           numberOfDays:-kNumberOfDaysToDisplay
                                               valueKey:kSpatialMemoryScoreSummaryKey
                                               latestOnly:NO];
    self.memoryScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_MEMORY_CAPTION", nil, APHLocaleBundle(), @"Memory", @"Dashboard caption for results of memory activity.");

    self.phonationScoring = [[APCScoring alloc] initWithTask:APHVoiceActivitySurveyIdentifier
                                             numberOfDays:-kNumberOfDaysToDisplay
                                                 valueKey:APHPhonationScoreSummaryOfRecordsKey];
    self.phonationScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_VOICE_CAPTION", nil, APHLocaleBundle(), @"Voice", @"Dashboard caption for results of voice activity.");
    
    HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    self.stepScoring = [[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                    unit:[HKUnit countUnit]
                                                            numberOfDays:-kNumberOfDaysToDisplay];
    self.stepScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_STEPS_CAPTION", nil, APHLocaleBundle(), @"Steps", @"Dashboard caption for results of steps score.");
    
    if (!self.correlatedScoring) {
        [self prepareCorrelatedScoring];
    }
}

- (void)prepareCorrelatedScoring{

    self.correlatedScoring = [[APCScoring alloc] initWithTask:APHWalkingActivitySurveyIdentifier
                                                 numberOfDays:-kNumberOfDaysToDisplay
                                                     valueKey:kGaitScoreKey];
    
    HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [self.correlatedScoring correlateWithScoringObject:[[APCScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                                                    unit:[HKUnit countUnit]
                                                                                            numberOfDays:-kNumberOfDaysToDisplay]];
    
    self.correlatedScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DATA_CORRELATION_CAPTION", nil, APHLocaleBundle(), @"Data Correlation", @"Dashboard caption for data correlation.");
    
    //default series
    self.correlatedScoring.series1Name = self.gaitScoring.caption;
    self.correlatedScoring.series2Name = self.stepScoring.caption;
}

- (void)prepareData
{
    [self.items removeAllObjects];
    
    {
        NSMutableArray *rowItems = [NSMutableArray new];
        
        NSUInteger allScheduledTasks = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.countOfTotalRequiredTasksForToday;
        NSUInteger completedScheduledTasks = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.countOfTotalCompletedTasksForToday;
        
        {
            APCTableViewDashboardProgressItem *item = [APCTableViewDashboardProgressItem new];
            item.reuseIdentifier = kAPCDashboardProgressTableViewCellIdentifier;
            item.editable = NO;
            item.progress = (CGFloat)completedScheduledTasks/allScheduledTasks;
            item.caption = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_COMPLETION_CAPTION", nil, APHLocaleBundle(), @"Activity Completion", @"Dashboard caption for the activities completed.");

            item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_ACTIVITY_COMPLETION_INFO", nil, APHLocaleBundle(), @"This graph shows the percent of Today's activities that you completed. You can complete more of your tasks in the Activities tab.", @"Dashboard tooltip item info text for Activity Completion in Parkinson");
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = item;
            row.itemType = kAPCTableViewDashboardItemTypeProgress;
            [rowItems addObject:row];
        }
        
        NSString *detailMinMaxFormat = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_MINMAX_DETAIL", nil, APHLocaleBundle(), @"Min: %@  Max: %@", @"Format of detail text showing participant's minimum and maximum scores on relevant activity, to be filled in with their minimum and maximum scores");
        NSString *detailAvgFormat = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_AVG_DETAIL", nil, APHLocaleBundle(), @"Average: %@", @"Format of detail text showing participant's average score on relevant activity, to be filled in with their average score");
        
        for (NSNumber *typeNumber in self.rowItemsOrder) {
            
            APHDashboardItemType rowType = typeNumber.integerValue;
            
            switch (rowType) {
                    
                case kAPHDashboardItemTypeCorrelation:{
                    
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DATA_CORRELATION_CAPTION", nil, APHLocaleBundle(), @"Data Correlation", @"Dashboard caption for data correlation.");
                    item.graphData = self.correlatedScoring;
                    item.graphType = kAPCDashboardGraphTypeLine;
                    item.reuseIdentifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    NSString *infoFormat = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_CORRELATION_INFO", nil, APHLocaleBundle(), @"This chart plots the index of your %@ against the index of your %@. For more comparisons, click the series name.", @"Format of caption for correlation plot comparing indices of two series, to be filled in with the names of the series being compared.");
                    item.info = [NSString stringWithFormat:infoFormat, self.correlatedScoring.series1Name, self.correlatedScoring.series2Name];
                    item.detailText = @"";
                    item.legend = [APCTableViewDashboardGraphItem legendForSeries1:self.correlatedScoring.series1Name series2:self.correlatedScoring.series2Name];
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeIntervalTappingRight:
                case kAPHDashboardItemTypeIntervalTappingLeft:
                {
                    APCScoring *tapScoring = (rowType == kAPHDashboardItemTypeIntervalTappingRight) ? self.tapRightScoring : self.tapLeftScoring;
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = tapScoring.caption;
                    item.taskId = APHTappingActivitySurveyIdentifier;
                    item.graphData = tapScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    
                    double avgValue = [[tapScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([tapScoring minimumDataPoint]), APHLocalizedStringFromNumber([tapScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier =  kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_TAPPING_INFO", nil, APHLocaleBundle(), @"This plot shows your finger tapping speed each day as measured by the Tapping Interval Activity. The length and position of each vertical bar represents the range in the number of taps you made in 20 seconds for a given day. Any differences in length or position over time reflect variations and trends in your tapping speed, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Tapping in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];

                }
                    break;
                case kAPHDashboardItemTypeGait:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = self.gaitScoring.caption;
                    item.taskId = APHWalkingActivitySurveyIdentifier;
                    item.graphData = self.gaitScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    
                    double avgValue = [[self.gaitScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.gaitScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.gaitScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_WALKING_INFO", nil, APHLocaleBundle(), @"This plot combines several accelerometer-based measures for the Walking Activity. The length and position of each vertical bar represents the range of measures for a given day. Any differences in length or position over time reflect variations and trends in your Walking measure, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Gait in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                case kAPHDashboardItemTypeSpatialMemory:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = self.memoryScoring.caption;
                    item.taskId = APHMemoryActivitySurveyIdentifier;
                    item.graphData = self.memoryScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    
                    double avgValue = [[self.memoryScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.memoryScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.memoryScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_MEMORY_INFO", nil, APHLocaleBundle(), @"This plot shows the score you received each day for the Memory Game. The length and position of each vertical bar represents the range of scores for a given day. Any differences in length or position over time reflect variations and trends in your score, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Memory in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                case kAPHDashboardItemTypePhonation:
                {
                    APCTableViewDashboardGraphItem *item = [APCTableViewDashboardGraphItem new];
                    item.caption = self.phonationScoring.caption;
                    item.taskId = APHVoiceActivitySurveyIdentifier;
                    item.graphData = self.phonationScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    
                    double avgValue = [[self.phonationScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.phonationScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.phonationScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_VOICE_INFO", nil, APHLocaleBundle(), @"This plot combines several microphone-based measures as a single score for the Voice Activity. The length and position of each vertical bar represents the range of measures for a given day. Any differences in length or position over time reflect variations and trends in your Voice measure, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Voice in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeSteps:
                {
                    APCTableViewDashboardGraphItem  *item = [APCTableViewDashboardGraphItem new];
                    item.caption = self.stepScoring.caption;
                    item.graphData = self.stepScoring;
                    
                    double avgValue = [[self.stepScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailAvgFormat,
                                           APHLocalizedStringFromNumber([self.stepScoring averageDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPCDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_STEPS_INFO", nil, APHLocaleBundle(), @"This graph shows how many steps you took each day, according to your phone's motion sensors. Remember that for this number to be accurate, you should have the phone on you as frequently as possible.", @"Dashboard tooltip item info text for Steps in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                default:
                    break;
            }
            
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.rows = [NSArray arrayWithArray:rowItems];
        section.sectionTitle = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_RECENT_ACTIVITY_TITLE", nil, APHLocaleBundle(), @"Recent Activity", @"Title for the recent activity section of the dashboard table.");
        [self.items addObject:section];
    }
    
    [self.tableView reloadData];
}

#pragma mark - CorrelationsSelector Delegate

- (void)dashboardTableViewCellDidTapLegendTitle:(APCDashboardTableViewCell *)__unused cell
{
    APCCorrelationsSelectorViewController *correlationSelector = [[APCCorrelationsSelectorViewController alloc]initWithScoringObjects:@[self.tapRightScoring, self.tapLeftScoring, self.gaitScoring, self.stepScoring, self.memoryScoring, self.phonationScoring]];
    correlationSelector.delegate = self;
    [self.navigationController pushViewController:correlationSelector animated:YES];
}

- (void)viewController:(APCCorrelationsSelectorViewController *)__unused viewController didChangeCorrelatedScoringDataSource:(APCScoring *)scoring
{
    self.correlatedScoring = scoring;
    [self prepareData];
}

@end
