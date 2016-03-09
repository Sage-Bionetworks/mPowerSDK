//
//  APHCircleView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHCircleView.h"

@implementation APHCircleView

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    
    self.shapeLayer.fillColor = tintColor.CGColor;
}

@end
