//
//  APHActivitiesSectionHeaderView.h
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHActivitiesSectionHeaderView : APCActivitiesSectionHeaderView

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;

@end
