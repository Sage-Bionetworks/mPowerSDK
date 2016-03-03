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

- (NSString *)titleForHeaderInSection:(NSUInteger)sectionNumber
{
    APCActivitiesViewSection *section = [self sectionForSectionNumber:sectionNumber];
    
    if ([section isKeepGoingSection]) {
        return [NSLocalizedStringWithDefaultValue(@"APH_ACTIVITIES_KEEP_GOING_HEADER_TITLE",
                                                  nil,
                                                  APHLocaleBundle(),
                                                  @"Additional Activities",
                                                  @"Title for 'Keep Going' section header in activities list") uppercaseString];
    } else if ([section isTodaySection]) {
        return section.title;
    }

    return [section.title uppercaseString];
}

- (NSString *)subtitleForHeaderInSection:(NSUInteger)sectionNumber
{
    APCActivitiesViewSection *section = [self sectionForSectionNumber:sectionNumber];
    
    if ([section isKeepGoingSection]) {
        return NSLocalizedStringWithDefaultValue(@"APH_ACTIVITIES_KEEP_GOING_HEADER_SUBTITLE",
                                                 nil,
                                                 APHLocaleBundle(),
                                                 @"Try one of these extra activities to enhance your study experience.",
                                                 @"Subtitle for 'Keep Going' section header in activities list");
    } else if ([section isYesterdaySection]) {
        return NSLocalizedStringWithDefaultValue(@"APH_ACTIVITIES_YESTERDAY_HEADER_SUBTITLE",
                                                 nil,
                                                 APHLocaleBundle(),
                                                 @"Below are your incomplete tasks from yesterday. For your reference only.",
                                                 @"Subtitle for 'Yesterday' section header in activities list");
    }
    
    return section.subtitle;
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
    headerView.titleLabel.text = [self titleForHeaderInSection:sectionNumber];
	headerView.subTitleLabel.text = [self subtitleForHeaderInSection:sectionNumber];

	return headerView;
}

@end
