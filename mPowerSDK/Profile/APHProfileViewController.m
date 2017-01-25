//
//  APHProfileViewController.m
//  mPowerSDK
//
//  Created by Josh Bruhin on 1/25/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

#import "APHProfileViewController.h"
#import "APHSettingsViewController.h"

@interface APHProfileViewController ()

@end

@implementation APHProfileViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    /*
     Overriding here so we can provide our custom subclass for APCSettingsViewController, which is used to set
     reminder settings, which is being modified as per https://sagebionetworks.jira.com/browse/BRIDGE-1660
     */

    if ((NSUInteger)indexPath.section >= self.items.count) {
        
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        
    }
    else {
        
        APCTableViewItemType type = [self itemTypeForIndexPath:indexPath];
        switch (type) {
            case kAPCSettingsItemTypeReminderOnOff:
            {
                if (!self.isEditing){
                    APHSettingsViewController *remindersTableViewController = [[UIStoryboard storyboardWithName:@"APHProfile" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:@"APHSettingsViewController"];
                    [self.navigationController pushViewController:remindersTableViewController animated:YES];
                } else {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                
            }
                break;
                
            default:{
                
                [super tableView:tableView didSelectRowAtIndexPath:indexPath];
            }
                break;
        }
    }
}


@end
