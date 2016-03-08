//
//  APHActivitiesViewController.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHActivitiesViewController.h"
#import "APHLocalization.h"

@interface APCActivitiesViewController ()

@property(nonatomic, strong) IBOutlet UITableView *tableView;

- (APCActivitiesViewSection *)sectionForSectionNumber:(NSUInteger)sectionNumber;

@end

@implementation APHActivitiesViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	NSString *headerViewNibName = NSStringFromClass([APHActivitiesSectionHeaderView class]);
	UINib *nib = [UINib nibWithNibName:headerViewNibName bundle:[NSBundle bundleForClass:[self class]]];
	[self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:headerViewNibName];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionNumber {
	NSString *headerViewIdentifier = NSStringFromClass([APHActivitiesSectionHeaderView class]);
	APHActivitiesSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];

	if (sectionNumber == 0) {
		headerView.backgroundImageView.image = [UIImage imageNamed:@"Activity_Panel_Background"
														  inBundle:[NSBundle bundleForClass:[self class]]
									 compatibleWithTraitCollection:nil];
		headerView.titleLabel.textAlignment = NSTextAlignmentCenter;
		headerView.subTitleLabel.textAlignment = NSTextAlignmentCenter;
	} else {
		headerView.backgroundImageView.image = nil;
		headerView.titleLabel.textAlignment = NSTextAlignmentLeft;
		headerView.subTitleLabel.textAlignment = NSTextAlignmentLeft;
	}

	[headerView removeConstraint:headerView.titleLabelTopConstraint];
	headerView.titleLabelTopConstraint = [NSLayoutConstraint constraintWithItem:headerView.titleLabel
																	  attribute:NSLayoutAttributeTop
																	  relatedBy:NSLayoutRelationEqual
																		 toItem:headerView
																	  attribute:NSLayoutAttributeTop
																	 multiplier:1
																	   constant:sectionNumber == 0 ? 18 : 10];

	[headerView addConstraint:headerView.titleLabelTopConstraint];

	return headerView;
}

@end
