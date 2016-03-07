//
//  APHScoring.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-28.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import "APHDiscreteGraphView.h"
#import "APHScatterGraphView.h"
#import "APHSparkGraphView.h"

@interface APHScoring : APCScoring <APHDiscreteGraphViewDataSource, APHScatterGraphViewDataSource, APHSparkGraphViewDataSource>

@property(nonatomic) NSArray *activityTimingChoicesStrings;
@property(nonatomic) BOOL latestOnly;
@property(nonatomic) BOOL providesExpandedScatterPlotData;

- (void)changeDataPointsWithTaskChoice:(NSString *)taskChoice;
- (void)resetChanges;

@end
