//
//  APHRegularShapeView.m
//  APCAppCore
//
//  Created by Everest Liu on 2/27/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHRegularShapeView.h"

@implementation APHRegularShapeView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    // default to a circle
    return [self initWithFrame:frame andNumberOfSides:0];
}

- (instancetype)initWithFrame:(CGRect)frame andNumberOfSides:(int)sides {
	if (self = [super initWithFrame:frame]) {
		_numberOfSides = sides;
		[self setupPolygon];
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[self setupPolygon];
	}
	return self;
}

- (void)setupPolygon {
	self.backgroundColor = [UIColor clearColor];
    _fillColor = [UIColor clearColor];
}

#pragma mark - Polygon Methods

- (UIBezierPath *)layoutPath {
	CGPoint origin = CGPointMake(CGRectGetWidth(self.frame) / 2.f, CGRectGetHeight(self.frame) / 2.f);
	CGFloat radius = CGRectGetWidth(self.frame) / 4;

	UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
	if (self.numberOfSides > 0) {
		CGFloat angle = (CGFloat) (M_PI * (2.f / self.numberOfSides));
		NSMutableArray *points = [[NSMutableArray alloc] init];
		for (int i = 0; i <= self.numberOfSides; i++) {
			CGFloat xpo = (CGFloat) (origin.x + radius * cos(angle * i));
			CGFloat ypo = (CGFloat) (origin.y + radius * sin(angle * i));
			[points addObject:[NSValue valueWithCGPoint:CGPointMake(xpo, ypo)]];
		}

		NSValue *initialPoint = (NSValue *) points[0];
		CGPoint cpg = initialPoint.CGPointValue;
		[bezierPath moveToPoint:cpg];
		for (NSValue *pointValue in points) {
			CGPoint point = pointValue.CGPointValue;
			[bezierPath addLineToPoint:point];
		}

		[bezierPath closePath];
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];
		[bezierPath applyTransform:CGAffineTransformMakeRotation((CGFloat) (M_PI / 2 - M_PI / self.numberOfSides))];
		[bezierPath applyTransform:CGAffineTransformMakeTranslation(origin.x, origin.y)];

	} else {
		bezierPath = [UIBezierPath bezierPathWithArcCenter:origin
													radius:radius * 0.8f
												startAngle:0
												  endAngle:(CGFloat) (2 * M_PI)
												 clockwise:YES];
	}

	return bezierPath;
}

#pragma mark - other

+ (Class)layerClass {
	return CAShapeLayer.class;
}

- (CAShapeLayer *)shapeLayer {
	return (CAShapeLayer *) self.layer;
}

- (void)layoutSubviews {
	[super layoutSubviews];

    self.shapeLayer.lineWidth = 2.f;
    self.shapeLayer.strokeColor = self.tintColor.CGColor;
    self.shapeLayer.fillColor = self.fillColor.CGColor;
	self.shapeLayer.path = [self layoutPath].CGPath;
}

#pragma mark - Setter methods

- (void)tintColorDidChange {
	self.shapeLayer.strokeColor = self.tintColor.CGColor;
}

- (void)setFillColor:(UIColor *)fillColor {
	_fillColor = fillColor;
    [self fillColorDidChange];
}

- (void)fillColorDidChange {
	self.shapeLayer.fillColor = self.fillColor.CGColor;
}

@end
