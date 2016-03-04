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
#import "APHDashboardGraphTableViewCell.h"
#import "APHDataKeys.h"
#import "APHLocalization.h"
#import "APHMedicationTrackerTask.h"
#import "APHMedicationTrackerViewController.h"
#import "APHSpatialSpanMemoryGameViewController.h"
#import "APHScatterGraphView.h"
#import "APHTableViewDashboardGraphItem.h"
#import "APHScoring.h"
#import "APHSparkGraphView.h"
//#import "APHTremorTaskViewController.h"
#import "APHWalkingTaskViewController.h"
#import "APHAppDelegate.h"
#import "APHCorrelationsSelectorViewController.h"
#import "APHGraphViewController.h"
#import "APHLineGraphView.h"

NSInteger const kNumberOfDaysToDisplayInSparkLineGraph = 30;
NSInteger const kPaddingMagicNumber = 80; // For the cell height to make the dashboard look pretty.

static NSString * const kAPCBasicTableViewCellIdentifier          = @"APCBasicTableViewCell";
static NSString * const kAPCRightDetailTableViewCellIdentifier    = @"APCRightDetailTableViewCell";
static NSString * const kAPHDashboardGraphTableViewCellIdentifier = @"APHDashboardGraphTableViewCell";

@interface APCDashboardViewController (Private) <UIGestureRecognizerDelegate>
@property (nonatomic, strong) APCPresentAnimator *presentAnimator;
@property (nonatomic, strong) NSMutableArray *lineCharts;
@end

@interface APHDashboardViewController ()<UIViewControllerTransitioningDelegate, APCCorrelationsSelectorDelegate, ORKTaskViewControllerDelegate, APHDashboardGraphTableViewCellDelegate, APHCorrelationsSelectorDelegate>

@property (nonatomic, strong) NSArray *rowItemsOrder;
@property (nonatomic, strong) NSMutableArray<APHScoring *> *correlatedScores; // Should have two!
@property (nonatomic, strong) NSArray<APHScoring *> *scoreArray;
@property (nonatomic, strong) NSMutableDictionary *sparkLineGraphScoring;

@property (nonatomic, strong) APHScoring *correlatedScoring;
@property (nonatomic, strong) APHScoring *tapRightScoring;
@property (nonatomic, strong) APHScoring *tapLeftScoring;
@property (nonatomic, strong) APHScoring *gaitScoring;
@property (nonatomic, strong) APHScoring *stepScoring;
@property (nonatomic, strong) APHScoring *memoryScoring;
@property (nonatomic, strong) APHScoring *phonationScoring;
@property (nonatomic, strong) APHScoring *moodScoring;
@property (nonatomic, strong) APHScoring *energyScoring;
@property (nonatomic, strong) APHScoring *exerciseScoring;
@property (nonatomic, strong) APHScoring *sleepScoring;
@property (nonatomic, strong) APHScoring *cognitiveScoring;
@property (nonatomic, strong) APHScoring *customScoring;

@property (nonatomic) NSInteger selectedCorrelationTimeTab;

@end

@implementation APHDashboardViewController

#pragma mark - Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _rowItemsOrder = [NSMutableArray arrayWithArray:[defaults objectForKey:kAPCDashboardRowItemsOrder]];
        
        if (!_rowItemsOrder.count) {
            _rowItemsOrder = [self allRowItems];
            
            [defaults setObject:[NSArray arrayWithArray:_rowItemsOrder] forKey:kAPCDashboardRowItemsOrder];
            [defaults synchronize];
        }
        
        self.selectedCorrelationTimeTab = 0;
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
    
    [self updateRowItemsOrder];
    
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

- (NSArray<APHScoring *> *)scoreArray
{
    if (nil == _scoreArray) {
        _scoreArray = @[self.tapRightScoring, self.tapLeftScoring, self.gaitScoring, self.stepScoring, self.memoryScoring, self.phonationScoring];
    }
    
    return _scoreArray;
}

// list of all the valid row items, in what will be the default order until the user rearranges them
- (NSArray<NSNumber *> *)allRowItems
{
    NSMutableArray<NSNumber *> *allRowItems =
    [@[
      @(kAPHDashboardItemTypeCorrelation),
      @(kAPHDashboardItemTypeSteps),
      @(kAPHDashboardItemTypeIntervalTappingRight),
      @(kAPHDashboardItemTypeIntervalTappingLeft),
      @(kAPHDashboardItemTypeSpatialMemory),
      @(kAPHDashboardItemTypePhonation),
      @(kAPHDashboardItemTypeGait),
      @(kAPHDashboardItemTypeDailyMood),
      @(kAPHDashboardItemTypeDailyEnergy),
      @(kAPHDashboardItemTypeDailyExercise),
      @(kAPHDashboardItemTypeDailySleep),
      @(kAPHDashboardItemTypeDailyCognitive)
      ] mutableCopy];
    
    APCAppDelegate *appDelegate = (APCAppDelegate *)[UIApplication sharedApplication].delegate;
    NSString *customSurveyQuestion = appDelegate.dataSubstrate.currentUser.customSurveyQuestion;
    if (customSurveyQuestion != nil && ![customSurveyQuestion isEqualToString:@""]) {
        [allRowItems addObject:@(kAPHDashboardItemTypeDailyCustom)];
    }
    
    return [allRowItems copy];
}

// Make sure self.rowItemsOrder contains all, and only, the available items
// (this is mostly important when a new release contains new dashboard items, and when the user adds or
// removes their custom daily survey question)
- (void)updateRowItemsOrder
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.rowItemsOrder = [defaults objectForKey:kAPCDashboardRowItemsOrder];
    NSMutableArray *itemsOrder = [self.rowItemsOrder mutableCopy];
    
    NSArray *allRowItems = [self allRowItems];
    NSMutableArray *newItems = [NSMutableArray array];
    for (NSNumber *item in allRowItems) {
        if (![itemsOrder containsObject:item]) {
            [newItems addObject:item];
        }
    }
    
    [itemsOrder addObjectsFromArray:newItems];
    
    NSMutableArray *oldItems = [NSMutableArray array];
    for (NSNumber *item in _rowItemsOrder) {
        if (![allRowItems containsObject:item]) {
            [oldItems addObject:item];
        }
    }
    
    [itemsOrder removeObjectsInArray:oldItems];
    
    // update locally and in user defaults only if it changed
    if (newItems.count || oldItems.count) {
        self.rowItemsOrder = [itemsOrder copy];
        [defaults setObject:self.rowItemsOrder forKey:kAPCDashboardRowItemsOrder];
        [defaults synchronize];
    }
}

- (void)prepareScoringObjects
{
    self.tapRightScoring = [[APHScoring alloc] initWithTask:APHTappingActivitySurveyIdentifier
                                               numberOfDays:-kNumberOfDaysToDisplay
                                                   valueKey:APHRightSummaryNumberOfRecordsKey
                                                 latestOnly:NO];
    self.tapRightScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_RIGHT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Right", @"Dashboard caption for results of right hand tapping activity.");

    self.tapLeftScoring = [[APHScoring alloc] initWithTask:APHTappingActivitySurveyIdentifier
                                              numberOfDays:-kNumberOfDaysToDisplay
                                                  valueKey:APHLeftSummaryNumberOfRecordsKey
                                                latestOnly:NO];
    self.tapLeftScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_LEFT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Left", @"Dashboard caption for results of left hand tapping activity.");
    
    self.gaitScoring = [[APHScoring alloc] initWithTask:APHWalkingActivitySurveyIdentifier
                                           numberOfDays:-kNumberOfDaysToDisplay
                                               valueKey:kGaitScoreKey
                                             latestOnly:NO];
    self.gaitScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_WALKING_CAPTION", nil, APHLocaleBundle(), @"Gait", @"Dashboard caption for results of walking activity.");

    self.memoryScoring = [[APHScoring alloc] initWithTask:APHMemoryActivitySurveyIdentifier
                                             numberOfDays:-kNumberOfDaysToDisplay
                                                 valueKey:kSpatialMemoryScoreSummaryKey
                                               latestOnly:NO];
    self.memoryScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_MEMORY_CAPTION", nil, APHLocaleBundle(), @"Memory", @"Dashboard caption for results of memory activity.");

    self.phonationScoring = [[APHScoring alloc] initWithTask:APHVoiceActivitySurveyIdentifier
                                                numberOfDays:-kNumberOfDaysToDisplay
                                                    valueKey:APHPhonationScoreSummaryOfRecordsKey
                                                  latestOnly:NO];
    self.phonationScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_VOICE_CAPTION", nil, APHLocaleBundle(), @"Voice", @"Dashboard caption for results of voice activity.");
    
    HKQuantityType *hkQuantity = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    self.stepScoring = [[APHScoring alloc] initWithHealthKitQuantityType:hkQuantity
                                                                    unit:[HKUnit countUnit]
                                                            numberOfDays:-kNumberOfDaysToDisplay];
    self.stepScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_STEPS_CAPTION", nil, APHLocaleBundle(), @"Steps", @"Dashboard caption for results of steps score.");
    
    self.moodScoring = [self scoringForValueKey:@"moodsurvey103"];
    self.moodScoring.customMinimumPoint = 1.0;
    self.moodScoring.customMaximumPoint = 5.0;
    self.moodScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_MOOD_CAPTION", nil, APHLocaleBundle(), @"Mood", @"Dashboard caption for daily mood report");
    
    self.energyScoring = [self scoringForValueKey:@"moodsurvey104"];
    self.energyScoring.customMinimumPoint = 1.0;
    self.energyScoring.customMaximumPoint = 5.0;
    self.energyScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_ENERGY_CAPTION", nil, APHLocaleBundle(), @"Energy Level", @"Dashboard caption for daily energy report");
    
    self.exerciseScoring = [self scoringForValueKey:@"moodsurvey106"];
    self.exerciseScoring.customMinimumPoint = 1.0;
    self.exerciseScoring.customMaximumPoint = 5.0;
    self.exerciseScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_EXERCISE_CAPTION", nil, APHLocaleBundle(), @"Exercise Level", @"Dashboard caption for daily exercise report");
    
    self.sleepScoring = [self scoringForValueKey:@"moodsurvey105"];
    self.sleepScoring.customMinimumPoint = 1.0;
    self.sleepScoring.customMaximumPoint = 5.0;
    self.sleepScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_SLEEP_CAPTION", nil, APHLocaleBundle(), @"Sleep Quality", @"Dashboard caption for daily sleep quality report");
    
    self.cognitiveScoring = [self scoringForValueKey:@"moodsurvey102"];
    self.cognitiveScoring.customMinimumPoint = 1.0;
    self.cognitiveScoring.customMaximumPoint = 5.0;
    self.cognitiveScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_THINKING_CAPTION", nil, APHLocaleBundle(), @"Thinking", @"Dashboard caption for daily mental clarity report");
    
    self.customScoring = [self scoringForValueKey:@"moodsurvey107"];
    self.customScoring.customMinimumPoint = 1.0;
    self.customScoring.customMaximumPoint = 5.0;
    self.customScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_CUSTOM_CAPTION", nil, APHLocaleBundle(), @"Custom Question", @"Dashboard caption for daily user-defined custom question report");

    if (!self.correlatedScores) {
        self.correlatedScores = [NSMutableArray arrayWithArray:@[self.scoreArray[0], self.scoreArray[1]]];
    }
    [self prepareCorrelatedScoring];
    [self prepareSparkLineScoring];
}

- (APHScoring *)scoringForValueKey:(NSString *)valueKey
{
    return [[APHScoring alloc] initWithTask:APHDailySurveyIdentifier
                               numberOfDays:-kNumberOfDaysToDisplay
                                   valueKey:valueKey
                                 latestOnly:NO];
}

- (void)prepareCorrelatedScoring
{
    self.correlatedScoring = nil;
    self.correlatedScoring = self.correlatedScores[0].copy;
    [self.correlatedScoring correlateWithScoringObject:self.correlatedScores[1].copy];
    
    //default series
    self.correlatedScoring.series1Name = self.correlatedScores[0].caption;
    self.correlatedScoring.series2Name = self.correlatedScores[1].caption;
    
    NSString *taskChoice = [self.correlatedScoring.activityTimingChoicesStrings objectAtIndex:self.selectedCorrelationTimeTab];
    [self.correlatedScoring changeDataPointsWithTaskChoice:taskChoice];
    
    // Commented out because it overwrites
//    self.correlatedScoring.caption = NSLocalizedStringWithDefaultValue(@"APH_DATA_CORRELATION_CAPTION", nil, APHLocaleBundle(), @"Data Correlation", @"Dashboard caption for data correlation.");
}

- (void)prepareSparkLineScoring
{
    NSArray *scoringObjects = @[ self.tapRightScoring,
                                 self.tapLeftScoring,
                                 self.gaitScoring,
                                 self.stepScoring,
                                 self.memoryScoring,
                                 self.phonationScoring,
                                 self.moodScoring,
                                 self.energyScoring,
                                 self.exerciseScoring,
                                 self.sleepScoring,
                                 self.cognitiveScoring,
                                 self.customScoring ];
    
    self.sparkLineGraphScoring = [[NSMutableDictionary alloc] initWithCapacity:scoringObjects.count];
    
    for (APHScoring *scoring in scoringObjects) {
        NSValue *key = [NSValue valueWithPointer:(const void *)scoring];
        APHScoring *value = [scoring copy];
        [value updatePeriodForDays:-kNumberOfDaysToDisplayInSparkLineGraph groupBy:APHTimelineGroupDay];
        self.sparkLineGraphScoring[key] = value;
    }
}

- (nullable APHScoring *)sparkLineScoringForScoring:(APCScoring *)scoring
{
    NSValue *key = [NSValue valueWithPointer:(const void *)scoring];
    return self.sparkLineGraphScoring[key];
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
                    
                case kAPHDashboardItemTypeCorrelation:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DATA_CORRELATION_CAPTION", nil, APHLocaleBundle(), @"Data Correlation", @"Dashboard caption for data correlation.");
                    item.graphData = self.correlatedScoring;
                    item.graphType = kAPCDashboardGraphTypeLine;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.showCorrelationSelectorView = YES;
                    item.showCorrelationSegmentControl = YES;
                    item.hideTintBar = YES;
                    item.tintColor = [UIColor appSecondaryColor2];
                    
                    NSString *infoFormat = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_CORRELATION_INFO", nil, APHLocaleBundle(), @"This chart plots the index of your %@ against the index of your %@. For more comparisons, click the series name.", @"Format of caption for correlation plot comparing indices of two series, to be filled in with the names of the series being compared.");
                    item.info = [NSString stringWithFormat:infoFormat, self.correlatedScoring.series1Name, self.self.correlatedScoring.series2Name];
                    item.detailText = @"";
                    item.legend = [APHTableViewDashboardGraphItem legendForSeries1:self.correlatedScoring.series1Name series2:self.correlatedScoring.series2Name];
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeIntervalTappingRight:
                case kAPHDashboardItemTypeIntervalTappingLeft:
                {
                    APHScoring *tapScoring = (rowType == kAPHDashboardItemTypeIntervalTappingRight) ? self.tapRightScoring : self.tapLeftScoring;
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = tapScoring.caption;
                    item.taskId = APHTappingActivitySurveyIdentifier;
                    item.graphData = tapScoring;
                    item.graphType = kAPHDashboardGraphTypeScatter;
                    
                    double avgValue = [[tapScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([tapScoring minimumDataPoint]), APHLocalizedStringFromNumber([tapScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
					item.showMedicationLegend = YES;
                    item.showSparkLineGraph = YES;
                
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_TAPPING_INFO", nil, APHLocaleBundle(), @"This plot shows your finger tapping speed each day as measured by the Tapping Interval Activity. The length and position of each vertical bar represents the range in the number of taps you made in 20 seconds for a given day. Any differences in length or position over time reflect variations and trends in your tapping speed, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Tapping in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];

                }
                    break;
                case kAPHDashboardItemTypeGait:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.gaitScoring.caption;
                    item.taskId = APHWalkingActivitySurveyIdentifier;
                    item.graphData = self.gaitScoring;
                    item.graphType = kAPHDashboardGraphTypeScatter;
                    
                    double avgValue = [[self.gaitScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.gaitScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.gaitScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    item.showMedicationLegend = YES;
                    item.showSparkLineGraph = YES;
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_WALKING_INFO", nil, APHLocaleBundle(), @"This plot combines several accelerometer-based measures for the Walking Activity. The length and position of each vertical bar represents the range of measures for a given day. Any differences in length or position over time reflect variations and trends in your Walking measure, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Gait in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                case kAPHDashboardItemTypeSpatialMemory:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.memoryScoring.caption;
                    item.taskId = APHMemoryActivitySurveyIdentifier;
                    item.graphData = self.memoryScoring;
                    item.graphType = kAPHDashboardGraphTypeScatter;
                    
                    double avgValue = [[self.memoryScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.memoryScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.memoryScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    item.showMedicationLegend = YES;
                    item.showSparkLineGraph = YES;
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_MEMORY_INFO", nil, APHLocaleBundle(), @"This plot shows the score you received each day for the Memory Game. The length and position of each vertical bar represents the range of scores for a given day. Any differences in length or position over time reflect variations and trends in your score, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Memory in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                case kAPHDashboardItemTypePhonation:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.phonationScoring.caption;
                    item.taskId = APHVoiceActivitySurveyIdentifier;
                    item.graphData = self.phonationScoring;
                    item.graphType = kAPHDashboardGraphTypeScatter;
                    
                    double avgValue = [[self.phonationScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailMinMaxFormat,
                                           APHLocalizedStringFromNumber([self.phonationScoring minimumDataPoint]), APHLocalizedStringFromNumber([self.phonationScoring maximumDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    item.showMedicationLegend = YES;
                    item.showSparkLineGraph = YES;
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_VOICE_INFO", nil, APHLocaleBundle(), @"This plot combines several microphone-based measures as a single score for the Voice Activity. The length and position of each vertical bar represents the range of measures for a given day. Any differences in length or position over time reflect variations and trends in your Voice measure, which may reflect variations and trends in your symptoms.", @"Dashboard tooltip item info text for Voice in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeSteps:
                {
                    APHTableViewDashboardGraphItem  *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.stepScoring.caption;
                    item.graphData = self.stepScoring;
                    
                    double avgValue = [[self.stepScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailAvgFormat,
                                           APHLocalizedStringFromNumber([self.stepScoring averageDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_STEPS_INFO", nil, APHLocaleBundle(), @"This graph shows how many steps you took each day, according to your phone's motion sensors. Remember that for this number to be accurate, you should have the phone on you as frequently as possible.", @"Dashboard tooltip item info text for Steps in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                /*
                case kAPHDashboardItemTypeTremor:
                {
                    APHTableViewDashboardGraphItem  *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.tremorScoring.caption;
                    item.graphData = self.tremorScoring;
                    
                    double avgValue = [[self.tremorScoring averageDataPoint] doubleValue];
                    
                    if (avgValue > 0) {
                        item.detailText = [NSString stringWithFormat:detailAvgFormat,
                                           APHLocalizedStringFromNumber([self.tremorScoring averageDataPoint])];
                    }
                    
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor colorForTaskId:APHTremorActivitySurveyIdentifier];
                    item.showMedicationLegend = YES;
                    item.showSparkLineGraph = YES;
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_TREMOR_INFO", nil, APHLocaleBundle(), @"This plot shows the score you received each day for the Tremor Test.", @"Dashboard tooltip item info text for Tremor Test in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyMood:{
                    
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.moodScoring.caption;
                    item.graphData = self.moodScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveyMood-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveyMood-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *scoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.moodScoring averageDataPoint] doubleValue] > 0 && scoringObjects.count > 1) {
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveyMood-%0.0fg", (double) 6 - [[self.moodScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat: NSLocalizedString(@"Average : ", nil)];
                    }
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_MOOD_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the daily check-in questions for mood each day. ", @"Dashboard tooltip item info text for daily check-in Mood in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                 */
                    
                case kAPHDashboardItemTypeDailyEnergy:{
                    
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.energyScoring.caption;
                    item.graphData = self.energyScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveyEnergy-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveyEnergy-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *scoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.energyScoring averageDataPoint] doubleValue] > 0 && scoringObjects.count > 1) {
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveyEnergy-%0.0fg", (double) 6 - [[self.energyScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : ", nil)];
                    }
                    
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_ENERGY_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the daily check-in questions for energy each day.", @"Dashboard tooltip item info text for daily check-in Energy in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyExercise:{
                    
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.exerciseScoring.caption;
                    item.graphData = self.exerciseScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveyExercise-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveyExercise-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *scoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.exerciseScoring averageDataPoint] doubleValue] > 0 && scoringObjects.count > 1) {
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveyExercise-%0.0fg", (double) 6 - [[self.exerciseScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : ", nil)];
                    }
                    
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_EXERCISE_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the daily check-in questions for exercise each day.", @"Dashboard tooltip item info text for daily check-in Exercise in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeDailySleep:{
                    
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.sleepScoring.caption;
                    item.graphData = self.sleepScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveySleep-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveySleep-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *scoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.sleepScoring averageDataPoint] doubleValue] > 0 && scoringObjects.count > 1) {
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveySleep-%0.0fg", (double) 6 - [[self.sleepScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : ", nil)];
                    }
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_SLEEP_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the daily check-in questions for sleep each day.", @"Dashboard tooltip item info text for daily check-in Sleep in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyCognitive:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.cognitiveScoring.caption;
                    item.graphData = self.cognitiveScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryRedColor];
                    
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveyClarity-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveyClarity-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *moodScoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.cognitiveScoring averageDataPoint] doubleValue] > 0 && moodScoringObjects.count > 1) {
                        
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveyClarity-%0.0fg", (double) 6 - [[self.cognitiveScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : ", nil)];
                    }
                    
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_THINKING_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the daily check-in questions for your thinking each day.", @"Dashboard tooltip item info text for daily check-in Thinking (mental clarity) in Parkinson");
                    
                    APCTableViewRow *row = [APCTableViewRow new];
                    row.item = item;
                    row.itemType = rowType;
                    [rowItems addObject:row];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyCustom:
                {
                    APHTableViewDashboardGraphItem *item = [APHTableViewDashboardGraphItem new];
                    item.caption = self.customScoring.caption;
                    item.graphData = self.customScoring;
                    item.graphType = kAPCDashboardGraphTypeDiscrete;
                    item.reuseIdentifier = kAPHDashboardGraphTableViewCellIdentifier;
                    item.editable = YES;
                    item.tintColor = [UIColor appTertiaryBlueColor];
                    item.minimumImage = [UIImage imageNamed:@"MoodSurveyCustom-5g"];
                    item.maximumImage = [UIImage imageNamed:@"MoodSurveyCustom-1g"];
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
                    NSArray *scoringObjects = [[self.moodScoring allObjects] filteredArrayUsingPredicate:predicate];
                    
                    if ([[self.customScoring averageDataPoint] doubleValue] > 0 && scoringObjects.count > 1) {
                        item.averageImage = [UIImage imageNamed:[NSString stringWithFormat:@"MoodSurveyCustom-%0.0fg", (double) 6 - [[self.customScoring averageDataPoint] doubleValue]]];
                        item.detailText = [NSString stringWithFormat:NSLocalizedString(@"Average : ", @"Average: ")];
                    }
                    
                    item.info = NSLocalizedStringWithDefaultValue(@"APH_DASHBOARD_DAILY_CUSTOM_INFO", nil, APHLocaleBundle(), @"This graph shows your answers to the custom question that you created as part of your daily check-in questions.", @"Dashboard tooltip item info text for daily check-in Custom in Parkinson");
                    
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


#pragma mark - APCDashboardTableViewCellDelegate

- (void)dashboardTableViewCellDidTapLegendTitle:(APCDashboardTableViewCell *)__unused cell
{
    APCCorrelationsSelectorViewController *correlationSelector = [[APCCorrelationsSelectorViewController alloc]initWithScoringObjects:@[self.tapRightScoring, self.tapLeftScoring, self.gaitScoring, self.stepScoring, self.memoryScoring, self.phonationScoring]];
    correlationSelector.delegate = self;
    [self.navigationController pushViewController:correlationSelector animated:YES];
}

- (void)dashboardTableViewCellDidTapExpand:(APCDashboardTableViewCell *)cell
{
    if ([cell isKindOfClass:[APHDashboardGraphTableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        APHTableViewDashboardGraphItem *graphItem = (APHTableViewDashboardGraphItem *)[self itemForIndexPath:indexPath];
        APHDashboardGraphTableViewCell *graphCell = (APHDashboardGraphTableViewCell *)cell;
        
        if ((APHDashboardGraphType)graphItem.graphType == kAPHDashboardGraphTypeScatter) {
            graphItem.graphType = kAPHDashboardGraphTypeDiscrete;
            ((APHScoring *)graphItem.graphData).latestOnly = YES;
        }
        
        CGRect initialFrame = [cell convertRect:cell.bounds toView:self.view.window];
        self.presentAnimator.initialFrame = initialFrame;
        
        APHGraphViewController *graphViewController = [[UIStoryboard storyboardWithName:@"APHDashboard" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:@"APHLineGraphViewController"];
        
        if (graphCell.showCorrelationSelectorView
                && (APHDashboardGraphType)graphItem.graphType == kAPHDashboardGraphTypeLine) {
            [((APHScoring *)graphItem.graphData) resetChanges];
            
            graphViewController.selectedCorrelationTimeTab = self.selectedCorrelationTimeTab;
            graphViewController.isForCorrelation = YES;
            graphViewController.shouldHideAverageLabel = YES;
            graphViewController.shouldHideCorrelationSegmentControl = YES;
        } else {
            graphViewController.shouldHideCorrelationSegmentControl = YES;
        }
        
        graphViewController.graphItem = graphItem;
        graphItem.graphData.scoringDelegate = graphViewController;
        [self.navigationController presentViewController:graphViewController animated:YES completion:nil];
    }
}

#pragma mark - APHDashboardGraphTableViewCellDelegate

- (void)dashboardTableViewCellDidTapCorrelation1:(APCDashboardTableViewCell *)cell
{
    APHCorrelationsSelectorViewController *correlationSelector = [[APHCorrelationsSelectorViewController alloc]initWithScoringObjects:self.scoreArray];
    [correlationSelector setTitle:@"Correlation 1"];
    correlationSelector.isForButton1 = YES;
    correlationSelector.delegate = self;
    correlationSelector.selectedObject = self.correlatedScores[0];
    correlationSelector.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.tabBarController presentViewController:correlationSelector animated:NO completion:nil];
}

- (void)dashboardTableViewCellDidTapCorrelation2:(APCDashboardTableViewCell *)cell
{
    APHCorrelationsSelectorViewController *correlationSelector = [[APHCorrelationsSelectorViewController alloc]initWithScoringObjects:self.scoreArray];
    [correlationSelector setTitle:@"Correlation 2"];
    correlationSelector.isForButton1 = NO;
    correlationSelector.delegate = self;
    correlationSelector.selectedObject = self.correlatedScores[1];
    correlationSelector.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self.tabBarController presentViewController:correlationSelector animated:NO completion:nil];
}

- (void)dashboardTableViewCellDidChangeCorrelationSegment:(NSInteger)selectedIndex
{
    self.selectedCorrelationTimeTab = selectedIndex;
    [self prepareCorrelatedScoring];
    [self prepareData];
}

#pragma mark - APHCorrelationsSelector Delegate

- (void)didChangeCorrelatedScoringDataSourceForButton1:(APHScoring*)scoring
{
    self.correlatedScores[0] = scoring;
    [self prepareCorrelatedScoring];
    [self prepareData];
}

- (void)didChangeCorrelatedScoringDataSourceForButton2:(APHScoring*)scoring
{
    self.correlatedScores[1] = scoring;
    [self prepareCorrelatedScoring];
    [self prepareData];
}

#pragma mark - CorrelationsSelector Delegate

- (void)viewController:(APCCorrelationsSelectorViewController *)__unused viewController didChangeCorrelatedScoringDataSource:(APHScoring *)scoring
{
    self.correlatedScoring = scoring;
    [self prepareData];
}

#pragma mark - ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error
{
    [self prepareData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGraphItem class]]) {
        
        APHTableViewDashboardGraphItem *graphItem = (APHTableViewDashboardGraphItem *)dashboardItem;
        APHDashboardGraphTableViewCell *graphCell = (APHDashboardGraphTableViewCell *)cell;
        
        [graphCell.legendButton setAttributedTitle:graphItem.legend forState:UIControlStateNormal];
        graphCell.showMedicationLegend = graphItem.showMedicationLegend;
        graphCell.showSparkLineGraph = graphItem.showSparkLineGraph;
        graphCell.showCorrelationSelectorView = graphItem.showCorrelationSelectorView;
        graphCell.showCorrelationSegmentControl = graphItem.showCorrelationSegmentControl;
        graphCell.hideTintBar = graphItem.hideTintBar;
        
        graphCell.button1Title = self.correlatedScoring.series1Name;
        graphCell.button2Title = self.correlatedScoring.series2Name;
        graphCell.correlationButton1TitleColor = [UIColor appTertiaryRedColor];
        graphCell.correlationButton2TitleColor = [UIColor appTertiaryYellowColor];
        graphCell.correlationDelegate = self;
        
        APHScatterGraphView *scatterGraphView = graphCell.scatterGraphView;
        scatterGraphView.dataSource = (APHScoring *)graphItem.graphData;
        
        APHSparkGraphView *sparkLineGraphView = graphCell.sparkLineGraphView;
        sparkLineGraphView.datasource = [self sparkLineScoringForScoring:graphItem.graphData];
        
        sparkLineGraphView.delegate = self;
        sparkLineGraphView.tintColor = graphItem.tintColor;
        sparkLineGraphView.secondaryTintColor = [UIColor appTertiaryGrayColor];
        sparkLineGraphView.axisColor = [UIColor appTertiaryGrayColor];
        sparkLineGraphView.axisTitleFont = [UIFont appRegularFontWithSize:14.0f];
        sparkLineGraphView.hidesYAxis = YES;
        sparkLineGraphView.hidesDataPoints = YES;
        sparkLineGraphView.shouldDrawShapePointKey = YES;
        sparkLineGraphView.shouldHighlightXaxisLastTitle = NO;
        sparkLineGraphView.maximumValueImage = graphItem.maximumImage;
        sparkLineGraphView.minimumValueImage = graphItem.minimumImage;
        [sparkLineGraphView layoutSubviews];
        
        if (sparkLineGraphView != nil) {
            [self.lineCharts addObject:sparkLineGraphView];
        }
        
        if (graphCell.showCorrelationSelectorView && (APHDashboardGraphType)graphItem.graphType == kAPHDashboardGraphTypeLine) {
            ((APHLineGraphView *)graphCell.lineGraphView).shouldDrawLastPoint = YES;
            ((APHLineGraphView *)graphCell.lineGraphView).colorForFirstCorrelationLine = graphCell.correlationButton1TitleColor;
            ((APHLineGraphView *)graphCell.lineGraphView).colorForSecondCorrelationLine = graphCell.correlationButton2TitleColor;
            graphCell.lineGraphView.hidesDataPoints = YES;
        } else {
            ((APHLineGraphView *)graphCell.lineGraphView).shouldDrawLastPoint = NO;
            graphCell.lineGraphView.hidesDataPoints = NO;
        }
        
        if ((APHDashboardGraphType)graphItem.graphType == kAPHDashboardGraphTypeScatter) {
            graphCell.discreteGraphView.hidden = YES;
            graphCell.lineGraphView.hidden = YES;
            graphCell.scatterGraphView.hidden = NO;
            graphCell.subTitleLabel.hidden = YES;
            
            [graphCell.legendButton setUserInteractionEnabled:graphItem.legend ? YES : NO];
            
            scatterGraphView.delegate = self;
            scatterGraphView.tintColor = graphItem.tintColor;
            scatterGraphView.axisColor = [UIColor appTertiaryGrayColor];
            scatterGraphView.showsVerticalReferenceLines = YES;
            scatterGraphView.panGestureRecognizer.delegate = self;
            scatterGraphView.axisTitleFont = [UIFont appRegularFontWithSize:14.0f];
            scatterGraphView.showsHorizontalReferenceLines = NO;
            
            scatterGraphView.maximumValueImage = graphItem.maximumImage;
            scatterGraphView.minimumValueImage = graphItem.minimumImage;
            
            graphCell.averageImageView.image = graphItem.averageImage;
            graphCell.title = graphItem.caption;
            graphCell.subTitleLabel.text = graphItem.detailText;
            
            graphCell.tintColor = graphItem.tintColor;
            graphCell.delegate = self;
            
            [scatterGraphView layoutSubviews];
            
            if (scatterGraphView != nil) {
                [self.lineCharts addObject:scatterGraphView];
            }
        } else {
            graphCell.scatterGraphView.hidden = YES;
            graphCell.subTitleLabel.hidden = NO;
        }
        
        for (UIView *tintView in graphCell.tintViews) {
            tintView.tintColor = graphItem.tintColor;
        }
    }

	((APCDashboardTableViewCell *)cell).titleLabel.textColor = [UIColor blackColor];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGraphItem class]]) {
        APHTableViewDashboardGraphItem *graphItem = (APHTableViewDashboardGraphItem *)dashboardItem;
        CGFloat rowHeight = [super tableView:tableView heightForRowAtIndexPath:indexPath];
        
        if (graphItem.showMedicationLegend) {
            rowHeight += [APHDashboardGraphTableViewCell medicationLegendContainerHeight];
        }
        
        if (graphItem.showSparkLineGraph) {
            rowHeight += [APHDashboardGraphTableViewCell sparkLineGraphContainerHeight];
        }
        
        if (graphItem.showCorrelationSegmentControl) {
            rowHeight += [APHDashboardGraphTableViewCell correlationSelectorHeight];
        }
        
        rowHeight += kPaddingMagicNumber;
        
        return rowHeight;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)__unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    APCTableViewItem *dashboardItem = [self itemForIndexPath:indexPath];
    
    if ([dashboardItem isKindOfClass:[APHTableViewDashboardGraphItem class]]){
        APCTableViewDashboardGraphItem *graphItem = (APCTableViewDashboardGraphItem *)dashboardItem;
        APHDashboardGraphTableViewCell *graphCell = (APHDashboardGraphTableViewCell *)cell;
        
        APHSparkGraphView *sparkLineGraphView = graphCell.sparkLineGraphView;
        [sparkLineGraphView setNeedsLayout];
        [sparkLineGraphView layoutIfNeeded];
        [sparkLineGraphView refreshGraph];
        
        APCBaseGraphView *graphView;
        if (graphItem.graphType == (APCDashboardGraphType)kAPHDashboardGraphTypeScatter) {
            graphView = (APHScatterGraphView *)graphCell.scatterGraphView;
            
            [graphView setNeedsLayout];
            [graphView layoutIfNeeded];
            [graphView refreshGraph];
        } else {
            [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
        }
    } else {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

@end
