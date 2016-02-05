//
//  APHActivitiesSectionHeaderView.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHActivitiesSectionHeaderView.h"

void *BackgroundImageContext = &BackgroundImageContext;

@interface APCActivitiesSectionHeaderView ()

- (void)setupAppearance;

@end

@implementation APHActivitiesSectionHeaderView

- (void)awakeFromNib {
	[self.backgroundImageView addObserver:self
							   forKeyPath:@"image"
								  options:NSKeyValueObservingOptionNew
								  context:BackgroundImageContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == BackgroundImageContext) {
		[self setupAppearance];
	} else {
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

- (void)setupAppearance {
	[super setupAppearance];

	if (self.backgroundImageView.image != nil) {
		self.titleLabel.textColor = [UIColor whiteColor];
		self.subTitleLabel.textColor = [UIColor whiteColor];
		self.titleLabel.font = [UIFont appLightFontWithSize:20.f];
		self.subTitleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	} else {
		self.titleLabel.font = [UIFont boldSystemFontOfSize:14.f];
	}
}

@end
