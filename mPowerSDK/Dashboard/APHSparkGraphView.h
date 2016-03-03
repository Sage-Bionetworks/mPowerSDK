//
//  APHSparkGraphView.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-03.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@protocol APHSparkGraphViewDataSource;

@interface APHSparkGraphView : APCBaseGraphView

@property (nonatomic, weak) IBOutlet id <APHSparkGraphViewDataSource> datasource;

@property (nonatomic, strong) UIView *plotsView;
@property (nonatomic) BOOL smoothLines;
@property (nonatomic) BOOL showsFillPath;

@end

@protocol APHSparkGraphViewDataSource <NSObject>

@required

- (NSInteger)sparkGraph:(APHSparkGraphView *)graphView numberOfPointsInPlot:(NSInteger)plotIndex;

- (NSDictionary *)sparkGraph:(APHSparkGraphView *)graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger)pointIndex;

@optional

- (NSInteger)numberOfPlotsInSparkGraph:(APHSparkGraphView *)graphView;

- (NSInteger)numberOfDivisionsInXAxisForSparkGraph:(APHSparkGraphView *)graphView;

- (CGFloat)maximumValueForSparkGraph:(APHSparkGraphView *)graphView;

- (CGFloat)minimumValueForSparkGraph:(APHSparkGraphView *)graphView;

- (NSString *)sparkGraph:(APHSparkGraphView *)graphView titleForXAxisAtIndex:(NSInteger)pointIndex;

@end