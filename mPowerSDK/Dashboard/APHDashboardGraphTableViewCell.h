//
//  APHDashboardGraphTableViewCell.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@class APHScatterGraphView;

@interface APHDashboardGraphTableViewCell : APCDashboardGraphTableViewCell

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *tintViews;
@property (weak, nonatomic) IBOutlet APHScatterGraphView *scatterGraphView;

@property (nonatomic) BOOL showMedicationLegend;

+ (CGFloat)medicationLegendContainerHeight;

@end