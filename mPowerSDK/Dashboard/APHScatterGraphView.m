//
//  APHScatterGraphView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-01.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHScatterGraphView.h"

@interface APCDiscreteGraphView (Private)
@property (nonatomic) BOOL hasDataPoint;
@property (nonatomic) BOOL shouldAnimate;
@property (nonatomic, strong) NSMutableArray *dataPoints;
@property (nonatomic, strong) NSMutableArray *dots;
@property (nonatomic, strong) NSMutableArray *xAxisPoints;
@property (nonatomic, strong) NSMutableArray *yAxisPoints;
@property (nonatomic, strong) UIView *plotsView;
- (void)prepareDataForPlotIndex:(NSInteger)plotIndex;
- (NSArray *)normalizeCanvasPoints:(NSArray *) __unused dataPoints forRect:(CGSize)canvasSize;
- (CGFloat)offsetForPlotIndex:(NSInteger)plotIndex;
- (void)calculateMinAndMaxPoints;
@end

@implementation APHScatterGraphView

- (void)prepareDataForPlotIndex:(NSInteger)plotIndex
{
    [self.dataPoints removeAllObjects];
    [self.yAxisPoints removeAllObjects];
    self.hasDataPoint = NO;
    for (int i = 0; i<[self numberOfPointsInPlot:plotIndex]; i++) {
        
        if ([self.scatterGraphDelegate respondsToSelector:@selector(scatterGraph:plot:valuesForPointsAtIndex:)]) {
            NSDictionary *values = [self.scatterGraphDelegate scatterGraph:self plot:plotIndex valuesForPointsAtIndex:i];
            
            if (values) {
                [self.dataPoints addObject:values];
            }
        }
    }
    
    [self.yAxisPoints addObjectsFromArray:[self normalizeCanvasPoints:self.dataPoints forRect:self.plotsView.frame.size]];
}

- (void)drawPointCirclesForPlotIndex:(NSInteger)plotIndex
{
    CGFloat pointSize = self.isLandscapeMode ? 10.0f : 8.0f;
    
    for (NSUInteger i=0 ; i<self.yAxisPoints.count; i++) {
        
        NSDictionary *dataPointVal = (NSDictionary *)self.dataPoints[i];
        
        CGFloat positionOnXAxis = [self.xAxisPoints[i] floatValue];
        positionOnXAxis += [self offsetForPlotIndex:plotIndex];
        
        if (!dataPointVal.count == 0) {
            
            APCRangePoint *positionOnYAxis = (APCRangePoint *)self.yAxisPoints[i];
            
            {
                APCCircleView *point = [[APCCircleView alloc] initWithFrame:CGRectMake(0, 0, pointSize, pointSize)];
                point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
                point.center = CGPointMake(positionOnXAxis, positionOnYAxis.minimumValue);
                [self.plotsView.layer addSublayer:point.layer];
                
                if (self.shouldAnimate) {
                    point.alpha = 0;
                }
                
                [self.dots addObject:point];
            }
            
            if (![positionOnYAxis isRangeZero]) {
                
                CGFloat pointSize = self.isLandscapeMode ? 10.0f : 8.0f;
                APCCircleView *point = [[APCCircleView alloc] initWithFrame:CGRectMake(0, 0, pointSize, pointSize)];
                point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
                point.center = CGPointMake(positionOnXAxis, positionOnYAxis.maximumValue);
                [self.plotsView.layer addSublayer:point.layer];
                
                if (self.shouldAnimate) {
                    point.alpha = 0;
                }
                
                [self.dots addObject:point];
            }
            
            for (NSDictionary *rawDataPoint in [dataPointVal valueForKey:@"datasetRawDataPoints"]) {
                
            }
        }
    }
}

- (NSArray *)normalizeCanvasPoints:(NSArray *) __unused dataPoints forRect:(CGSize)canvasSize
{
    return dataPoints;
}

- (NSInteger)numberOfValidValues
{
    NSInteger count = 0;
    
    for (NSDictionary *dataVal in self.dataPoints) {
        APCRangePoint *dataPointValue = [dataVal valueForKey:@"datasetRangeValueKey"];
        if (!dataPointValue.isEmpty) {
            count ++;
        }
    }
    return count;
}

@end
