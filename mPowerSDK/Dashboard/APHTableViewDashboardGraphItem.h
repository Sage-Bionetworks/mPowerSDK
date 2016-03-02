//
//  APHTableViewDashboardGraphItem.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-01.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

typedef NS_ENUM(NSUInteger, APHDashboardGraphType) {
    kAPHDashboardGraphTypeLine = kAPCDashboardGraphTypeLine,
    kAPHDashboardGraphTypeDiscrete = kAPCDashboardGraphTypeDiscrete,
    kAPHDashboardGraphTypeScatter,
};

@interface APHTableViewDashboardGraphItem : APCTableViewDashboardGraphItem

@property (nonatomic) BOOL showMedicationLegend;
@property (nonatomic) BOOL showCorrelationSelectorView;

@end
