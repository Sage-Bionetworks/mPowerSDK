//
//  APHScoring.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-28.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import "APHScatterGraphView.h"
#import "APHSparkGraphView.h"

@interface APHScoring : APCScoring <APHScatterGraphViewDataSource, APHSparkGraphViewDataSource>

@property(nonatomic) BOOL latestOnly;

- (NSArray<NSString *> *)medTrackerTaskChoices;
- (void)changeDataPointsWithTaskChoice:(NSString *)taskChoice;

@end
