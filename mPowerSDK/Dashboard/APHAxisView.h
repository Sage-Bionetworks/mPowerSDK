//
//  APHAxisView.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHAxisView : APCAxisView

@property (nonatomic) BOOL hasSecondaryYAxis;
@property (nonatomic) CGFloat secondaryYAxisHorizontalOffset;
@property (nonatomic) UIColor *lastTitleHighlightColor;

@end
