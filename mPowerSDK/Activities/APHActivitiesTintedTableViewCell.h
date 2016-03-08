//
//  APHActivitiesTintedTableViewCell.h
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHActivitiesTintedTableViewCell : APCActivitiesTintedTableViewCell

@property(weak, nonatomic) IBOutlet UILabel *cyclesRemainingLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelLeadingConstraint;

@end
