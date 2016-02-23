//
//  APHStudyLandingCollectionViewCell.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/23/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHStudyLandingCollectionViewCell.h"

@interface APCStudyLandingCollectionViewCell ()

- (void)setupAppearance;

@end

@implementation APHStudyLandingCollectionViewCell

- (void)setupAppearance {
	[super setupAppearance];

	self.logoImageView.image = [UIImage imageNamed:@"logo_backdrop"];
	self.titleLabel.font = [UIFont appThinFontWithSize:28.f];
	self.subTitleLabel.font = [UIFont appMediumFontWithSize:14.f];
	self.swipeLabel.font = [UIFont appMediumFontWithSize:12.f];
	self.swipeLabel.textColor = [UIColor blackColor];
}

@end
