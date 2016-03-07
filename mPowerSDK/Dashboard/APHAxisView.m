//
//  APHAxisView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHAxisView.h"

@interface APCAxisView (Private)
@property (nonatomic, strong) NSMutableArray *titleLabels;
@end

@implementation APHAxisView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.shouldHighlightLastLabel) {
        UILabel *lastTitleLabel = self.titleLabels.lastObject;
        lastTitleLabel.backgroundColor = self.lastTitleHighlightColor;
    }
}

@end
