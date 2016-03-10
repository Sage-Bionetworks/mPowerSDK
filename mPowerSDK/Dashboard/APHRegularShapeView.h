//
//  APHRegularShapeView.h
//  APCAppCore
//
//  Created by Everest Liu on 2/27/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface APHRegularShapeView : UIView

@property(nonatomic) IBInspectable UIColor *fillColor;
@property(nonatomic) IBInspectable int numberOfSides;

@property(nonatomic) CGFloat value;

- (instancetype)initWithFrame:(CGRect)frame andNumberOfSides:(int)sides;
- (CAShapeLayer *)shapeLayer;

@end
