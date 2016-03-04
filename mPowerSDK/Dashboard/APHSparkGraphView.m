//
//  APHSparkGraphView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-03.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHSparkGraphView.h"
#import "APHRegularShapeView.h"
#import "APHMedicationTrackerTask.h"
#import "NSNull+APHExtensions.h"

NSString * const kAPCLineGraphViewTriggerAnimationsNotification = @"APCLineGraphViewTriggerAnimationsNotification";
NSString * const kAPCLineGraphViewRefreshNotification = @"APCLineGraphViewRefreshNotification";

static CGFloat const kYAxisPaddingFactor = 0.15f;
static CGFloat const kAPCGraphLeftPadding = 10.f;
static CGFloat const kAxisMarkingRulerLength = 8.0f;

static CGFloat const kSnappingClosenessFactor = 0.3f;

@interface APHSparkGraphView ()

@property (nonatomic, strong) NSMutableArray *dataPoints;//actual data
@property (nonatomic, strong) NSMutableArray *xAxisPoints;
@property (nonatomic, strong) NSMutableArray *yAxisPoints;//normalised for this view

@property (nonatomic, strong) APCAxisView *xAxisView;
@property (nonatomic, strong) UIView *yAxisView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic) BOOL hasDataPoint;

@property (nonatomic, strong) UIView *scrubberLine;
@property (nonatomic, strong) UILabel *scrubberLabel;
@property (nonatomic, strong) UIView *scrubberThumbView;

@property (nonatomic, readwrite) CGFloat minimumValue;
@property (nonatomic, readwrite) CGFloat maximumValue;

@property (nonatomic, strong) NSMutableArray *xAxisTitles;
@property (nonatomic) NSInteger numberOfXAxisTitles;

@property (nonatomic, strong) NSMutableArray *referenceLines;
@property (nonatomic, strong) NSMutableArray *pathLines;
@property (nonatomic, strong) NSMutableArray *dots;
@property (nonatomic, strong) NSMutableArray *fillLayers;

@property (nonatomic) BOOL shouldAnimate;

@property (nonatomic, strong) APCCubicCurveAlgorithm *smoothCurveGenerator;

@end

@implementation APHSparkGraphView

@synthesize tintColor = _tintColor;
@synthesize maximumValue = _maximumValue;
@synthesize minimumValue = _minimumValue;

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
    }
    return self;
}

- (void)sharedInit
{
    [super sharedInit];
    
    _dataPoints = [NSMutableArray new];
    
    _xAxisPoints = [NSMutableArray new];
    _yAxisPoints = [NSMutableArray new];
    
    _xAxisTitles = [NSMutableArray new];
    
    _referenceLines = [NSMutableArray new];
    _pathLines = [NSMutableArray new];
    _dots = [NSMutableArray new];
    _fillLayers = [NSMutableArray new];
    
    _tintColor = [UIColor colorWithRed:244/255.f green:190/255.f blue:74/255.f alpha:1.f];
    
    _shouldAnimate = YES;
    
    _hasDataPoint = NO;
    _showsFillPath = NO;
    
    [self setupViews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animateLayersSequentially) name:kAPCLineGraphViewTriggerAnimationsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshGraph) name:kAPCLineGraphViewRefreshNotification object:nil];
    
    _smoothCurveGenerator = [APCCubicCurveAlgorithm new];
}

- (void)setupViews
{
    /* ----------------- */
    /* Basic Views */
    /* ----------------- */
    
    _plotsView = [UIView new];
    _plotsView.backgroundColor = [UIColor clearColor];
    [self addSubview:_plotsView];
    
    /* ----------------- */
    /* Scrubber Views */
    /* ----------------- */
    _scrubberLine = [UIView new];
    _scrubberLine.backgroundColor = self.scrubberLineColor;
    _scrubberLine.alpha = 0;
    [self addSubview:_scrubberLine];
    
    _scrubberLabel = [UILabel new];
    _scrubberLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:12.0f];
    _scrubberLabel.alpha = 0;
    _scrubberLabel.layer.cornerRadius = 2.0f;
    _scrubberLabel.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _scrubberLabel.layer.borderWidth = 1.0f;
    _scrubberLabel.textAlignment = NSTextAlignmentCenter;
    _scrubberLabel.frame = CGRectMake(2, 0, 100, 20);
    _scrubberLabel.backgroundColor = [UIColor colorWithWhite:0.98 alpha:0.8];
    [self addSubview:_scrubberLabel];
    
    _scrubberThumbView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self scrubberThumbSize].width, [self scrubberThumbSize].height)];
    _scrubberThumbView.layer.borderWidth = 1.0;
    _scrubberThumbView.backgroundColor = self.scrubberThumbColor;
    _scrubberThumbView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    _scrubberThumbView.alpha = 0;
    [self addSubview:_scrubberThumbView];
    
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panGestureRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.panGestureRecognizer];
}

- (void)setDefaults
{
    _minimumValue = MAXFLOAT;
    _maximumValue = -MAXFLOAT;
}

- (NSString *)formatNumber:(NSNumber *)value
{
    NSString *formattedNumber = nil;
    NSString *suffix = @"k";
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    if ([value doubleValue] < 1000) {
        [numberFormatter setMaximumFractionDigits:0];
        formattedNumber = [numberFormatter stringFromNumber:value];
    } else {
        NSNumber *divdedValue = @([value doubleValue]/1000);
        [numberFormatter setMaximumFractionDigits:2];
        formattedNumber =  [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:divdedValue], suffix];
    }
    
    return formattedNumber;
}

#pragma mark - Appearance

- (void)updateScrubberLabel
{
    if (self.isLandscapeMode) {
        self.scrubberLabel.font = [UIFont fontWithName:self.scrubberLabel.font.familyName size:14.0f];
    } else {
        self.scrubberLabel.font = [UIFont fontWithName:self.scrubberLabel.font.familyName size:12.0f];
    }
}

- (CGSize)scrubberThumbSize
{
    CGSize thumbSize;
    
    if (self.isLandscapeMode) {
        thumbSize = CGSizeMake(15, 15);
    } else{
        thumbSize = CGSizeMake(10, 10);
    }
    
    return thumbSize;
}


#pragma mark - View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat yAxisPadding = CGRectGetWidth(self.frame)*kYAxisPaddingFactor;
    
    //Basic Views
    
    self.plotsView.frame = CGRectMake(kAPCGraphLeftPadding, kAPCGraphTopPadding, CGRectGetWidth(self.frame) - yAxisPadding - kAPCGraphLeftPadding, CGRectGetHeight(self.frame) - kXAxisHeight - kAPCGraphTopPadding);
    
    if (self.emptyLabel) {
        self.emptyLabel.frame = CGRectMake(kAPCGraphLeftPadding, kAPCGraphTopPadding, CGRectGetWidth(self.frame) - kAPCGraphLeftPadding, CGRectGetHeight(self.frame) - kXAxisHeight - kAPCGraphTopPadding);
    }
    
    //Scrubber Views
    self.scrubberLine.frame = CGRectMake(CGRectGetMinX(self.scrubberLine.frame), kAPCGraphTopPadding, 1, CGRectGetHeight(self.plotsView.frame));
    [self updateScrubberLabel];
    self.scrubberThumbView.frame = CGRectMake(CGRectGetMinX(self.scrubberThumbView.frame), CGRectGetMinY(self.scrubberThumbView.frame), [self scrubberThumbSize].width, [self scrubberThumbSize].height);
    self.scrubberThumbView.layer.cornerRadius = self.scrubberThumbView.bounds.size.height/2;
    
    [self.xAxisView layoutSubviews];
    
}

- (void)refreshGraph
{
    //Clear subviews and sublayers
    [self.plotsView.layer.sublayers makeObjectsPerformSelector:@selector(removeAllAnimations)];
    [self.plotsView.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    
    [self drawXAxis];
    [self drawYAxis];
    
    if (self.showsHorizontalReferenceLines) {
        [self drawhorizontalReferenceLines];
    }
    
    if (self.showsVerticalReferenceLines) {
        [self drawVerticalReferenceLines];
    }
    
    [self calculateXAxisPoints];
    
    [self.dots removeAllObjects];
    [self.pathLines removeAllObjects];
    [self.fillLayers removeAllObjects];
    
    for (int i=0; i<[self numberOfPlots]; i++) {
        if ([self numberOfPointsInPlot:i] <= 1) {
            return;
        } else {
            [self drawGraphForPlotIndex:i];
        }
    }
    
    if (!self.hasDataPoint) {
        [self setupEmptyView];
    } else {
        if (self.emptyLabel) {
            [self.emptyLabel removeFromSuperview];
        }
    }
    
    [self animateLayersSequentially];
    
}

- (void)setupEmptyView
{
    if (!_emptyLabel) {
        
        _emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(kAPCGraphLeftPadding, kAPCGraphTopPadding, CGRectGetWidth(self.frame) - kAPCGraphLeftPadding, CGRectGetHeight(self.frame) - kXAxisHeight - kAPCGraphTopPadding)];
        _emptyLabel.text = self.emptyText;
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.font = [UIFont fontWithName:@"Helvetica" size:25];
        _emptyLabel.textColor = [UIColor lightGrayColor];
    }
    
    [self addSubview:_emptyLabel];
}

#pragma mark - Data

- (NSInteger)numberOfPlots
{
    NSInteger numberOfPlots = 1;
    
    if ([self.datasource respondsToSelector:@selector(numberOfPlotsInLineGraph:)]) {
        numberOfPlots = [self.datasource numberOfPlotsInSparkGraph:self];
    }
    
    return numberOfPlots;
}

- (NSInteger)numberOfPointsInPlot:(NSInteger)plotIndex
{
    NSInteger numberOfPoints = 0;
    
    if ([self.datasource respondsToSelector:@selector(lineGraph:numberOfPointsInPlot:)]) {
        numberOfPoints = [self.datasource sparkGraph:self numberOfPointsInPlot:plotIndex];
        
    }
    
    return numberOfPoints;
}

- (NSInteger)numberOfXAxisTitles
{
    _numberOfXAxisTitles = 0;
    
    if ([self.datasource respondsToSelector:@selector(numberOfDivisionsInXAxisForGraph:)]) {
        _numberOfXAxisTitles = [self.datasource numberOfDivisionsInXAxisForSparkGraph:self];
    } else {
        _numberOfXAxisTitles = [self numberOfPointsInPlot:0];
    }
    
    return _numberOfXAxisTitles;
}

- (void)calculateXAxisPoints
{
    [self.xAxisPoints removeAllObjects];
    
    for (NSUInteger i=0 ; i < [self.dataPoints count]; i++) {
        
        CGFloat positionOnXAxis = ((CGRectGetWidth(self.plotsView.frame) / (self.yAxisPoints.count - 1)) * i);
        positionOnXAxis = round(positionOnXAxis);
        [self.xAxisPoints addObject:@(positionOnXAxis)];
    }
}

- (void)prepareDataForPlotIndex:(NSInteger)plotIndex
{
    [self.dataPoints removeAllObjects];
    [self.yAxisPoints removeAllObjects];
    self.hasDataPoint = NO;
    for (int i = 0; i<[self numberOfPointsInPlot:plotIndex]; i++) {
        
        if ([self.datasource respondsToSelector:@selector(lineGraph:plot:valueForPointAtIndex:)]) {
            NSDictionary *value = [self.datasource sparkGraph:self plot:plotIndex valueForPointAtIndex:i];
            
            if (value) {
                [self.dataPoints addObject:value];
            }
            
            if (value.count != 0){
                self.hasDataPoint = YES;
            }
            
        }
    }
    
    [self.yAxisPoints addObjectsFromArray:[self normalizeCanvasPoints:self.dataPoints forRect:self.plotsView.frame.size]];
}

#pragma mark - Draw

- (void)drawXAxis
{
    //Add Title Labels
    [self.xAxisTitles removeAllObjects];
    
    for (int i=0; i<self.numberOfXAxisTitles; i++) {
        if ([self.datasource respondsToSelector:@selector(lineGraph:titleForXAxisAtIndex:)]) {
            NSString *title = [self.datasource sparkGraph:self titleForXAxisAtIndex:i];
            
            [self.xAxisTitles addObject:title];
        }
    }
    
    if (self.xAxisView) {
        [self.xAxisView removeFromSuperview];
        self.xAxisView = nil;
    }
    
    self.xAxisView = [[APCAxisView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.plotsView.frame), CGRectGetWidth(self.plotsView.frame), kXAxisHeight)];
    self.xAxisView.landscapeMode = self.landscapeMode;
    self.xAxisView.tintColor = self.tintColor;
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
}

- (void)drawYAxis
{
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
    
    if (self.maximumValueImage && self.minimumValueImage) {
        //Use image icons as legends
        
        CGFloat width = CGRectGetWidth(self.yAxisView.frame)/2;
        CGFloat verticalPadding = 3.f;
        
        UIImageView *maxImageView = [[UIImageView alloc] initWithImage:self.maximumValueImage];
        maxImageView.contentMode = UIViewContentModeScaleAspectFit;
        maxImageView.frame = CGRectMake(CGRectGetWidth(self.yAxisView.bounds) - width, -width/2, width, width);
        [self.yAxisView addSubview:maxImageView];
        
        UIImageView *minImageView = [[UIImageView alloc] initWithImage:self.minimumValueImage];
        minImageView.contentMode = UIViewContentModeScaleAspectFit;
        minImageView.frame = CGRectMake(CGRectGetWidth(self.yAxisView.bounds) - width, CGRectGetMaxY(self.yAxisView.bounds) - width - verticalPadding, width, width);
        [self.yAxisView addSubview:minImageView];
        
    } else {
        
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
            rulerLayer.strokeColor = self.axisColor.CGColor;
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
            axisTitleLabel.textColor = self.axisTitleColor;
            axisTitleLabel.textAlignment = NSTextAlignmentRight;
            axisTitleLabel.font = self.isLandscapeMode ? [UIFont fontWithName:self.axisTitleFont.familyName size:16.0f] : self.axisTitleFont;
            axisTitleLabel.minimumScaleFactor = 0.8;
            [self.yAxisView addSubview:axisTitleLabel];
        }
    }
    
    self.yAxisView.hidden = self.hidesYAxis;
}

- (void)drawhorizontalReferenceLines
{
    [self.referenceLines removeAllObjects];
    
    UIBezierPath *referenceLinePath = [UIBezierPath bezierPath];
    [referenceLinePath moveToPoint:CGPointMake(0, kAPCGraphTopPadding + CGRectGetHeight(self.plotsView.frame)/2)];
    [referenceLinePath addLineToPoint:CGPointMake(CGRectGetWidth(self.frame), kAPCGraphTopPadding + CGRectGetHeight(self.plotsView.frame)/2)];
    
    CAShapeLayer *referenceLineLayer = [CAShapeLayer layer];
    referenceLineLayer.strokeColor = self.referenceLineColor.CGColor;
    referenceLineLayer.path = referenceLinePath.CGPath;
    referenceLineLayer.lineDashPattern = self.isLandscapeMode ? @[@12, @7] : @[@6, @4];
    [self.plotsView.layer addSublayer:referenceLineLayer];
    
    [self.referenceLines addObject:referenceLineLayer];
}

- (void)drawVerticalReferenceLines
{
    for (int i=1; i<self.numberOfXAxisTitles; i++) {
        
        CGFloat positionOnXAxis = ((CGRectGetWidth(self.plotsView.frame) / (self.numberOfXAxisTitles - 1)) * i);
        
        UIBezierPath *referenceLinePath = [UIBezierPath bezierPath];
        [referenceLinePath moveToPoint:CGPointMake(positionOnXAxis, 0)];
        [referenceLinePath addLineToPoint:CGPointMake(positionOnXAxis, CGRectGetHeight(self.plotsView.frame))];
        
        CAShapeLayer *referenceLineLayer = [CAShapeLayer layer];
        referenceLineLayer.strokeColor = self.referenceLineColor.CGColor;
        referenceLineLayer.path = referenceLinePath.CGPath;
        referenceLineLayer.lineDashPattern = self.isLandscapeMode ? @[@12, @7] : @[@6, @4];
        [self.plotsView.layer addSublayer:referenceLineLayer];
        
        [self.referenceLines addObject:referenceLineLayer];
    }
}

- (void)drawGraphForPlotIndex:(NSInteger)plotIndex
{
    [self prepareDataForPlotIndex:plotIndex];
    
    if ([self numberOfValidValues] > 1) {
        [self drawLinesForPlotIndex:plotIndex];
    }
    
    if (!self.hidesDataPoints) {
        [self drawPointCirclesForPlotIndex:plotIndex];
    }

    if (self.shouldDrawShapePointKey) {
        [self drawShapePointKey:plotIndex];
    }
}

- (void)drawPointCirclesForPlotIndex:(NSInteger)plotIndex
{
    
    NSUInteger smallestArrayCount = self.yAxisPoints.count < self.xAxisPoints.count ?: self.xAxisPoints.count;
    
    for (NSUInteger i=0 ; i< smallestArrayCount; i++) {
        
        NSDictionary *dataPoint = self.dataPoints[i];
        CGFloat dataPointVal = [dataPoint[kDatasetValueKey] floatValue];
        
        CGFloat positionOnXAxis = [self.xAxisPoints[i] floatValue];
        
        if (dataPointVal != NSNotFound) {
            NSDictionary *yAxisPoint = self.yAxisPoints[i];
            CGFloat positionOnYAxis = [yAxisPoint[kDatasetValueKey] floatValue];
            
            CGFloat pointSize = self.isLandscapeMode ? 10.0f : 8.0f;
            APCCircleView *point = [[APCCircleView alloc] initWithFrame:CGRectMake(0, 0, pointSize, pointSize)];
            point.tintColor = (plotIndex == 0) ? self.tintColor : self.secondaryTintColor;
            point.center = CGPointMake(positionOnXAxis, positionOnYAxis);
            [self.plotsView.layer addSublayer:point.layer];
            
            if (self.shouldAnimate) {
                point.alpha = 0;
            }
            
            [self.dots addObject:point];
        }
    }
}

- (void)drawLinesForPlotIndex:(NSInteger)plotIndex
{
    UIBezierPath *fillPath = [UIBezierPath bezierPath];
    
    CGPoint position = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGPoint prevPosition = CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX);
    
    NSMutableArray *pointsArray = [NSMutableArray new];
    
    NSUInteger smallestArrayCount = self.yAxisPoints.count < self.xAxisPoints.count ?: self.xAxisPoints.count;
    
    for (NSUInteger i=0; i< smallestArrayCount; i++) {
        NSNumber *xAxisPoint = self.xAxisPoints[i];
        NSDictionary *yAxisPoint = self.yAxisPoints[i];
        CGPoint point = CGPointMake([xAxisPoint doubleValue], [[yAxisPoint valueForKey:kDatasetValueKey] doubleValue]);
        [pointsArray addObject:[NSValue valueWithCGPoint:point]];
    }
    
    NSArray *controlPoints = [self.smoothCurveGenerator controlPointsFromPoints:pointsArray];
    
    BOOL emptyDataPresent = NO;
    
    for (NSUInteger i=0; i<smallestArrayCount; i++) {
        
        NSDictionary *dataPoint = self.dataPoints[i];
        CGFloat dataPointVal = [[dataPoint valueForKey:kDatasetValueKey] floatValue];
        
        if (dataPointVal != NSNotFound) {
            
            UIBezierPath *plotLinePath = [UIBezierPath bezierPath];
            NSDictionary *yAxisPoint = self.yAxisPoints[i];
            position = CGPointMake([self.xAxisPoints[i] floatValue], [[yAxisPoint valueForKey:kDatasetValueKey] floatValue]);
            
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
                plotLineLayer.strokeColor = (plotIndex == 0) ? self.tintColor.CGColor : self.secondaryTintColor.CGColor;
                plotLineLayer.lineJoin = kCALineJoinRound;
                plotLineLayer.lineCap = kCALineCapRound;
                plotLineLayer.lineWidth = self.isLandscapeMode ? 3.0 : 2.0;
                
                if (emptyDataPresent) {
                    plotLineLayer.lineDashPattern = self.isLandscapeMode ? @[@12, @7] : @[@12, @6];
                    emptyDataPresent = NO;
                }
                
                [self.plotsView.layer addSublayer:plotLineLayer];
                
                if (self.shouldAnimate) {
                    plotLineLayer.strokeEnd = 0;
                }
                [self.pathLines addObject:plotLineLayer];
            } else {
                emptyDataPresent = NO;
            }
            
        } else {
            emptyDataPresent = NO;
        }
        
        prevPosition = position;
    }
    
    [fillPath addLineToPoint:CGPointMake(position.x, CGRectGetHeight(self.plotsView.frame))];
    
    CAShapeLayer *fillPathLayer = [CAShapeLayer layer];
    fillPathLayer.path = fillPath.CGPath;
    fillPathLayer.fillColor = (plotIndex == 0) ? [self.tintColor colorWithAlphaComponent:0.4].CGColor : [self.secondaryTintColor colorWithAlphaComponent:0.2].CGColor;
    [self.plotsView.layer addSublayer:fillPathLayer];
    
    if (self.shouldAnimate) {
        fillPathLayer.opacity = 0;
    }
    
    if (self.showsFillPath) {
        [self.fillLayers addObject:fillPathLayer];
    }
}

- (void)drawShapePointKey:(NSInteger)plotIndex {
    __block NSInteger i = -1;
    [self.dataPoints enumerateObjectsUsingBlock:^(NSDictionary *dataPoint, NSUInteger idx, BOOL *stop) {
        if ([dataPoint[kDatasetValueKey] floatValue] != NSNotFound) {
            i = idx;
            *stop = YES;
        }
    }];

    if (i < 0) return;

    CGFloat pointSize = 25.f;
    CGFloat positionOnXAxis = ((NSNumber *)self.xAxisPoints[i]).floatValue - 10.f;
	CGFloat positionOnYAxis = ((NSNumber *)[self.yAxisPoints[i] valueForKey:kDatasetValueKey]).floatValue;
    CGRect pointFrame = CGRectMake(0, 0, pointSize, pointSize);

    NSString *medicationActivityTiming = [self.datasource sparkGraph:self medTimingForPlot:plotIndex];

    APHRegularShapeView *point;
    BOOL pointColorGray = NO;
    
    APHMedicationTrackerTask *medTrackerTask = [[APHMedicationTrackerTask alloc] init];
    NSArray<ORKTextChoice *> *choices = medTrackerTask.activityTimingChoices;
    
    if ([medicationActivityTiming isEqualToString:((ORKTextChoice *)choices[0]).text]) {
        point = [[APHRegularShapeView alloc] initWithFrame:pointFrame andNumberOfSides:0];
    } else if ([medicationActivityTiming isEqualToString:((ORKTextChoice *)choices[1]).text]) {
        point = [[APHRegularShapeView alloc] initWithFrame:pointFrame andNumberOfSides:3];
    } else if ([medicationActivityTiming isEqualToString:((ORKTextChoice *)choices[2]).text]) {
        point = [[APHRegularShapeView alloc] initWithFrame:pointFrame andNumberOfSides:4];
    } else if ([medicationActivityTiming isEqualToString:((ORKTextChoice *)choices[3]).text]) {
        point = [[APHRegularShapeView alloc] initWithFrame:pointFrame andNumberOfSides:5];
    } else {
        pointColorGray = YES;
        point = [[APHRegularShapeView alloc] initWithFrame:pointFrame andNumberOfSides:0];
    }

    point.tintColor = pointColorGray ? [UIColor appTertiaryGrayColor] : self.tintColor;

    point.fillColor = [UIColor clearColor];
    point.center = CGPointMake(positionOnXAxis, positionOnYAxis);
    [self.plotsView.layer addSublayer:point.layer];

    if (self.shouldAnimate) {
        point.alpha = 0;
    }

    [self.dots addObject:point];
}

#pragma mark - Graph Calculations

- (NSInteger)numberOfValidValues
{
    NSInteger count = 0;
    
    for (NSDictionary *dataVal in self.dataPoints) {
        if (dataVal.count > 0) {
            count ++;
        }
    }
    return count;
}

- (void)calculateMinAndMaxPoints
{
    [self setDefaults];
    
    //Min
    if ([self.datasource respondsToSelector:@selector(minimumValueForLineGraph:)]) {
        self.minimumValue = [self.datasource minimumValueForSparkGraph:self];
    } else {
        
        if (self.dataPoints.count) {
            NSDictionary *dataPoint = self.dataPoints[0];
            self.minimumValue = [[dataPoint valueForKey:kDatasetValueKey ] floatValue];
            
            for (NSUInteger i=1; i<self.dataPoints.count; i++) {
                dataPoint = self.dataPoints[i];
                NSNumber *num = dataPoint[kDatasetValueKey];
                if ((self.minimumValue == NSNotFound) || (num.floatValue < self.minimumValue)) {
                    self.minimumValue = num.floatValue;
                }
            }
        }
        
    }
    
    //Max
    if ([self.datasource respondsToSelector:@selector(maximumValueForLineGraph:)]) {
        self.maximumValue = [self.datasource maximumValueForSparkGraph:self];
    } else {
        if (self.dataPoints.count) {
            NSDictionary *dataPoint = self.dataPoints[0];
            self.maximumValue = [dataPoint[kDatasetValueKey] floatValue];
            
            for (NSUInteger i=1; i<self.dataPoints.count; i++) {
                dataPoint = self.dataPoints[i];
                NSNumber *num = dataPoint[kDatasetValueKey];
                if (((num.floatValue != NSNotFound) && (num.floatValue > self.maximumValue)) || (self.maximumValue == NSNotFound)) {
                    self.maximumValue = num.floatValue;
                }
            }
        }
    }
}

- (NSArray *)normalizeCanvasPoints:(NSArray *) __unused dataPoints forRect:(CGSize)canvasSize
{
    [self calculateMinAndMaxPoints];
    
    NSMutableArray *normalizedDataPointValues = [NSMutableArray new];
    
    for (NSUInteger i=0; i<self.dataPoints.count; i++) {
        NSDictionary *dataPointValue = self.dataPoints[i];
        
        // Normalize container point
        CGFloat pointValue = [[dataPointValue valueForKey:kDatasetValueKey] floatValue];
        CGFloat normalizedPointValue;
        
        if (pointValue == 0){
            normalizedPointValue = canvasSize.height;
        } else if (self.minimumValue == self.maximumValue) {
            normalizedPointValue = canvasSize.height/2;
        } else {
            CGFloat range = self.maximumValue - self.minimumValue;
            CGFloat normalizedValue = (pointValue - self.minimumValue)/range * canvasSize.height;
            normalizedPointValue = canvasSize.height - normalizedValue;
        }
        
        // Normalize raw data points
        NSArray *rawDataPoints = [dataPointValue valueForKey:kDatasetRawDataPointsKey];
        NSMutableArray *normalizedRawDataPoints = [NSMutableArray new];
        for (NSDictionary *rawDataPoint in rawDataPoints) {
            CGFloat subPointValue = [[rawDataPoint valueForKey:kDatasetValueKey] floatValue];
            CGFloat normalizedSubPointValue;
            
            if (subPointValue == 0){
                normalizedSubPointValue = canvasSize.height;
            } else if (self.minimumValue == self.maximumValue) {
                normalizedSubPointValue = canvasSize.height/2;
            } else {
                CGFloat range = self.maximumValue - self.minimumValue;
                CGFloat normalizedValue = (subPointValue - self.minimumValue)/range * canvasSize.height;
                normalizedSubPointValue = canvasSize.height - normalizedValue;
            }
            
            NSMutableDictionary *mutableRawDataPoint = rawDataPoint.mutableCopy;
            mutableRawDataPoint[kDatasetValueKey] = @(normalizedSubPointValue);
            [normalizedRawDataPoints addObject:[mutableRawDataPoint copy]];
        }
        
        NSMutableDictionary *mutableDataPoint = dataPointValue.mutableCopy;
        mutableDataPoint[kDatasetValueKey] = @(normalizedPointValue);
        mutableDataPoint[kDatasetRawDataPointsKey] = normalizedRawDataPoints;
        
        [normalizedDataPointValues addObject:[mutableDataPoint copy]];
    }
    
    return [NSArray arrayWithArray:normalizedDataPointValues];
}

/* Used when the user scrubs the plot */

//Scrubbing Value
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
        value = [dataPoint[kDatasetValueKey] floatValue];
        
    }
    
    if (value == NSNotFound){
        for (positionIndex = 0; positionIndex<self.xAxisPoints.count-1; positionIndex++) {
            CGFloat xAxisPointVal = [self.xAxisPoints[positionIndex] floatValue];
            if (xAxisPointVal > xPosition) {
                break;
            }
        }
        
        NSInteger nextValidIndex = [self nextValidPositionIndexForPosition:positionIndex];
        NSInteger prevValidIndex = [self prevValidPositionIndexForPosition:positionIndex];
        
        CGFloat x1 = [self.xAxisPoints[prevValidIndex] floatValue];
        CGFloat x2 = [self.xAxisPoints[nextValidIndex] floatValue];
        
        CGFloat y1 = [[self.dataPoints[prevValidIndex] valueForKey:kDatasetValueKey] floatValue];
        CGFloat y2 = [[self.dataPoints[nextValidIndex] valueForKey:kDatasetValueKey] floatValue];
        
        CGFloat slope = (y2 - y1)/(x2 - x1);
        
        //  (y2 - y3)/(x2 - x3) = m
        value = y2 - (slope * (x2 - xPosition));
    }
    return value;
}

//Scrubber Y position
- (CGFloat)canvasYPointForXPosition:(CGFloat)xPosition
{
    CGFloat canvasYPosition;
    
    NSUInteger positionIndex;
    for (positionIndex = 0; positionIndex<self.xAxisPoints.count - 1; positionIndex++) {
        CGFloat xAxisPointVal = [self.xAxisPoints[positionIndex] floatValue];
        if (xAxisPointVal > xPosition) {
            break;
        }
    }
    
    NSInteger nextValidIndex = [self nextValidPositionIndexForPosition:positionIndex];
    NSInteger prevValidIndex = [self prevValidPositionIndexForPosition:positionIndex];
    
    CGFloat x1 = [self.xAxisPoints[prevValidIndex] floatValue];
    CGFloat x2 = [self.xAxisPoints[nextValidIndex] floatValue];
    
    CGFloat y1 = [[self.yAxisPoints[prevValidIndex] valueForKey:kDatasetValueKey] floatValue];
    CGFloat y2 = [[self.yAxisPoints[nextValidIndex] valueForKey:kDatasetValueKey] floatValue];
    
    CGFloat slope = (y2 - y1)/(x2 - x1);
    
    //  (y2 - y3)/(x2 - x3) = m
    canvasYPosition = y2 - (slope * (x2 - xPosition));
    
    return canvasYPosition;
}

//Valid - dataPoints[index]!= NSNotFound
- (NSInteger)nextValidPositionIndexForPosition:(NSInteger)positionIndex
{
    NSUInteger validPosition = positionIndex;
    
    while (validPosition < (self.dataPoints.count-1)) {
        if ([[self.dataPoints[validPosition] valueForKey:kDatasetValueKey] floatValue] != NSNotFound) {
            break;
        }
        validPosition ++;
    }
    
    return validPosition;
}

- (NSInteger)prevValidPositionIndexForPosition:(NSInteger)positionIndex
{
    NSInteger validPosition = positionIndex - 1;
    
    while (validPosition > 0) {
        if ([[self.dataPoints[validPosition] valueForKey:kDatasetValueKey] floatValue] != NSNotFound) {
            break;
        }
        validPosition --;
    }
    
    return validPosition;
}

- (CGFloat)snappedXPosition:(CGFloat)xPosition
{
    CGFloat widthBetweenPoints = CGRectGetWidth(self.plotsView.frame)/self.xAxisPoints.count;
    
    NSUInteger positionIndex;
    for (positionIndex = 0; positionIndex<self.xAxisPoints.count; positionIndex++) {
        
        CGFloat dataPointVal = [[self.dataPoints[positionIndex] valueForKey:kDatasetValueKey] floatValue];
        
        if (dataPointVal != NSNotFound) {
            CGFloat num = [self.xAxisPoints[positionIndex] floatValue];
            
            if (fabs(num - xPosition) < (widthBetweenPoints * kSnappingClosenessFactor)) {
                xPosition = num;
            }
        }
        
    }
    
    return xPosition;
}

#pragma mark - Animations

- (void)animateLayersSequentially
{
    CGFloat delay = 0.1;
    
    for (NSUInteger i=0; i<self.dots.count; i++) {
        CAShapeLayer *layer = [self.dots[i] shapeLayer];
        [self animateLayer:layer withAnimationType:kAPCGraphAnimationTypeFade toValue:1.0 startDelay:delay];
        delay += 0.1;
    }
    
    for (NSUInteger i=0; i<self.pathLines.count; i++) {
        CAShapeLayer *layer = self.pathLines[i];
        [self animateLayer:layer withAnimationType:kAPCGraphAnimationTypeGrow toValue:1.0 startDelay:delay];
        delay += kAPCGrowAnimationDuration;
    }
    
    for (NSUInteger i=0; i<self.fillLayers.count; i++) {
        CAShapeLayer *layer = self.fillLayers[i];
        [self animateLayer:layer withAnimationType:kAPCGraphAnimationTypeFade toValue:1.0 startDelay:delay];
        delay += kAPCGrowAnimationDuration;
    }
}

- (void)setScrubberViewsHidden:(BOOL)hidden animated:(BOOL)animated
{
    if ([self numberOfValidValues] > 0) {
        CGFloat alpha = hidden ? 0 : 1;
        
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.scrubberThumbView.alpha = alpha;
                self.scrubberLine.alpha = alpha;
                self.scrubberLabel.alpha = alpha;
            }];
        } else {
            self.scrubberThumbView.alpha = alpha;
            self.scrubberLine.alpha = alpha;
            self.scrubberLabel.alpha = alpha;
        }
    }
}

#pragma mark - Touch

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    
    if ((self.dataPoints.count > 0) && [self numberOfValidValues] > 0) {
        CGPoint location = [gestureRecognizer locationInView:self.plotsView];
        
        location = CGPointMake(location.x - kAPCGraphLeftPadding, location.y);
        
        CGFloat maxX = round(CGRectGetWidth(self.plotsView.bounds));
        CGFloat minX = 0;
        
        CGFloat normalizedX = MAX(MIN(location.x, maxX), minX);
        location = CGPointMake(normalizedX, location.y);
        
        //---------------
        
        CGFloat snappedXPosition = [self snappedXPosition:location.x];
        [self scrubberViewForXPosition:snappedXPosition];
        
        //---------------
        
        if ([self.delegate respondsToSelector:@selector(graphView:touchesMovedToXPosition:)]) {
            [self.delegate graphView:self touchesMovedToXPosition:snappedXPosition];
        }
        
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            
            [self setScrubberViewsHidden:NO animated:YES];
            if ([self.delegate respondsToSelector:@selector(graphViewTouchesBegan:)]) {
                [self.delegate graphViewTouchesBegan:self];
            }
        } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
            [self setScrubberViewsHidden:YES animated:YES];
            if ([self.delegate respondsToSelector:@selector(graphViewTouchesEnded:)]) {
                [self.delegate graphViewTouchesEnded:self];
            }
        }
    }
}

- (void)scrubberViewForXPosition:(CGFloat)xPosition
{
    self.scrubberLine.center = CGPointMake(xPosition + kAPCGraphLeftPadding, self.scrubberLine.center.y);
    
    CGFloat scrubbingVal = [self valueForCanvasXPosition:(xPosition)];
    self.scrubberLabel.text = [NSString stringWithFormat:@"%.0f", scrubbingVal];
    
    CGSize textSize = [self.scrubberLabel.text boundingRectWithSize:CGSizeMake(320, CGRectGetHeight(self.scrubberLabel.bounds)) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.scrubberLabel.font} context:nil].size;
    
    [self.scrubberLabel setFrame:CGRectMake(CGRectGetMaxX(self.scrubberLine.frame) + 6, CGRectGetMinY(self.scrubberLine.frame), textSize.width + 8, CGRectGetHeight(self.scrubberLabel.frame))];
    
    //---------------
    
    CGFloat scrubberYPos = [self canvasYPointForXPosition:xPosition];
    
    [self.scrubberThumbView setCenter:CGPointMake(xPosition + kAPCGraphLeftPadding, scrubberYPos + kAPCGraphTopPadding)];
    
    if (scrubbingVal >= self.minimumValue && scrubbingVal <= self.maximumValue) {
        self.scrubberLabel.alpha = 1;
        self.scrubberThumbView.alpha = 1;
    } else {
        self.scrubberLabel.alpha = 0;
        self.scrubberThumbView.alpha = 0;
    }
}

#pragma mark - Public Methods

- (void)scrubReferenceLineForXPosition:(CGFloat)xPosition
{
    if (self.dataPoints.count > 1) {
        [self scrubberViewForXPosition:xPosition];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPCLineGraphViewTriggerAnimationsNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPCLineGraphViewRefreshNotification object:nil];
}


@end
