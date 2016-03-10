//
//  APHRegularShapeView.m
//  APCAppCore
//
// Copyright (c) 2015, Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
