//
//  APHLineGraphView.m
//  mPowerSDK
//
//  Created by Andy Yeung on 3/2/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHLineGraphView.h"
#import "APHRegularShapeView.h"

static CGFloat const kAPCGraphLeftPadding = 10.f;
static CGFloat const kAxisMarkingRulerLength = 8.0f;

@interface APCLineGraphView (Private)

@property (nonatomic, strong) NSMutableArray *dataPoints;
@property (nonatomic, strong) APCAxisView *xAxisView;
@property (nonatomic, strong) NSMutableArray *xAxisTitles;
@property (nonatomic, strong) NSMutableArray *xAxisPoints;
@property (nonatomic, strong) NSMutableArray *yAxisPoints;
@property (nonatomic) NSInteger numberOfXAxisTitles;
@property (nonatomic, strong) NSMutableArray *dots;
@property (nonatomic) BOOL shouldAnimate;

@property (nonatomic, strong) APCCubicCurveAlgorithm *smoothCurveGenerator;
@property (nonatomic, strong) NSMutableArray *pathLines;
@property (nonatomic, strong) NSMutableArray *fillLayers;

- (void)drawGraphForPlotIndex:(NSInteger)plotIndex;
- (void)drawLinesForPlotIndex:(NSInteger)plotIndex;

@end

@implementation APHLineGraphView

- (UIColor *)colorForFirstCorrelationLine
{
    if (nil == _colorForFirstCorrelationLine) {
        _colorForFirstCorrelationLine = self.tintColor;
    }
    
    return _colorForFirstCorrelationLine;
}

- (UIColor *)colorForSecondCorrelationLine
{
    if (nil == _colorForSecondCorrelationLine) {
        _colorForSecondCorrelationLine = self.secondaryTintColor;
    }
    
    return _colorForSecondCorrelationLine;
}

- (void)drawXAxis
{
    //Add Title Labels
    [self.xAxisTitles removeAllObjects];
    
    for (int i=0; i<self.numberOfXAxisTitles; i++) {
        if ([self.datasource respondsToSelector:@selector(lineGraph:titleForXAxisAtIndex:)]) {
            NSString *title = [self.datasource lineGraph:self titleForXAxisAtIndex:i];
            
            [self.xAxisTitles addObject:title];
        }
    }
    
    if (self.xAxisView) {
        [self.xAxisView removeFromSuperview];
        self.xAxisView = nil;
    }
    
    self.axisColor = [UIColor appTertiaryGrayColor];
    
    self.xAxisView = [[APCAxisView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.plotsView.frame), CGRectGetWidth(self.plotsView.frame), kXAxisHeight)];
    self.xAxisView.landscapeMode = self.landscapeMode;
    self.xAxisView.tintColor = self.axisColor;
    self.xAxisView.shouldHighlightLastLabel = self.shouldHighlightXaxisLastTitle;
    [self.xAxisView setupLabels:self.xAxisTitles forAxisType:kAPCGraphAxisTypeX];
    self.xAxisView.leftOffset = kAPCGraphLeftPadding;
    [self insertSubview:self.xAxisView belowSubview:self.plotsView];
    
    UIBezierPath *xAxispath = [UIBezierPath bezierPath];
    [xAxispath moveToPoint:CGPointMake(0, 0)];
    [xAxispath addLineToPoint:CGPointMake(CGRectGetWidth(self.frame), 0)];
    
    CAShapeLayer *xAxisLineLayer = [CAShapeLayer layer];
    xAxisLineLayer.strokeColor = self.axisColor.CGColor;
    xAxisLineLayer.path = xAxispath.CGPath;
    [self.xAxisView.layer addSublayer:xAxisLineLayer];
    
    for (NSUInteger i=0; i<self.xAxisTitles.count; i++) {
        CGFloat positionOnXAxis = kAPCGraphLeftPadding + ((CGRectGetWidth(self.plotsView.frame) / (self.numberOfXAxisTitles - 1)) * i);
        
        UIBezierPath *rulerPath = [UIBezierPath bezierPath];
        [rulerPath moveToPoint:CGPointMake(positionOnXAxis, - kAxisMarkingRulerLength)];
        [rulerPath addLineToPoint:CGPointMake(positionOnXAxis, 0)];
        
        CAShapeLayer *rulerLayer = [CAShapeLayer layer];
        rulerLayer.strokeColor = self.axisColor.CGColor;
        rulerLayer.path = rulerPath.CGPath;
        [self.xAxisView.layer addSublayer:rulerLayer];
    }
}

- (void)drawGraphForPlotIndex:(NSInteger)plotIndex {
	[super drawGraphForPlotIndex:plotIndex];

	if (self.shouldDrawLastPoint) {
		[self drawLastPointDot:plotIndex];
	}
}

- (NSInteger)findLastValidPointIndex:(NSArray *)pointsArray {
	__block NSInteger i = -1;
	[pointsArray enumerateObjectsWithOptions:NSEnumerationReverse
									  usingBlock:^(NSNumber *dataPoint, NSUInteger idx, BOOL *stop) {
										  if (dataPoint.unsignedIntegerValue != NSNotFound) {
											  i = idx;
											  *stop = YES;
										  }
									  }];

	return i;
}

- (void)drawLastPointDot:(NSInteger)plotIndex {
	NSInteger i = [self findLastValidPointIndex:[self.dataPoints copy]];
	if (i < 0) {
		return;
	}

	CGFloat positionOnXAxis = ((NSNumber *)self.xAxisPoints[i]).floatValue;
	CGFloat positionOnYAxis = ((NSNumber *)self.yAxisPoints[i]).floatValue;

	CGFloat pointSize = 6.0f;
	APCCircleView *point = [[APCCircleView alloc] initWithFrame:CGRectMake(0, 0, pointSize, pointSize)];
	point.tintColor = (plotIndex == 0) ? self.colorForFirstCorrelationLine : self.colorForSecondCorrelationLine;
	point.shapeLayer.fillColor = point.tintColor.CGColor;
	point.center = CGPointMake(positionOnXAxis, positionOnYAxis);
	[self.plotsView.layer addSublayer:point.layer];

	if (self.shouldAnimate) {
		point.alpha = 0;
	}

	[self.dots addObject:point];
}

- (void)drawLinesForPlotIndex:(NSInteger)plotIndex
{
    UIBezierPath *fillPath = [UIBezierPath bezierPath];
    
    CGPoint position = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGPoint prevPosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    
    NSMutableArray *pointsArray = [NSMutableArray new];
    
    NSUInteger smallestArrayCount = self.yAxisPoints.count < self.xAxisPoints.count ?: self.xAxisPoints.count;
    
    for (NSUInteger i=0; i< smallestArrayCount; i++) {
        CGPoint point = CGPointMake([self.xAxisPoints[i] doubleValue], [self.yAxisPoints[i] doubleValue]);
        [pointsArray addObject:[NSValue valueWithCGPoint:point]];
    }
    
    NSArray *controlPoints = [self.smoothCurveGenerator controlPointsFromPoints:pointsArray];
    
    BOOL emptyDataPresent = NO;
    
    for (NSUInteger i=0; i<smallestArrayCount; i++) {
        
        CGFloat dataPointVal = [self.dataPoints[i] floatValue];
        
        if (dataPointVal != NSNotFound) {
            
            UIBezierPath *plotLinePath = [UIBezierPath bezierPath];
            
            position = CGPointMake([self.xAxisPoints[i] floatValue], [self.yAxisPoints[i] floatValue]);
            
            if (prevPosition.x != CGFLOAT_MAX) {
                //Prev point exists
                [plotLinePath moveToPoint:prevPosition];
                if ([fillPath isEmpty]) {
                    [fillPath moveToPoint:CGPointMake(prevPosition.x, CGRectGetHeight(self.plotsView.frame))];
                    [fillPath addLineToPoint:prevPosition];
                }
            }
            
            if (![plotLinePath isEmpty]) {
                
                if (self.smoothLines && (self.yAxisPoints.count>2)) {
                    
                    APCCubicCurveSegment *segment = controlPoints[i-1];
                    
                    [plotLinePath addCurveToPoint:position controlPoint1:segment.controlPoint1 controlPoint2:segment.controlPoint2];
                    [fillPath addCurveToPoint:position controlPoint1:segment.controlPoint1 controlPoint2:segment.controlPoint2];
                    
                } else {
                    [plotLinePath addLineToPoint:position];
                    [fillPath addLineToPoint:position];
                }
                
                CAShapeLayer *plotLineLayer = [CAShapeLayer layer];
                plotLineLayer.path = plotLinePath.CGPath;
                plotLineLayer.fillColor = [UIColor clearColor].CGColor;
                plotLineLayer.strokeColor = (plotIndex == 0) ? self.colorForFirstCorrelationLine.CGColor : self.colorForSecondCorrelationLine.CGColor;
                plotLineLayer.lineJoin = kCALineJoinRound;
                plotLineLayer.lineCap = kCALineCapRound;
                plotLineLayer.lineWidth = self.isLandscapeMode ? 3.0 : 2.0;
                
//                if (emptyDataPresent) {
//                    plotLineLayer.lineDashPattern = self.isLandscapeMode ? @[@12, @7] : @[@12, @6];
//                    emptyDataPresent = NO;
//                }
                
                [self.plotsView.layer addSublayer:plotLineLayer];
                
                if (self.shouldAnimate) {
                    plotLineLayer.strokeEnd = 0;
                }
                [self.pathLines addObject:plotLineLayer];
            } else {
                emptyDataPresent = NO;
            }
            
        } else {
            emptyDataPresent = YES;
        }
        
        prevPosition = position;
    }
    
    [fillPath addLineToPoint:CGPointMake(position.x, CGRectGetHeight(self.plotsView.frame))];
    
    CAShapeLayer *fillPathLayer = [CAShapeLayer layer];
    fillPathLayer.path = fillPath.CGPath;
    fillPathLayer.fillColor = (plotIndex == 0) ? self.colorForFirstCorrelationLine.CGColor : self.colorForSecondCorrelationLine.CGColor;
    [self.plotsView.layer addSublayer:fillPathLayer];
    
    if (self.shouldAnimate) {
        fillPathLayer.opacity = 0;
    }
    
    if (self.showsFillPath) {
        [self.fillLayers addObject:fillPathLayer];
    }
}

@end
