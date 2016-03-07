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
@end

@interface APHDiscreteGraphView : APCDiscreteGraphView

@property (nonatomic) UIColor *primaryLineColor;
@property (nonatomic) UIColor *secondaryLineColor;

@property (nonatomic, weak) id <APHDiscreteGraphViewDataSource> datasource;

@end


