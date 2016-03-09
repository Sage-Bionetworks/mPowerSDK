//
//  APHScoring.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-28.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import "APHDiscreteGraphView.h"
#import "APHSparkGraphView.h"

@interface APHScoring : APCScoring <APHDiscreteGraphViewDataSource, APHSparkGraphViewDataSource>

@property(nonatomic) NSArray *activityTimingChoicesStrings;
@property(nonatomic) BOOL latestOnly;
@property(nonatomic) BOOL providesAveragedPointData;
@property(nonatomic) BOOL shouldDiscardIncongruentCorrelationElements;

- (void)changeDataPointsWithTaskChoice:(NSString *)taskChoice;
- (void)resetChanges;

@end
