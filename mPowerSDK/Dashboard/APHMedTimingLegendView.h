//
//  APHMedTimingLegendView.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APHMedTimingLegendView : UIView

+ (CGFloat)defaultHeight;

@property (nonatomic) BOOL showCorrelationLegend;
@property (nonatomic) BOOL showExpandedView;
@property (nonatomic) UIColor *secondaryTintColor;

@end
