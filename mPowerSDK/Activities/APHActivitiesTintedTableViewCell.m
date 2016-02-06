//
//  APHActivitiesTintedTableViewCell.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "APHActivitiesTintedTableViewCell.h"

@interface APCActivitiesTintedTableViewCell ()
@property (nonatomic, weak) IBOutlet APCBadgeLabel *countLabel;
@end

@implementation APHActivitiesTintedTableViewCell

- (void)configureWithTaskGroup:(APCTaskGroup *)taskGroup
				   isTodayCell:(BOOL)cellRepresentsToday
			 showDebuggingInfo:(BOOL)shouldShowDebuggingInfo {
	[super configureWithTaskGroup:taskGroup
					  isTodayCell:cellRepresentsToday
				showDebuggingInfo:shouldShowDebuggingInfo];

	self.titleLabel.textColor =
		cellRepresentsToday && !taskGroup.isFullyCompleted || taskGroup.task.taskIsOptional.boolValue ?
			[UIColor appSecondaryColor1] : [UIColor appSecondaryColor3];

	if (cellRepresentsToday) {
		self.confirmationView.completedBackgroundColor = [UIColor colorWithRed:0.39 green:0.76 blue:0.46 alpha:1];
		self.confirmationView.hidden = NO;

		self.countLabel.hidden = self.cyclesRemainingLabel.hidden = !(taskGroup.totalRequiredTasksForThisTimeRange > 1 && !taskGroup.isFullyCompleted);
	} else {
		self.confirmationView.hidden = self.countLabel.hidden = self.cyclesRemainingLabel.hidden = YES;
	}

	[self removeConstraint:self.titleLabelLeadingConstraint];
	self.titleLabelLeadingConstraint = [NSLayoutConstraint constraintWithItem:self.titleLabel
																	  attribute:NSLayoutAttributeLeading
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:self
																	  attribute:NSLayoutAttributeLeadingMargin
																	 multiplier:1
																	   constant:cellRepresentsToday ? 36 : 8];

	[self addConstraint:self.titleLabelLeadingConstraint];
}

// Using runtime manipluation to prevent drawing in APCActivitiesTintedTableViewCell
- (void)drawRect:(CGRect)rect {
	Class class = [[self superclass] superclass];
	IMP classImp = class_getMethodImplementation(class, _cmd);
	classImp();
}

@end
