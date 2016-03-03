//
//  APHLineGraphView.m
//  mPowerSDK
//
//  Created by Andy Yeung on 3/2/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHLineGraphView.h"

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

- (void)drawGraphForPlotIndex:(NSInteger)plotIndex;

@end

@implementation APHLineGraphView

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

	if (self.drawLastPoint) {
		[self drawLastPointDot:plotIndex];
	}
}

- (void)drawLastPointDot:(NSInteger)plotIndex
{

	NSUInteger smallestArrayCount = self.yAxisPoints.count < self.xAxisPoints.count ?: self.xAxisPoints.count;
	smallestArrayCount--;

	CGFloat dataPointVal = [self.dataPoints[smallestArrayCount] floatValue];

	CGFloat positionOnXAxis = [self.xAxisPoints[smallestArrayCount] floatValue];

	if (dataPointVal != NSNotFound) {
		CGFloat positionOnYAxis = ((NSNumber*)self.yAxisPoints[smallestArrayCount]).floatValue;

		CGFloat pointSize = self.isLandscapeMode ? 10.0f : 8.0f;
		APCCircleView *point = [[APCCircleView alloc] initWithFrame:CGRectMake(0, 0, pointSize, pointSize)];
		point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
		point.shapeLayer.fillColor = point.tintColor.CGColor;
		point.center = CGPointMake(positionOnXAxis, positionOnYAxis);
		[self.plotsView.layer addSublayer:point.layer];

		if (self.shouldAnimate) {
			point.alpha = 0;
		}

		[self.dots addObject:point];
	}
}

@end
