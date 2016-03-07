//
//  APHStudyVideoCollectionViewCell.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/23/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHStudyVideoCollectionViewCell.h"

@interface APCStudyVideoCollectionViewCell ()

- (void)setupAppearance;

@end

@implementation APHStudyVideoCollectionViewCell

- (void)setupAppearance {
	[super setupAppearance];

	[self.videoButton setImage:[[UIImage imageNamed:@"play_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
					  forState:UIControlStateNormal];
}

@end
