//
//  APHScatterGraphView.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-01.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@protocol APHScatterGraphViewDelegate;

@interface APHScatterGraphView : APCDiscreteGraphView

@property (weak, nonatomic) id <APHScatterGraphViewDelegate> scatterGraphDelegate;

@end

@protocol APHScatterGraphViewDelegate <NSObject>
@optional

- (NSDictionary *)scatterGraph:(APHScatterGraphView *)graphView plot:(NSInteger)plotIndex valuesForPointsAtIndex:(NSInteger)pointIndex;

@end
