//
//  APHActivitiesViewController.m
//  mPowerSDK
//
//  Created by Everest Liu on 2/4/16.
//  Copyright © 2016 Thread, Inc. All rights reserved.
//

#import "APHActivitiesViewController.h"

static NSString *const kAPCSectionTitleKeepGoing = @"Additional Activities";
static NSString *const kAPCSectionSubtitleKeepGoing = @"Try one of these extra activities to enhance your study experience.";
static NSString *const kAPCSectionSubtitleYesterday = @"Below are your incomplete tasks from yesterday. For your reference only.";

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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionNumber {
	NSString *headerViewIdentifier = NSStringFromClass([APHActivitiesSectionHeaderView class]);
	APHActivitiesSectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewIdentifier];
	APCActivitiesViewSection *section = [self sectionForSectionNumber:sectionNumber];

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

	if ([section isKeepGoingSection]) {

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

	headerView.titleLabel.text = [section isKeepGoingSection] ? [kAPCSectionTitleKeepGoing uppercaseString] : [section isTodaySection] ? section.title : [section.title uppercaseString];
	headerView.subTitleLabel.text = [section isKeepGoingSection] ? kAPCSectionSubtitleKeepGoing : [section isYesterdaySection] ? kAPCSectionSubtitleYesterday : section.subtitle;

	return headerView;
}

@end
