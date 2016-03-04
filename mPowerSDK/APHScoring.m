//
//  APHScoring.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-28.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHScoring.h"
#import "APHLocalization.h"
#import "APHMedicationTrackerTask.h"

@interface APCScoring (Private)
@property (nonatomic) APHTimelineGroups groupBy;
@property (nonatomic) NSInteger numberOfDays;
@property (nonatomic, strong) APCScoring *correlatedScoring;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSMutableArray *dataPoints;
@property (nonatomic, strong) NSMutableArray *rawDataPoints;
@property (nonatomic) NSUInteger current;
- (NSDictionary *)generateDataPointForDate:(NSDate *)pointDate withValue:(NSNumber *)pointValue noDataValue:(BOOL)noDataValue;
- (NSDictionary *)groupByKeyPath:(NSString *)key dataset:(NSArray *)dataset;
- (NSInteger)numberOfDivisionsInXAxisForDiscreteGraph:(APCDiscreteGraphView *) graphView;
- (NSInteger)numberOfDivisionsInXAxisForLineGraph:(APCLineGraphView *) graphView;
- (NSInteger)numberOfDivisionsInXAxis;
- (NSInteger)numberOfPlotsInGraph;
- (NSInteger)numberOfPointsInPlot:(NSInteger)plotIndex;
- (NSString *)graph:(APCBaseGraphView *) graphView titleForXAxisAtIndex:(NSInteger)pointIndex;
@end

@interface APHScoring ()

@property(nonatomic) NSMutableDictionary *medTimingDataPoints;
@property(nonatomic) NSMutableDictionary *medTimingDataPointsCorrelatedScoring;
@property(nonatomic) NSArray *filteredDataPoints;

@end

@implementation APHScoring

#pragma mark - APCScoring Overrides

- (NSDictionary *)summarizeDataset:(NSDictionary *)dataset period:(APHTimelineGroups)period
{
    NSMutableDictionary *summarizedDataset = [NSMutableDictionary new];
    NSArray *keys = [dataset allKeys];
    
    for (id key in keys) {
        NSArray *elements = dataset[key];
        NSDictionary *rawData = nil;
        
        if (period == APHTimelineGroupForInsights) {
            // The elements array is sorted in ansending order,
            // therefore the last object will be the latest data point.
            NSDictionary *latestElement = [elements lastObject];
            rawData = latestElement[kDatasetRawDataKey];
        }
        
        // Exclude data points with NSNotFound
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K <> %@)", kDatasetValueKey, @(NSNotFound)];
        NSArray *filteredDataPoints = [elements filteredArrayUsingPredicate:predicate];
        
        double itemSum = 0;
        double dayAverage = 0;
        
        for (NSDictionary *dataPoint in filteredDataPoints) {
            NSNumber *value = [dataPoint valueForKey:kDatasetValueKey];
            
            if ([value integerValue] != NSNotFound) {
                itemSum += [value doubleValue];
            }
        }
        
        if (filteredDataPoints.count != 0) {
            dayAverage = itemSum / filteredDataPoints.count;
        }
        
        if (dayAverage == 0) {
            dayAverage = NSNotFound;
        }
        
        APCRangePoint *rangePoint = [APCRangePoint new];
        
        if (dayAverage != NSNotFound) {
            NSNumber *minValue = [filteredDataPoints valueForKeyPath:@"@min.datasetValueKey"];
            NSNumber *maxValue = [filteredDataPoints valueForKeyPath:@"@max.datasetValueKey"];
            
            rangePoint.minimumValue = [minValue floatValue];
            rangePoint.maximumValue = [maxValue floatValue];
        }
        
        NSMutableDictionary *entry = [[self generateDataPointForDate:key withValue:@(dayAverage) noDataValue:YES] mutableCopy];
        entry[kDatasetRangeValueKey] = rangePoint;
        entry[kDatasetRawDataPointsKey] = filteredDataPoints;
        
        if (rawData) {
            entry[kDatasetRawDataKey] = rawData;
        }
        
        summarizedDataset[key] = @[entry];
    }
    
    return summarizedDataset;
}

- (NSArray *)activityTimingChoicesStrings {
    if (nil == _activityTimingChoicesStrings) {
        _activityTimingChoicesStrings = [self medTrackerTaskChoices];
    }
    
    return _activityTimingChoicesStrings;
}

- (NSArray<NSString*> *)medTrackerTaskChoices {
	APHMedicationTrackerTask *task = [[APHMedicationTrackerTask alloc] init];
	NSArray<ORKTextChoice *> *activityTimingChoices = task.activityTimingChoices;
	NSMutableArray *activityTimingChoicesStrings = [[NSMutableArray alloc] init];
	for (ORKTextChoice *textChoice in activityTimingChoices) {
		[activityTimingChoicesStrings addObject:textChoice.text];
	}
	
	return [activityTimingChoicesStrings copy];
}

- (void)filterDataForMedicationTiming {
    self.medTimingDataPoints = [[NSMutableDictionary alloc] init];
    self.medTimingDataPointsCorrelatedScoring = [[NSMutableDictionary alloc] init];
    
	APHMedicationTrackerTask *task = [[APHMedicationTrackerTask alloc] init];
	NSArray<ORKTextChoice *> *activityTimingChoices = task.activityTimingChoices;
    
    if (!self.filteredDataPoints) {
        self.filteredDataPoints = [NSArray arrayWithArray:self.dataPoints.copy];
    }

	for (ORKTextChoice *textChoice in activityTimingChoices) {
		self.medTimingDataPoints[textChoice.text] = [[NSMutableArray alloc] init];
	}
    
    NSString *noMedicationTimingKey = self.activityTimingChoicesStrings.lastObject;

	for (NSDictionary *dataPoint in self.dataPoints) {
        NSArray *rawDataPoints = dataPoint[@"datasetRawDataPoints"];
        
        for (NSString *activityTimingChoiceString in self.activityTimingChoicesStrings) {
            NSMutableDictionary *filteredDataPoint = [dataPoint mutableCopy];
            
            NSPredicate *filterPredicate;
            if ([activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filterPredicate = [NSPredicate predicateWithFormat:@"(datasetTaskResult == nil) || (datasetTaskResult.MedicationActivityTiming == nil)"];
            } else {
                filterPredicate = [NSPredicate predicateWithFormat:@"(dataSetTaskResult.MedicationActivityTiming == '%@')", activityTimingChoiceString];
            }
            
            NSArray *filteredRawDataPoints = [rawDataPoints filteredArrayUsingPredicate:filterPredicate];
            filteredDataPoint[@"datasetRawDataPoints"] = filteredRawDataPoints;
            
            if (filteredRawDataPoints.count == 0) {
                filteredDataPoint[kDatasetValueKey] = @(NSNotFound);
            } else {
                NSNumber *averageRawDataPointValue = [[filteredRawDataPoints valueForKey:kDatasetValueKey] valueForKeyPath:@"@avg.intValue"];
                filteredDataPoint[kDatasetValueKey] = averageRawDataPointValue;
            }
            
            [self.medTimingDataPoints[activityTimingChoiceString] addObject:filteredDataPoint];
        }
	}
    
    if (!self.correlatedScoring) { return; }
    
    for (NSDictionary *dataPoint in self.correlatedScoring.dataPoints) {
        NSArray *rawDataPoints = dataPoint[@"datasetRawDataPoints"];
        
        for (NSString *activityTimingChoiceString in self.activityTimingChoicesStrings) {
            NSMutableDictionary *filteredDataPoint = [dataPoint mutableCopy];
            
            NSPredicate *filterPredicate;
            if ([activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filterPredicate = [NSPredicate predicateWithFormat:@"(datasetTaskResult == nil) || (datasetTaskResult.MedicationActivityTiming == nil)"];
            } else {
                filterPredicate = [NSPredicate predicateWithFormat:@"(dataSetTaskResult.MedicationActivityTiming == '%@')", activityTimingChoiceString];
            }
            
            NSArray *filteredRawDataPoints = [rawDataPoints filteredArrayUsingPredicate:filterPredicate];
            filteredDataPoint[@"datasetRawDataPoints"] = filteredRawDataPoints;
            
            if (filteredRawDataPoints.count == 0) {
                filteredDataPoint[kDatasetValueKey] = @(NSNotFound);
            } else {
                NSNumber *averageRawDataPointValue = [[filteredRawDataPoints valueForKey:kDatasetValueKey] valueForKeyPath:@"@avg.intValue"];
                filteredDataPoint[kDatasetValueKey] = averageRawDataPointValue;
            }
            
            [self.medTimingDataPointsCorrelatedScoring[activityTimingChoiceString] addObject:filteredDataPoint];
        }
    }
}

- (void)changeDataPointsWithTaskChoice:(NSString *)taskChoice
{
	[self updatePeriodForDays:self.numberOfDays groupBy:self.groupBy];
    
    self.dataPoints = self.medTimingDataPoints[taskChoice];
    
    if (self.correlatedScoring) {
        self.correlatedScoring.dataPoints = self.medTimingDataPointsCorrelatedScoring[taskChoice] ?: self.correlatedScoring.dataPoints;
    }
    
    [self correlateWithScoringObject:self.correlatedScoring];
}

- (void)updatePeriodForDays:(NSInteger)numberOfDays groupBy:(APHTimelineGroups)groupBy
{
    [super updatePeriodForDays:numberOfDays groupBy:groupBy];
    
    [self filterDataForMedicationTiming];
}


#pragma mark - APHSparkGraphViewDataSource

- (NSInteger)sparkGraph:(APHSparkGraphView *) __unused graphView numberOfPointsInPlot:(NSInteger)plotIndex
{
    NSString *key = self.activityTimingChoicesStrings[plotIndex];
    
    return [self.medTimingDataPoints[key] count];
}

- (NSInteger)numberOfPlotsInSparkGraph:(APHSparkGraphView *) __unused graphView
{
    return self.activityTimingChoicesStrings.count;
}

- (CGFloat)minimumValueForSparkGraph:(APHSparkGraphView *) __unused graphView
{
    CGFloat factor = 0.2;
    CGFloat maxDataPoint = (self.customMaximumPoint == CGFLOAT_MAX) ? [[self maximumDataPoint] doubleValue] : self.customMaximumPoint;
    CGFloat minDataPoint = (self.customMinimumPoint == CGFLOAT_MIN) ? [[self minimumDataPoint] doubleValue] : self.customMinimumPoint;
    
    CGFloat minValue = (minDataPoint - factor*maxDataPoint)/(1-factor);
    
    return minValue;
}

- (CGFloat)maximumValueForSparkGraph:(APHSparkGraphView *) __unused graphView
{
    return (self.customMaximumPoint == CGFLOAT_MAX) ? [[self maximumDataPoint] doubleValue] : self.customMaximumPoint;
}

- (NSDictionary *)sparkGraph:(APHSparkGraphView *) __unused graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger) pointIndex
{
    NSString *key = self.activityTimingChoicesStrings[plotIndex];
    
    return [self.medTimingDataPoints[key] objectAtIndex:pointIndex];
}

- (NSString *)sparkGraph:(APHSparkGraphView *) graphView titleForXAxisAtIndex:(NSInteger)pointIndex
{
    if (pointIndex == 0) {
        return [self graph:graphView titleForXAxisAtIndex:pointIndex];
    } else if (pointIndex == self.dataPoints.count - 1) {
        return NSLocalizedStringWithDefaultValue(@"Today", nil, APHLocaleBundle(), @"Today", @"Today");
    }
    
    return @"";
}

- (NSInteger)numberOfDivisionsInXAxisForSparkGraph:(APHSparkGraphView *)__unused graphView
{
    return [self numberOfDivisionsInXAxis];
}

- (NSString *)sparkGraph:(APHSparkGraphView *)graphView medTimingForPlot:(NSInteger)plotIndex
{
    return self.activityTimingChoicesStrings[plotIndex];
}

#pragma mark - APHScatterGraphViewDataSource

- (NSInteger)scatterGraph:(APHScatterGraphView *)graphView numberOfPointsInPlot:(NSInteger)plotIndex
{
    return self.dataPoints.count;
}

- (NSDictionary *)scatterGraph:(APHScatterGraphView *)graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger)pointIndex
{
    NSDictionary *dataPointValue = [NSDictionary new];
    
    if (plotIndex == 0) {
        dataPointValue = [self.dataPoints objectAtIndex:pointIndex];
    }
    
    return dataPointValue;
}

- (NSInteger)numberOfPlotsInScatterGraph:(APHScatterGraphView *)graphView
{
    return [self numberOfPlotsInGraph];
}

- (NSInteger)numberOfDivisionsInXAxisForGraph:(APHScatterGraphView *)graphView
{
    return [self numberOfDivisionsInXAxis];
}

- (NSString *)scatterGraph:(APHScatterGraphView *)graphView titleForXAxisAtIndex:(NSInteger)pointIndex
{
    NSDate *titleDate = nil;
    NSInteger numOfTitles = [self numberOfDivisionsInXAxisForGraph:graphView];
    
    NSInteger actualIndex = ((self.dataPoints.count - 1)/numOfTitles + 1) * pointIndex;
    
    titleDate = [[self.dataPoints objectAtIndex:actualIndex] valueForKey:kDatasetDateKey];
    
    switch (self.groupBy) {
            
        case APHTimelineGroupMonth:
        case APHTimelineGroupYear:
            [self.dateFormatter setDateFormat:@"MMM"];
            break;
            
        case APHTimelineGroupWeek:
        case APHTimelineGroupDay:
        default:
            if (actualIndex == 0) {
                [self.dateFormatter setDateFormat:@"MMM d"];
            } else {
                [self.dateFormatter setDateFormat:@"d"];
            }
            break;
    }
    
    NSString *xAxisTitle = [self.dateFormatter stringFromDate:titleDate] ? [self.dateFormatter stringFromDate:titleDate] : @"";
    
    return xAxisTitle;
}

- (CGFloat)minimumValueForScatterGraph:(APHScatterGraphView *)graphView
{
    CGFloat factor = 0.2;
    CGFloat maxDataPoint = (self.customMaximumPoint == CGFLOAT_MAX) ? [[self maximumDataPoint] doubleValue] : self.customMaximumPoint;
    CGFloat minDataPoint = (self.customMinimumPoint == CGFLOAT_MIN) ? [[self minimumDataPoint] doubleValue] : self.customMinimumPoint;
    
    CGFloat minValue = (minDataPoint - factor*maxDataPoint)/(1-factor);
    
    return minValue;
}

- (CGFloat)maximumValueForScatterGraph:(APHScatterGraphView *)graphView
{
    return (self.customMaximumPoint == CGFLOAT_MAX) ? [[self maximumDataPoint] doubleValue] : self.customMaximumPoint;
}


#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *) zone
{
    id copy = [super copyWithZone:zone];
    
    [copy setLatestOnly:self.latestOnly];
    [copy setActivityTimingChoicesStrings:self.activityTimingChoicesStrings.copy];
    
    return copy;
}


@end
