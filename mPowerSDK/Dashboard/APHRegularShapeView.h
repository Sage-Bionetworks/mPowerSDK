//
//  APHRegularShapeView.h
//  APCAppCore
//
//  Created by Everest Liu on 2/27/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface APHRegularShapeView : UIView

@property(nonatomic) UIColor *tintColor;
@property(nonatomic) UIColor *fillColor;
@property(nonatomic) int numberOfSides;
@property(nonatomic) CGFloat value;

- (instancetype)initWithFrame:(CGRect)frame andNumberOfSides:(int)sides;
- (CAShapeLayer *)shapeLayer;

@end
