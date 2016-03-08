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

@property (nonatomic) BOOL hideTintBar;
@property (nonatomic) BOOL showCorrelationSelectorView;
@property (nonatomic) BOOL showCorrelationSegmentControl;
@property (nonatomic) BOOL showMedicationLegend;
@property (nonatomic) BOOL showMedicationLegendCorrelation;
@property (nonatomic) BOOL showSparkLineGraph;

+(NSAttributedString *)legendForSeries1:(NSString *)series1
								series2:(NSString *)series2
						colorForSeries1:(UIColor *)color1
						colorForSeries2:(UIColor *)color2;

@end
