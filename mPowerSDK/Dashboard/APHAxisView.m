//
//  APHAxisView.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-06.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHAxisView.h"

@interface APCAxisView (Private)

@property (nonatomic) APCGraphAxisType axisType;
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

	if (self.hasSecondaryYAxis) {
		CGFloat segmentWidth = (CGFloat) CGRectGetWidth(self.bounds) / (self.titleLabels.count);
		CGFloat labelWidth = segmentWidth;
		CGFloat labelHeight = (self.axisType == kAPCGraphAxisTypeX) ? CGRectGetHeight(self.bounds) * 0.77 : 20;

		for (NSUInteger i = 0; i < self.titleLabels.count; i++) {
			CGFloat positionX = (self.axisType == kAPCGraphAxisTypeX) ? (self.leftOffset + (i + 1) * segmentWidth) : 0;

			if (i == 0) {
				//Shift the first label to acoomodate the month text.
				positionX -= self.leftOffset;
			}

			UILabel *label = (UILabel *) self.titleLabels[i];

			if (label.text) {
				labelWidth = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, labelHeight)
													  options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin)
												   attributes:@{NSFontAttributeName : label.font}
													  context:nil].size.width;
				labelWidth = MAX(labelWidth, 15);
				labelWidth += self.landscapeMode ? 14 : 8; //padding
			}

			if (i == 0) {
				label.frame = CGRectMake(positionX, (CGRectGetHeight(self.bounds) - labelHeight) / 2, labelWidth, labelHeight);
			} else {
				label.frame = CGRectMake(positionX - labelWidth / 2, (CGRectGetHeight(self.bounds) - labelHeight) / 2, labelWidth, labelHeight);
			}

			if (i == self.titleLabels.count - 1 && self.shouldHighlightLastLabel) {
				//Last label

				label.textColor = [UIColor whiteColor];
				label.backgroundColor = self.tintColor;
				label.layer.cornerRadius = CGRectGetHeight(label.frame) / 2;
				label.layer.masksToBounds = YES;
			}
		}
	}
}

@end
