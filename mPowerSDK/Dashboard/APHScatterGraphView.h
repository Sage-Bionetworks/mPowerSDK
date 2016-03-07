//
//  APHScatterGraphView.h
//  APCAppCore
//
//  Created by Jake Krog on 2016-03-01.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

@import APCAppCore;

@protocol APHScatterGraphViewDataSource;

@interface APHScatterGraphView : APCBaseGraphView

@property (weak, nonatomic) id <APHScatterGraphViewDataSource> dataSource;

@end

@protocol APHScatterGraphViewDataSource <NSObject>

@required

- (NSInteger)scatterGraph:(APHScatterGraphView *)graphView numberOfPointsInPlot:(NSInteger)plotIndex;

- (NSDictionary *)scatterGraph:(APHScatterGraphView *)graphView plot:(NSInteger)plotIndex valueForPointAtIndex:(NSInteger)pointIndex;

@optional

- (NSInteger)numberOfPlotsInScatterGraph:(APHScatterGraphView *)graphView;

- (NSInteger)numberOfDivisionsInXAxisForGraph:(APHScatterGraphView *)graphView;

- (CGFloat)maximumValueForScatterGraph:(APHScatterGraphView *)graphView;

- (CGFloat)minimumValueForScatterGraph:(APHScatterGraphView *)graphView;

- (NSString *)scatterGraph:(APHScatterGraphView *)graphView titleForXAxisAtIndex:(NSInteger)pointIndex;

@end
