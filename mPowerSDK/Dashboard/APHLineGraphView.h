//
//  APHLineGraphView.h
//  mPowerSDK
//
//  Created by Andy Yeung on 3/2/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHLineGraphView : APCLineGraphView

@property (nonatomic) UIColor *colorForFirstCorrelationLine;
@property (nonatomic) UIColor *colorForSecondCorrelationLine;

@property (nonatomic) BOOL shouldDrawLastPoint;

@end
