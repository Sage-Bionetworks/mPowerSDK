//
//  APHDiscreteGraphView.m
//  mPowerSDK
//
//  Created by Andy Yeung on 3/2/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHDiscreteGraphView.h"
#import "APHAxisView.h"
#import "APHMedicationTrackerTask.h"
#import "APHCircleView.h"

static CGFloat const kAPCGraphLeftPadding = 10.f;
static CGFloat const kYAxisPaddingFactor = 0.15f;
static CGFloat const kAxisMarkingRulerLength = 8.0f;
static CGFloat const kSnappingClosenessFactor = 0.3f;

@interface APCDiscreteGraphView (Private)
@property (nonatomic, strong) APCAxisView *xAxisView;
@property (nonatomic, strong) UIView *yAxisView;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *dataPoints;
@property (nonatomic, strong) NSMutableArray *dots;
@property (nonatomic, strong) NSMutableArray *pathLines;
@property (nonatomic, strong) NSMutableArray *xAxisPoints;
@property (nonatomic, strong) NSMutableArray *xAxisTitles;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *yAxisPoints;
@property (nonatomic, strong) UIView *plotsView;
@property (nonatomic) BOOL hasDataPoint;
@property (nonatomic) BOOL shouldAnimate;
@property (nonatomic, readwrite) CGFloat minimumValue;
@property (nonatomic, readwrite) CGFloat maximumValue;
@property (nonatomic) NSInteger numberOfXAxisTitles;
- (void)calculateXAxisPoints;
- (void)drawYAxis;
- (CGFloat)offsetForPlotIndex:(NSInteger)plotIndex;
- (void)setDefaults;
@end

@interface APHDiscreteGraphView()

@property (nonatomic, strong) UIView *secondaryYAxisView;
@property (nonatomic, readwrite) CGFloat secondaryMinimumValue;
@property (nonatomic, readwrite) CGFloat secondaryMaximumValue;

@end

@implementation APHDiscreteGraphView

@dynamic datasource, delegate;

#pragma mark - Accessors

- (UIColor *)primaryLineColor
{
    if (!_primaryLineColor) {
        _primaryLineColor = self.tintColor;
    }
    
    return _primaryLineColor;
}

- (UIColor *)secondaryLineColor
{
    if (!_secondaryLineColor) {
        if (self.primaryLineColor) {
            _secondaryLineColor = self.primaryLineColor;
        } else {
            _secondaryLineColor = self.secondaryTintColor;
        }
    }
    
    return _secondaryLineColor;
}


#pragma mark - APCDiscreteGraphView Overrides

- (void)calculateMinAndMaxPoints
{
	[self setDefaults];
	
	if (self.numberOfPlots > 1) {
		if ([self.datasource respondsToSelector:@selector(minimumValuesForDiscreteGraph:)]) {
			self.minimumValue = [[self.datasource minimumValuesForDiscreteGraph:self][1] floatValue];
			self.secondaryMinimumValue = [[self.datasource minimumValuesForDiscreteGraph:self][0] floatValue];
		}

		if ([self.datasource respondsToSelector:@selector(maximumValuesForDiscreteGraph:)]) {
			self.maximumValue = [[self.datasource maximumValuesForDiscreteGraph:self][1] floatValue];
			self.secondaryMaximumValue = [[self.datasource maximumValuesForDiscreteGraph:self][0] floatValue];
		}
	} else {
		//Min
		if ([self.datasource respondsToSelector:@selector(minimumValueForDiscreteGraph:)]) {
			self.minimumValue = [self.datasource minimumValueForDiscreteGraph:self];
		} else {

			if (self.dataPoints.count) {
				NSDictionary *firstDataPoint = self.dataPoints[0];
				APCRangePoint *rangePoint = [firstDataPoint valueForKey:kDatasetRangeValueKey];
				self.minimumValue = rangePoint.minimumValue;

				for (NSUInteger i=1; i<self.dataPoints.count; i++) {
					NSDictionary *dataPoint = self.dataPoints[i];
					CGFloat num = ((APCRangePoint *)[dataPoint valueForKey:kDatasetRangeValueKey]).minimumValue;
					if ((self.minimumValue == NSNotFound) || (num < self.minimumValue)) {
						self.minimumValue = num;
					}
				}
			}
		}

		//Max
		if ([self.datasource respondsToSelector:@selector(maximumValueForDiscreteGraph:)]) {
			self.maximumValue = [self.datasource maximumValueForDiscreteGraph:self];
		} else {
			if (self.dataPoints.count) {
				NSDictionary *firstDataPoint = self.dataPoints[0];
				APCRangePoint *rangePoint = [firstDataPoint valueForKey:kDatasetRangeValueKey];
				self.maximumValue = rangePoint.maximumValue;

				for (NSUInteger i=1; i<self.dataPoints.count; i++) {
					NSDictionary *dataPoint = self.dataPoints[i];
					CGFloat num = ((APCRangePoint *)[dataPoint valueForKey:kDatasetRangeValueKey]).maximumValue;
					if (((num != NSNotFound) && (num > self.maximumValue)) || (self.maximumValue == NSNotFound)) {
						self.maximumValue = num;
					}
				}
			}
		}
	}
}

- (void)drawLinesForPlotIndex:(NSInteger)plotIndex
{
    CGFloat positionOnXAxis = CGFLOAT_MAX;
    NSDictionary *positionOnYAxis = nil;
    UIColor *lineColor = (plotIndex == 0) ? self.primaryLineColor : self.secondaryLineColor;
    
    for (NSUInteger i=0; i<self.yAxisPoints.count; i++) {
        
        NSDictionary *dataPoint = self.dataPoints[i];
        CGFloat dataPointValue = [dataPoint[kDatasetValueKey] floatValue];
        NSArray *rawDataPoints = dataPoint[kDatasetRawDataPointsKey];
        
        if (dataPointValue != NSNotFound && (![[dataPoint valueForKey:kDatasetRangeValueKey] isRangeZero] || rawDataPoints.count > 0)) {
            
            UIBezierPath *plotLinePath = [UIBezierPath bezierPath];
            
            positionOnXAxis = [self.xAxisPoints[i] floatValue];
            positionOnXAxis += [self offsetForPlotIndex:plotIndex];
            
            positionOnYAxis = self.yAxisPoints[i];
            APCRangePoint *rangePoint = positionOnYAxis[kDatasetRangeValueKey];
            
            [plotLinePath moveToPoint:CGPointMake(positionOnXAxis, rangePoint.minimumValue)];
            
            [plotLinePath addLineToPoint:CGPointMake(positionOnXAxis, rangePoint.maximumValue)];
            
            CAShapeLayer *plotLineLayer = [CAShapeLayer layer];
            plotLineLayer.path = plotLinePath.CGPath;
            plotLineLayer.fillColor = [UIColor clearColor].CGColor;
            plotLineLayer.strokeColor = lineColor.CGColor;
            plotLineLayer.lineJoin = kCALineJoinRound;
            plotLineLayer.lineCap = kCALineCapRound;
            plotLineLayer.lineWidth = self.isLandscapeMode ? 12.0 : 10.0;
            plotLineLayer.opacity = 0.4;
            [self.plotsView.layer addSublayer:plotLineLayer];
            
            if (self.shouldAnimate) {
                plotLineLayer.strokeEnd = 0;
            }
            [self.pathLines addObject:plotLineLayer];
            
        }
    }
}

- (void)drawPointCirclesForPlotIndex:(NSInteger)plotIndex
{
    CGFloat pointSize = self.isLandscapeMode ? 8.f : 6.f;
    
    for (NSUInteger i=0 ; i<self.yAxisPoints.count; i++) {
        
        NSDictionary *dataPointVal = (NSDictionary *)self.dataPoints[i];
        
        if (dataPointVal.count == 0) {
            continue;
        }
        
        CGFloat positionOnXAxis = [self.xAxisPoints[i] floatValue];
        positionOnXAxis += [self offsetForPlotIndex:plotIndex];
        
        NSDictionary *positionOnYAxis = (NSDictionary *)self.yAxisPoints[i];
        NSArray *rawDataPoints = [positionOnYAxis valueForKey:kDatasetRawDataPointsKey];
        CGRect pointFrame = CGRectMake(0, 0, pointSize, pointSize);
        
        if (rawDataPoints.count == 0) {
            
            APHCircleView *point = [[APHCircleView alloc] initWithFrame:pointFrame];
            point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
            point.center = CGPointMake(positionOnXAxis, [[positionOnYAxis valueForKey:kDatasetValueKey] floatValue]);
            [self.plotsView.layer addSublayer:point.layer];
            
            if (self.shouldAnimate) {
                point.alpha = 0;
            }
            
            [self.dots addObject:point];
            continue;
        }
        
        for (NSDictionary *rawDataPoint in rawDataPoints) {
            NSString *medActivityMomentInDay = nil;
            
            NSDictionary *taskResult = [rawDataPoint valueForKey:kDatasetTaskResultKey];
            if (taskResult) {
                medActivityMomentInDay = taskResult[@"MedicationMomentInDay"];
            }
            
            APHCircleView *point = [[APHCircleView alloc] initWithFrame:pointFrame];
            
            APHMedicationTrackerTask *medTrackerTask = [[APHMedicationTrackerTask alloc] init];
            NSArray<NSString *> *momentInDayChoices = [medTrackerTask.activityMomentInDayChoices valueForKey:@"text"];
            
            switch ([momentInDayChoices indexOfObject:medActivityMomentInDay]) {
                // Before meds
                case 0:
                    point.tintColor = [UIColor colorWithRed:167.f / 255.f
                                                      green:169.f / 255.f
                                                       blue:172.f / 255.f
                                                      alpha:1.f];
                    break;
                
                // After meds
                case 1:
                    point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
                    break;
                    
                // Not sure
                case 2:
                    point.tintColor = [UIColor colorWithWhite:77.f / 255.f alpha:1.f];
                    break;
                    
                default:
                    point.tintColor = [UIColor colorWithRed:167.f / 255.f
                                                      green:169.f / 255.f
                                                       blue:172.f / 255.f
                                                      alpha:1.f];
                    break;
            }
            
            point.center = CGPointMake(positionOnXAxis, [[rawDataPoint valueForKey:kDatasetValueKey] floatValue]);
            [self.plotsView.layer addSublayer:point.layer];
            
            if (self.shouldAnimate) {
                point.alpha = 0;
            }
            
            [self.dots addObject:point];
        }
    }
}

- (void)drawXAxis
{
    //Add Title Labels
    [self.xAxisTitles removeAllObjects];
    
    for (int i=0; i<self.numberOfXAxisTitles; i++) {
        if ([self.datasource respondsToSelector:@selector(discreteGraph:titleForXAxisAtIndex:)]) {
            NSString *title = [self.datasource discreteGraph:self titleForXAxisAtIndex:i];
            
            [self.xAxisTitles addObject:title];
        }
    }
    
    if (self.xAxisView) {
        [self.xAxisView removeFromSuperview];
        self.xAxisView = nil;
    }
    
    self.axisColor = [UIColor appTertiaryGrayColor];
    
    APHAxisView *xAxisView = [[APHAxisView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.plotsView.frame), CGRectGetWidth(self.plotsView.frame), kXAxisHeight)];
    xAxisView.hasSecondaryYAxis = (BOOL *) (self.numberOfValidValues > 1);
    xAxisView.landscapeMode = self.landscapeMode;
    xAxisView.tintColor = self.axisColor;
    xAxisView.lastTitleHighlightColor = self.tintColor;
    xAxisView.shouldHighlightLastLabel = self.shouldHighlightXaxisLastTitle;
    [xAxisView setupLabels:self.xAxisTitles forAxisType:kAPCGraphAxisTypeX];
    xAxisView.leftOffset = kAPCGraphLeftPadding;
    
    self.xAxisView = xAxisView;
    [self insertSubview:self.xAxisView belowSubview:self.plotsView];
    
    UIBezierPath *xAxispath = [UIBezierPath bezierPath];
    [xAxispath moveToPoint:CGPointMake(0, 0)];
    [xAxispath addLineToPoint:CGPointMake(CGRectGetWidth(self.frame), 0)];
    
    CAShapeLayer *xAxisLineLayer = [CAShapeLayer layer];
    xAxisLineLayer.strokeColor = self.axisColor.CGColor;
    xAxisLineLayer.path = xAxispath.CGPath;
    [self.xAxisView.layer addSublayer:xAxisLineLayer];
    
    for (NSUInteger i=0; i<self.xAxisTitles.count; i++) {
        CGFloat positionOnXAxis;
        if (self.numberOfPlots > 1) {
            positionOnXAxis = kAPCGraphLeftPadding + (((CGRectGetWidth(self.plotsView.frame) - CGRectGetWidth(self.secondaryYAxisView.bounds))/ 
                (self.numberOfXAxisTitles - 1)) * i) + CGRectGetWidth(self.secondaryYAxisView.bounds);
        } else {
            positionOnXAxis = kAPCGraphLeftPadding + ((CGRectGetWidth(self.plotsView.frame) / (self.numberOfXAxisTitles - 1)) * i);
        }
        
        UIBezierPath *rulerPath = [UIBezierPath bezierPath];
        [rulerPath moveToPoint:CGPointMake(positionOnXAxis, - kAxisMarkingRulerLength)];
        [rulerPath addLineToPoint:CGPointMake(positionOnXAxis, 0)];
        
        CAShapeLayer *rulerLayer = [CAShapeLayer layer];
        rulerLayer.strokeColor = self.axisColor.CGColor;
        rulerLayer.path = rulerPath.CGPath;
        [self.xAxisView.layer addSublayer:rulerLayer];
    }
}

- (void)drawYAxis {
	if (self.hidesYAxis) {
		return;
	} else if (self.secondaryYAxisView) {
		[self.secondaryYAxisView removeFromSuperview];
		self.secondaryYAxisView = nil;
	}

	if (self.numberOfPlots > 1) {
		[self prepareDataForPlotIndex:0];

		if (self.yAxisView) {
			[self.yAxisView removeFromSuperview];
			self.yAxisView = nil;
		}

		CGFloat axisViewXPosition = CGRectGetWidth(self.frame) * (1 - kYAxisPaddingFactor);
		CGFloat axisViewWidth = CGRectGetWidth(self.frame)*kYAxisPaddingFactor;

		self.yAxisView = [[UIView alloc] initWithFrame:CGRectMake(axisViewXPosition, kAPCGraphTopPadding, axisViewWidth, CGRectGetHeight(self.plotsView.frame))];
		[self addSubview:self.yAxisView];


		CGFloat rulerXPosition = CGRectGetWidth(self.yAxisView.bounds) - kAxisMarkingRulerLength + 2;

		NSArray *yAxisLabelFactors;

		if (self.minimumValue == self.maximumValue) {
			yAxisLabelFactors = @[@0.5f];
		} else {
			yAxisLabelFactors = @[@0.2f,@1.0f];
		}

		for (NSUInteger i =0; i<yAxisLabelFactors.count; i++) {

			CGFloat factor = [yAxisLabelFactors[i] floatValue];
			CGFloat positionOnYAxis = CGRectGetHeight(self.plotsView.frame) * (1 - factor);

			UIBezierPath *rulerPath = [UIBezierPath bezierPath];
			[rulerPath moveToPoint:CGPointMake(rulerXPosition, positionOnYAxis)];
			[rulerPath addLineToPoint:CGPointMake(CGRectGetMaxX(self.yAxisView.bounds), positionOnYAxis)];

			CAShapeLayer *rulerLayer = [CAShapeLayer layer];
			rulerLayer.strokeColor = (self.secondaryTintColor ?: self.axisTitleColor).CGColor;
			rulerLayer.path = rulerPath.CGPath;
			[self.yAxisView.layer addSublayer:rulerLayer];

			CGFloat labelHeight = 20;
			CGFloat labelYPosition = positionOnYAxis - labelHeight/2;

			CGFloat yValue = self.minimumValue + (self.maximumValue - self.minimumValue)*factor;

			UILabel *axisTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, labelYPosition, CGRectGetWidth(self.yAxisView.frame) - kAxisMarkingRulerLength, labelHeight)];

			if (yValue != 0) {
				axisTitleLabel.text = [NSString stringWithFormat:@"%0.0f", yValue];
			}
			axisTitleLabel.backgroundColor = [UIColor clearColor];
			axisTitleLabel.textColor = self.secondaryTintColor ?: self.axisTitleColor;
			axisTitleLabel.textAlignment = NSTextAlignmentRight;
			axisTitleLabel.font = self.isLandscapeMode ? [UIFont fontWithName:self.axisTitleFont.familyName size:16.0f] : self.axisTitleFont;
			axisTitleLabel.minimumScaleFactor = 0.8;
			[self.yAxisView addSubview:axisTitleLabel];
		}

		[self prepareDataForPlotIndex:1];

		axisViewXPosition = 0.f;
		axisViewWidth = CGRectGetWidth(self.frame) * kYAxisPaddingFactor;

		self.secondaryYAxisView = [[UIView alloc] initWithFrame:CGRectMake(axisViewXPosition, kAPCGraphTopPadding, axisViewWidth, CGRectGetHeight(self.plotsView.frame))];
		[self addSubview:self.secondaryYAxisView];

		if (self.secondaryMinimumValue == self.secondaryMaximumValue) {
			yAxisLabelFactors = @[@0.5f];
		} else {
			yAxisLabelFactors = @[@0.2f, @1.0f];
		}

		for (NSUInteger i = 0; i < yAxisLabelFactors.count; i++) {

			CGFloat labelHeight = 20;
			CGFloat factor = [yAxisLabelFactors[i] floatValue];
			CGFloat labelYPosition = CGRectGetHeight(self.plotsView.frame) * (1 - factor) - labelHeight / 2;
			CGFloat yValue = self.secondaryMinimumValue + (self.secondaryMaximumValue - self.secondaryMinimumValue) * factor;

			UILabel *axisTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAxisMarkingRulerLength, labelYPosition, CGRectGetWidth(self.secondaryYAxisView.frame), labelHeight)];

			if (yValue != 0) {
				axisTitleLabel.text = [NSString stringWithFormat:@"%0.0f", yValue];
			}

			axisTitleLabel.backgroundColor = [UIColor clearColor];
			axisTitleLabel.textColor = self.tintColor ?: self.axisTitleColor;
			axisTitleLabel.textAlignment = NSTextAlignmentLeft;
			axisTitleLabel.font = self.isLandscapeMode ? [UIFont fontWithName:self.axisTitleFont.familyName
																		 size:16.0f] : self.axisTitleFont;
			axisTitleLabel.minimumScaleFactor = 0.8;
			[self.secondaryYAxisView addSubview:axisTitleLabel];

			UIBezierPath *rulerPath = [UIBezierPath bezierPath];
			CGFloat rulerYPosition = labelYPosition + labelHeight / 2;
			[rulerPath moveToPoint:CGPointMake(0, rulerYPosition)];
			[rulerPath addLineToPoint:CGPointMake(kAxisMarkingRulerLength, rulerYPosition)];

			CAShapeLayer *rulerLayer = [CAShapeLayer layer];
			rulerLayer.strokeColor = (self.tintColor ?: self.axisTitleColor).CGColor;
			rulerLayer.path = rulerPath.CGPath;
			[self.secondaryYAxisView.layer addSublayer:rulerLayer];

			[self drawXAxis];
		}
	} else {
		[super drawYAxis];
	}
}

- (NSArray *)normalizeCanvasPoints:(NSArray *) __unused dataPoints forRect:(CGSize)canvasSize plotIndex:(NSInteger)plotIndex
{
    [self calculateMinAndMaxPoints];
    
    NSMutableArray *normalizedDataPointValues = [NSMutableArray new];

	CGFloat minimumValue = (self.numberOfPlots > 1 && plotIndex == 0) ? self.secondaryMinimumValue : self.minimumValue;
	CGFloat maximumValue = (self.numberOfPlots > 1 && plotIndex == 0) ? self.secondaryMaximumValue : self.maximumValue;

	NSLog(@"plot %@ : min %@ : max %@ : self %p", @(plotIndex), @(minimumValue), @(maximumValue), self);
	
    for (NSUInteger i=0; i<self.dataPoints.count; i++) {
        NSDictionary *dataPoint = self.dataPoints[i];
        NSMutableDictionary *normalizedDataPoint = dataPoint.mutableCopy;

		// Normalize value
		CGFloat dataPointValue = [[dataPoint valueForKey:kDatasetValueKey] floatValue];
		CGFloat normalizedPointValue;

		if (dataPointValue == 0){
			normalizedPointValue = canvasSize.height;
		} else if (dataPointValue != NSNotFound && minimumValue == maximumValue) {
			normalizedPointValue = canvasSize.height/2;
		} else {
			CGFloat range = maximumValue - minimumValue;
			CGFloat normalizedValue = (dataPointValue - minimumValue)/range * canvasSize.height;
			normalizedPointValue = canvasSize.height - normalizedValue;
		}

		normalizedDataPoint[kDatasetValueKey] = @(normalizedPointValue);
        
        // Normalize range
        APCRangePoint *rangePoint = dataPoint[kDatasetRangeValueKey];
        APCRangePoint *normalizedRangePoint = [APCRangePoint new];
        
        if (!rangePoint && dataPointValue != NSNotFound) {
            rangePoint = [[APCRangePoint alloc] initWithMinimumValue:dataPointValue maximumValue:dataPointValue];
        }

		if (rangePoint.isEmpty){
            normalizedRangePoint.minimumValue = normalizedRangePoint.maximumValue = canvasSize.height;
        } else if (minimumValue == maximumValue) {
            normalizedRangePoint.minimumValue = normalizedRangePoint.maximumValue = canvasSize.height/2;
        } else {
            CGFloat range = maximumValue - minimumValue;
            CGFloat normalizedMinValue = (rangePoint.minimumValue - minimumValue)/range * canvasSize.height;
            CGFloat normalizedMaxValue = (rangePoint.maximumValue - minimumValue)/range * canvasSize.height;
            
            normalizedRangePoint.minimumValue = canvasSize.height - normalizedMinValue;
            normalizedRangePoint.maximumValue = canvasSize.height - normalizedMaxValue;
        }
        
        normalizedDataPoint[kDatasetRangeValueKey] = normalizedRangePoint;
        
        // Normalize raw data points
        NSArray *rawDataPoints = [dataPoint valueForKey:kDatasetRawDataPointsKey];
        NSMutableArray *normalizedRawDataPoints = [NSMutableArray new];
        for (NSDictionary *rawDataPoint in rawDataPoints) {
            CGFloat pointValue = [[rawDataPoint valueForKey:kDatasetValueKey] floatValue];
            CGFloat normalizedPointValue;
            
            if (pointValue == 0){
                normalizedPointValue = canvasSize.height;
            } else if (minimumValue == maximumValue) {
                normalizedPointValue = canvasSize.height/2;
            } else {
                CGFloat range = maximumValue - minimumValue;
                CGFloat normalizedValue = (pointValue - minimumValue)/range * canvasSize.height;
                normalizedPointValue = canvasSize.height - normalizedValue;
            }
            
            NSMutableDictionary *mutableRawDataPoint = rawDataPoint.mutableCopy;
            mutableRawDataPoint[kDatasetValueKey] = @(normalizedPointValue);
            [normalizedRawDataPoints addObject:[mutableRawDataPoint copy]];
        }
        
        normalizedDataPoint[kDatasetRawDataPointsKey] = normalizedRawDataPoints;
        
        [normalizedDataPointValues addObject:[normalizedDataPoint copy]];
    }
    
    return [NSArray arrayWithArray:normalizedDataPointValues];
}

- (NSInteger)numberOfValidValues
{
    NSInteger count = 0;
    
    for (NSDictionary *dataPoint in self.dataPoints) {
        if (dataPoint.count > 0) {
            count ++;
        }
    }
    return count;
}

- (CGFloat)offsetForPlotIndex:(NSInteger)plotIndex
{
    CGFloat pointWidth = self.isLandscapeMode ? 14.0 : 12.0;
    
    NSInteger numberOfPlots = [self numberOfPlots];
    
    CGFloat offset = 0;
    
    if (numberOfPlots%2 == 0) {
        //Even
        offset = (plotIndex - numberOfPlots/2 + 0.5) * pointWidth;
    } else {
        //Odd
        offset = (plotIndex - numberOfPlots/2) * pointWidth;
    }
    
    return offset;
}

#pragma mark - Calculations

- (void)calculateXAxisPoints {
    [self.xAxisPoints removeAllObjects];
	if (self.numberOfPlots > 1) {
		for (int i=0 ; i<[self numberOfXAxisTitles]; i++) {
			CGFloat positionOnXAxis = (((CGRectGetWidth(self.plotsView.frame) - CGRectGetWidth(self.secondaryYAxisView.bounds)) /
				(self.numberOfXAxisTitles - 1)) * i) + CGRectGetWidth(self.secondaryYAxisView.bounds);
			positionOnXAxis = round(positionOnXAxis);
			[self.xAxisPoints addObject:@(positionOnXAxis)];
		}
	} else {
		[super calculateXAxisPoints];
	}
}

- (void)prepareDataForPlotIndex:(NSInteger)plotIndex
{
    [self.dataPoints removeAllObjects];
    [self.yAxisPoints removeAllObjects];
    self.hasDataPoint = NO;
    for (int i = 0; i<[self numberOfPointsInPlot:plotIndex]; i++) {
        
        if ([self.datasource respondsToSelector:@selector(discreteGraph:plot:dictionaryValueForPointAtIndex:)]) {
            NSDictionary *value = [self.datasource discreteGraph:self plot:plotIndex dictionaryValueForPointAtIndex:i];
            
            if (value) {
                [self.dataPoints addObject:value];
            }
            
            if (![value[kDatasetRangeValueKey] isEmpty]){
                self.hasDataPoint = YES;
            }
        }
    }
    
    [self.yAxisPoints addObjectsFromArray:[self normalizeCanvasPoints:self.dataPoints forRect:self.plotsView.frame.size plotIndex:plotIndex]];
}

- (CGFloat)valueForCanvasXPosition:(CGFloat)xPosition
{
    BOOL snapped = [self.xAxisPoints containsObject:@(xPosition)];
    
    CGFloat value = NSNotFound;
    
    NSUInteger positionIndex = 0;
    
    if (snapped) {
        for (positionIndex = 0; positionIndex<self.xAxisPoints.count-1; positionIndex++) {
            CGFloat xAxisPointVal = [self.xAxisPoints[positionIndex] floatValue];
            if (xAxisPointVal == xPosition) {
                break;
            }
        }
        
        NSDictionary *dataPoint = self.dataPoints[positionIndex];
        value = ((APCRangePoint *)dataPoint[kDatasetRangeValueKey]).maximumValue;
    }
    
    return value;
}

//Scrubber Y position
- (CGFloat)canvasYPointForXPosition:(CGFloat)xPosition
{
    BOOL snapped = [self.xAxisPoints containsObject:@(xPosition)];
    
    CGFloat canvasYPosition = 0;
    
    NSUInteger positionIndex = 0;
    
    if (snapped) {
        for (positionIndex = 0; positionIndex<self.xAxisPoints.count-1; positionIndex++) {
            CGFloat xAxisPointVal = [self.xAxisPoints[positionIndex] floatValue];
            if (xAxisPointVal == xPosition) {
                break;
            }
        }
        
        NSDictionary *yAxisPoint = self.yAxisPoints[positionIndex];
        canvasYPosition = ((APCRangePoint *)yAxisPoint[kDatasetRangeValueKey]).maximumValue;
    }
    
    return canvasYPosition;
}

- (CGFloat)snappedXPosition:(CGFloat)xPosition
{
    CGFloat widthBetweenPoints = CGRectGetWidth(self.plotsView.frame)/self.xAxisPoints.count;
    
    NSUInteger positionIndex;
    for (positionIndex = 0; positionIndex<self.xAxisPoints.count; positionIndex++) {
        
        NSDictionary *dataPoint = self.dataPoints[positionIndex];
        CGFloat dataPointVal = ((APCRangePoint *)dataPoint[kDatasetRangeValueKey]).maximumValue;
        
        if (dataPointVal != NSNotFound) {
            CGFloat num = [self.xAxisPoints[positionIndex] floatValue];
            
            if (fabs(num - xPosition) < (widthBetweenPoints * kSnappingClosenessFactor)) {
                xPosition = num;
            }
        }    
    }
    
    return xPosition;
}

@end
