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
- (NSNumber *)minimumDataPointInSeries:(NSArray *)series;
- (NSNumber *)maximumDataPointInSeries:(NSArray *)series;
- (NSInteger)numberOfDivisionsInXAxisForDiscreteGraph:(APCDiscreteGraphView *) graphView;
- (NSInteger)numberOfDivisionsInXAxisForLineGraph:(APCLineGraphView *) graphView;
- (NSInteger)numberOfDivisionsInXAxis;
- (NSInteger)numberOfPlotsInGraph;
- (NSInteger)numberOfPointsInPlot:(NSInteger)plotIndex;
- (NSString *)graph:(APCBaseGraphView *) graphView titleForXAxisAtIndex:(NSInteger)pointIndex;
- (void)discardIncongruentArrayElements;
@end

@interface APHScoring ()

@property(nonatomic) NSMutableDictionary *medTimingDataPoints;
@property(nonatomic) NSMutableDictionary *medTimingDataPointsCorrelatedScoring;
@property(nonatomic) NSArray *averagedDataPoints;
@property(nonatomic) NSArray *correlatedAverageDataPoints;
@property(nonatomic) NSArray *filteredDataPoints;

@end

@implementation APHScoring

#pragma mark - APCScoring Overrides

- (void)correlateDataSources{
    //move dataPoints into correlateDataPoints
    if (self.shouldDiscardIncongruentCorrelationElements) {
        [self discardIncongruentArrayElements];
    }
    
    //index the arrays
    [self indexDataSeries:self.dataPoints];
    [self indexDataSeries:self.correlatedScoring.dataPoints];
}

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

- (NSArray<NSString *> *)medMomentInDayTaskChoices {
    APHMedicationTrackerTask *task = [[APHMedicationTrackerTask alloc] init];
	NSArray<ORKTextChoice *> *activityMomentInDayChoices = task.activityMomentInDayChoices;
	NSMutableArray *activityMomentInDayChoicesStrings = [[NSMutableArray alloc] init];
	for (ORKTextChoice *textChoice in activityMomentInDayChoices) {
		[activityMomentInDayChoicesStrings addObject:textChoice.text];
	}

	return [activityMomentInDayChoicesStrings copy];
}

- (void)filterDataForMedicationTiming {
    self.medTimingDataPoints = [[NSMutableDictionary alloc] init];
    self.medTimingDataPointsCorrelatedScoring = [[NSMutableDictionary alloc] init];
    
	self.activityTimingChoicesStrings = [self medMomentInDayTaskChoices];
    
    if (!self.filteredDataPoints) {
        self.filteredDataPoints = [NSArray arrayWithArray:self.dataPoints.copy];
    }

	for (NSString *activityTimingChoice in self.activityTimingChoicesStrings) {
		self.medTimingDataPoints[activityTimingChoice] = [[NSMutableArray alloc] init];
	}
    
    NSString *noMedicationTimingKey = self.activityTimingChoicesStrings.lastObject;
    
    NSArray *dataPoints = [self.dataPoints copy];
	for (NSDictionary *dataPoint in dataPoints) {
        NSArray *rawDataPoints = dataPoint[kDatasetRawDataPointsKey];
        
        for (NSString *activityTimingChoiceString in self.activityTimingChoicesStrings) {
            NSMutableDictionary *filteredDataPoint = [dataPoint mutableCopy];
            
            NSPredicate *filterPredicate;
            if ([activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filterPredicate = [NSPredicate predicateWithFormat:@"(%K == nil) || (%K == nil) || (%K == %@)",
                                   @"datasetTaskResult",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   noMedicationTimingKey];
            } else {
                filterPredicate = [NSPredicate predicateWithFormat:@"(%K == %@)",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   activityTimingChoiceString];
            }
            
            NSArray *filteredRawDataPoints = [rawDataPoints filteredArrayUsingPredicate:filterPredicate];
            filteredDataPoint[@"datasetRawDataPoints"] = filteredRawDataPoints;
            
            if (filteredRawDataPoints.count == 0 && ![activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filteredDataPoint[kDatasetValueKey] = @(NSNotFound);
            } else if (filteredRawDataPoints.count > 0) {
                NSArray *filteredRawDataPointValues = [filteredRawDataPoints valueForKey:kDatasetValueKey];
                NSNumber *averageValue = [filteredRawDataPointValues valueForKeyPath:@"@avg.intValue"];
                filteredDataPoint[kDatasetValueKey] = averageValue;
            }
            
            [self.medTimingDataPoints[activityTimingChoiceString] addObject:filteredDataPoint];
        }
	}
    
    NSMutableArray *averagedDataPoints = [NSMutableArray new];
    for (NSDictionary *dataPoint in dataPoints) {
        CGFloat dataPointValue = [dataPoint[kDatasetValueKey] floatValue];
        NSMutableDictionary *copiedDataPoint = [dataPoint mutableCopy];
        
        NSMutableArray *newRawDataPoints = [NSMutableArray new];
        for (NSString *medTimingChoiceString in self.activityTimingChoicesStrings) {
            NSArray *points = self.medTimingDataPoints[medTimingChoiceString];
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"%K == %@",
                                            @"datasetDateKey",
                                            dataPoint[kDatasetDateKey]];
            NSDictionary *point = [points filteredArrayUsingPredicate:filterPredicate].firstObject;
            
            if (!point) {
                continue;
            }
            
            NSMutableDictionary *pointCopy = [point mutableCopy];
            [pointCopy removeObjectForKey:kDatasetRawDataPointsKey];
            pointCopy[kDatasetTaskResultKey] = @{ @"MedicationMomentInDay": medTimingChoiceString };
            [newRawDataPoints addObject:pointCopy];
        }
        
        copiedDataPoint[kDatasetRawDataPointsKey] = newRawDataPoints;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %@", kDatasetValueKey, @(NSNotFound)];
        NSArray *filteredRawDataPoints = [newRawDataPoints filteredArrayUsingPredicate:predicate];
        
        if (filteredRawDataPoints.count > 0) {
            NSArray *filteredRawDataPointValues = [filteredRawDataPoints valueForKey:kDatasetValueKey];
            NSNumber *minValue = [filteredRawDataPointValues valueForKeyPath:@"@min.intValue"];
            NSNumber *maxValue = [filteredRawDataPointValues valueForKeyPath:@"@max.intValue"];
            APCRangePoint *newRangePoint = [[APCRangePoint alloc] initWithMinimumValue:minValue.floatValue maximumValue:maxValue.floatValue];
            copiedDataPoint[kDatasetRangeValueKey] = newRangePoint;
        } else if (dataPointValue != NSNotFound) {
            APCRangePoint *newRangePoint = [[APCRangePoint alloc] initWithMinimumValue:dataPointValue maximumValue:dataPointValue];
            copiedDataPoint[kDatasetRangeValueKey] = newRangePoint;
        }
        
        [averagedDataPoints addObject:copiedDataPoint];
    }
    
    self.averagedDataPoints = [averagedDataPoints copy];
    
    if (!self.correlatedScoring) {
        [self filterDataForCorrelatedScoring];
    }
}

- (void)filterDataForCorrelatedScoring {
    NSString *noMedicationTimingKey = self.activityTimingChoicesStrings.lastObject;
    
    NSArray *correlatedDataPoints = [self.correlatedScoring.dataPoints copy];
    for (NSDictionary *dataPoint in correlatedDataPoints) {
        NSArray *rawDataPoints = dataPoint[@"datasetRawDataPoints"];
        
        for (NSString *activityTimingChoiceString in self.activityTimingChoicesStrings) {
            NSMutableDictionary *filteredDataPoint = [dataPoint mutableCopy];
            
            NSPredicate *filterPredicate;
            if ([activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filterPredicate = [NSPredicate predicateWithFormat:@"(%K == nil) || (%K == nil) || (%K == %@)",
                                   @"datasetTaskResult",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   noMedicationTimingKey];
            } else {
                filterPredicate = [NSPredicate predicateWithFormat:@"(%K == %@)",
                                   @"datasetTaskResult.MedicationMomentInDay",
                                   activityTimingChoiceString];
            }
            
            NSArray *filteredRawDataPoints = [rawDataPoints filteredArrayUsingPredicate:filterPredicate];
            filteredDataPoint[kDatasetRawDataPointsKey] = filteredRawDataPoints;
            
            if (filteredRawDataPoints.count == 0 && ![activityTimingChoiceString isEqualToString:noMedicationTimingKey]) {
                filteredDataPoint[kDatasetValueKey] = @(NSNotFound);
            } else if (filteredRawDataPoints.count > 0) {
                NSNumber *averageRawDataPointValue = [[filteredRawDataPoints valueForKey:kDatasetValueKey] valueForKeyPath:@"@avg.intValue"];
                filteredDataPoint[kDatasetValueKey] = averageRawDataPointValue;
            }
            
            [self.medTimingDataPointsCorrelatedScoring[activityTimingChoiceString] addObject:filteredDataPoint];
        }
    }
    
    NSMutableArray *correlatedAverageDataPoints = [NSMutableArray new];
    for (NSDictionary *dataPoint in correlatedDataPoints) {
        CGFloat dataPointValue = [dataPoint[kDatasetValueKey] floatValue];
        NSMutableDictionary *copiedDataPoint = [dataPoint mutableCopy];
        
        NSMutableArray *newRawDataPoints = [NSMutableArray new];
        for (NSString *medTimingChoiceString in self.activityTimingChoicesStrings) {
            NSArray *points = self.medTimingDataPointsCorrelatedScoring[medTimingChoiceString];
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"%K == %@",
                                            @"datasetDateKey",
                                            dataPoint[kDatasetDateKey]];
            NSDictionary *point = [points filteredArrayUsingPredicate:filterPredicate].firstObject;
            
            if (!point) {
                continue;
            }
            
            NSMutableDictionary *pointCopy = [point mutableCopy];
            [pointCopy removeObjectForKey:kDatasetRawDataPointsKey];
            pointCopy[kDatasetTaskResultKey] = @{ @"MedicationMomentInDay": medTimingChoiceString };
            [newRawDataPoints addObject:pointCopy];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != %@", kDatasetValueKey, @(NSNotFound)];
        NSArray *filteredRawDataPoints = [newRawDataPoints filteredArrayUsingPredicate:predicate];
        
        if (filteredRawDataPoints.count > 0) {
            NSArray *filteredRawDataPointValues = [filteredRawDataPoints valueForKey:kDatasetValueKey];
            NSNumber *minValue = [filteredRawDataPointValues valueForKeyPath:@"@min.intValue"];
            NSNumber *maxValue = [filteredRawDataPointValues valueForKeyPath:@"@max.intValue"];
            APCRangePoint *newRangePoint = [[APCRangePoint alloc] initWithMinimumValue:minValue.floatValue maximumValue:maxValue.floatValue];
            copiedDataPoint[kDatasetRangeValueKey] = newRangePoint;
        } else if (dataPointValue != NSNotFound) {
            APCRangePoint *newRangePoint = [[APCRangePoint alloc] initWithMinimumValue:dataPointValue maximumValue:dataPointValue];
            copiedDataPoint[kDatasetRangeValueKey] = newRangePoint;
        }
        
        copiedDataPoint[kDatasetRawDataPointsKey] = newRawDataPoints;
        [correlatedAverageDataPoints addObject:copiedDataPoint];
    }
    
    self.correlatedAverageDataPoints = [correlatedAverageDataPoints copy];
}

- (void)changeDataPointsWithTaskChoice:(NSString *)taskChoice
{
	[self updatePeriodForDays:self.numberOfDays groupBy:self.groupBy];
    
    if (taskChoice) {
        self.dataPoints = self.medTimingDataPoints[taskChoice];
        
        if (self.correlatedScoring) {
            self.correlatedScoring.dataPoints = self.medTimingDataPointsCorrelatedScoring[taskChoice] ?: self.correlatedScoring.dataPoints;
        }
    }
    
    [self correlateWithScoringObject:self.correlatedScoring];
}

- (void)updatePeriodForDays:(NSInteger)numberOfDays groupBy:(APHTimelineGroups)groupBy
{
    [super updatePeriodForDays:numberOfDays groupBy:groupBy];
    
    [self filterDataForMedicationTiming];
}

- (void)resetChanges
{
    [self updatePeriodForDays:self.numberOfDays groupBy:self.groupBy];
}

- (void)indexDataSeries:(NSMutableArray *)series
{
    
}


- (NSArray<NSNumber *> *)minimumCorrelatedDataPoints {
	NSNumber *minDataPoint = [self minimumDataPointInSeries:self.dataPoints];
	NSNumber *minCorrelatedDataPoint = [self minimumDataPointInSeries:self.correlatedScoring.dataPoints];

	return @[minDataPoint, minCorrelatedDataPoint];
}


- (NSArray<NSNumber *> *)maximumCorrelatedDataPoints {
	NSNumber *maxDataPoint = [self maximumDataPointInSeries:self.dataPoints];
	NSNumber *maxCorrelatedDataPoint = [self maximumDataPointInSeries:self.correlatedScoring.dataPoints];

	return @[maxDataPoint, maxCorrelatedDataPoint];
}

#pragma mark - APHDiscreteGraphViewDataSource

- (NSDictionary *)discreteGraph:(APHDiscreteGraphView *)graphView plot:(NSInteger)plotIndex dictionaryValueForPointAtIndex:(NSInteger)pointIndex
{
    NSArray *dataPoints;
    
    if (plotIndex == 0) {
        dataPoints = self.providesAveragedPointData ? self.averagedDataPoints : self.dataPoints;
    } else {
        dataPoints = self.providesAveragedPointData ? self.correlatedAverageDataPoints : self.correlatedScoring.dataPoints;
    }
    
    NSDictionary *dataPoint = [dataPoints objectAtIndex:pointIndex];
    
    return dataPoint;
}

- (NSArray<NSNumber *> *)minimumValuesForDiscreteGraph:(APCDiscreteGraphView *)graphView {
	CGFloat factor = 0.2;
	
	NSArray<NSNumber *> *minimumCorrelatedDataPoints = [self minimumCorrelatedDataPoints];
	NSArray<NSNumber *> *maximumCorrelatedDataPoints = [self maximumCorrelatedDataPoints];
	NSMutableArray<NSNumber *> *minimumValues = [[NSMutableArray alloc] init];

	for (int i = 0; i < minimumCorrelatedDataPoints.count; i++) {
		CGFloat minFloat = [minimumCorrelatedDataPoints[i] floatValue];
		CGFloat maxFloat = [maximumCorrelatedDataPoints[i] floatValue];
		CGFloat minValue = (minFloat - factor * maxFloat) / (1-factor);
		[minimumValues addObject:@(minValue)];
	}
	
	return [minimumValues copy];
}

- (NSArray<NSNumber *> *)maximumValuesForDiscreteGraph:(APCDiscreteGraphView *)graphView {
	return [self maximumCorrelatedDataPoints];
}

- (NSInteger)discreteGraph:(APCDiscreteGraphView *)graphView numberOfPointsInPlot:(NSInteger)plotIndex
{
    NSArray *dataPoints;
    
    if (plotIndex == 0) {
        dataPoints = self.providesAveragedPointData ? self.averagedDataPoints : self.dataPoints;
    } else {
        dataPoints = self.providesAveragedPointData ? self.correlatedAverageDataPoints : self.correlatedScoring.dataPoints;
    }
    
    return dataPoints.count;
}

#pragma mark - APHSparkGraphViewDataSource

- (NSInteger)sparkGraph:(APHSparkGraphView *) __unused graphView numberOfPointsInPlot:(NSInteger)plotIndex
{
    NSInteger plotCounter = 0;
    
    for (NSString *activityTimingChoice in self.activityTimingChoicesStrings) {
        NSArray *points = self.medTimingDataPoints[activityTimingChoice];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
        NSArray *filteredPoints = [points filteredArrayUsingPredicate:filterPredicate];
        
        if (filteredPoints.count == 0 || activityTimingChoice == self.activityTimingChoicesStrings.lastObject) {
            continue;
        }
        
        if (plotCounter == plotIndex && filteredPoints.count > 0) {
            return points.count;
        }
        
        plotCounter++;
    }
    
    return 0.f;
}

- (NSInteger)numberOfPlotsInSparkGraph:(APHSparkGraphView *) __unused graphView
{
    NSInteger numberOfPlots = 0;
    
    for (NSString *activityTimingChoice in self.activityTimingChoicesStrings) {
        NSArray *points = self.medTimingDataPoints[activityTimingChoice];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
        NSArray *filteredPoints = [points filteredArrayUsingPredicate:filterPredicate];
        
        if ([filteredPoints count] > 0 && activityTimingChoice != self.activityTimingChoicesStrings.lastObject) {
            numberOfPlots++;
        }
    }
    
    return numberOfPlots;
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
    NSDictionary *value = @{};
    NSInteger counter = 0;
    
    for (NSString *activityTimingChoice in self.activityTimingChoicesStrings) {
        NSArray *points = self.medTimingDataPoints[activityTimingChoice];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
        NSArray *filteredPoints = [points filteredArrayUsingPredicate:filterPredicate];
        
        if (filteredPoints.count == 0 || activityTimingChoice == self.activityTimingChoicesStrings.lastObject) {
            continue;
        }

        if (counter == plotIndex && points.count > 0) {
            value = points[pointIndex];
            break;
        }
        
        counter++;
    }
    
    return value;
}

- (NSString *)sparkGraph:(APHSparkGraphView *) graphView titleForXAxisAtIndex:(NSInteger)pointIndex
{
    if (pointIndex == 0) {
        return [self graph:graphView titleForXAxisAtIndex:pointIndex];
    } else if (pointIndex == self.dataPoints.count - 1) {
        return NSLocalizedStringWithDefaultValue(@"Today", nil, APHLocaleBundle(), @"Today", @"'Today' xAxis title for graph view");
    }
    
    return @"";
}

- (NSInteger)numberOfDivisionsInXAxisForSparkGraph:(APHSparkGraphView *)__unused graphView
{
    return [self numberOfDivisionsInXAxis];
}

- (NSString *)sparkGraph:(APHSparkGraphView *)graphView medTimingForPlot:(NSInteger)plotIndex
{
    NSInteger counter = 0;
    
    for (NSString *activityTimingChoice in self.activityTimingChoicesStrings) {
        NSArray *points = self.medTimingDataPoints[activityTimingChoice];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"datasetValueKey != %@", @(NSNotFound)];
        NSArray *filteredPoints = [points filteredArrayUsingPredicate:filterPredicate];
        
        if (filteredPoints.count == 0 || activityTimingChoice == self.activityTimingChoicesStrings.lastObject) {
            continue;
        }
        
        if (counter == plotIndex && filteredPoints.count > 0) {
            return activityTimingChoice;
        }
        
        counter++;
    }
    
    return nil;
}

#pragma mark - APHScatterGraphViewDataSource

- (NSInteger)scatterGraph:(APHScatterGraphView *)graphView numberOfPointsInPlot:(NSInteger)plotIndex
{
    NSArray *dataPoints = self.providesAveragedPointData ? self.averagedDataPoints : self.dataPoints;
    return dataPoints.count;
}

- (NSDictionary *)scatterGraph:(APHScatterGraphView *)graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger)pointIndex
{
    NSArray *dataPoints = self.providesAveragedPointData ? self.averagedDataPoints : self.dataPoints;
    NSDictionary *dataPointValue = [NSDictionary new];
    
    if (plotIndex == 0) {
        dataPointValue = [dataPoints objectAtIndex:pointIndex];
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
    NSArray *dataPoints = self.providesAveragedPointData ? self.averagedDataPoints : self.dataPoints;
    NSDate *titleDate = nil;
    NSInteger numOfTitles = [self numberOfDivisionsInXAxisForGraph:graphView];
    
    NSInteger actualIndex = ((dataPoints.count - 1)/numOfTitles + 1) * pointIndex;
    
    titleDate = [[dataPoints objectAtIndex:actualIndex] valueForKey:kDatasetDateKey];
    
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
    
    [copy setActivityTimingChoicesStrings:self.activityTimingChoicesStrings.copy];
    [copy setMedTimingDataPoints:[self.medTimingDataPoints mutableCopy]];
    [copy setMedTimingDataPointsCorrelatedScoring:[self.medTimingDataPointsCorrelatedScoring mutableCopy]];
    [copy setFilteredDataPoints:[self.filteredDataPoints copy]];
    
    return copy;
}


@end
