//
//  APHDiscreteGraphView.h
//  mPowerSDK
//
//  Created by Andy Yeung on 3/2/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@class APHDiscreteGraphView;

@protocol APHDiscreteGraphViewDataSource <APCDiscreteGraphViewDataSource>
@optional
- (NSDictionary *)discreteGraph:(APHDiscreteGraphView *)graphView plot:(NSInteger)plotIndex dictionaryValueForPointAtIndex:(NSInteger)pointIndex;
- (NSArray<NSNumber *> *)maximumValuesForDiscreteGraph:(APCDiscreteGraphView *)graphView;
- (NSArray<NSNumber *> *)minimumValuesForDiscreteGraph:(APCDiscreteGraphView *)graphView;
@end

@interface APHDiscreteGraphView : APCDiscreteGraphView

@property (nonatomic) UIColor *primaryLineColor;
@property (nonatomic) UIColor *secondaryLineColor;

@property (nonatomic, weak) id <APHDiscreteGraphViewDataSource> datasource;

@end


