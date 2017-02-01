//
//  APHSettingsViewController.m
//  mPowerSDK
//
//  Created by Josh Bruhin on 1/25/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

#import "APHSettingsViewController.h"

@interface APCSettingsViewController ()
- (void)prepareContent;
@end

@interface APHSettingsViewController ()

@end

@implementation APHSettingsViewController

- (void)prepareContent {
    
    /*
     overriding here to define content to only include the "enable reminders" on/off switch
     as per https://sagebionetworks.jira.com/browse/BRIDGE-1660
     */
    
    NSMutableArray *items = [NSMutableArray new];
    APCAppDelegate * appDelegate = (APCAppDelegate*) [UIApplication sharedApplication].delegate;
    BOOL reminderOnState = appDelegate.tasksReminder.reminderOn;
    
    {
        
        NSMutableArray *rowItems = [NSMutableArray new];
        
        {
            APCTableViewSwitchItem *field = [APCTableViewSwitchItem new];
            field.caption = NSLocalizedStringWithDefaultValue(@"Enable Reminders", @"APCAppCore", APCBundle(), @"Enable Reminders", nil);
            field.reuseIdentifier = kAPCSwitchCellIdentifier;
            field.editable = NO;
            
            field.on = reminderOnState;
            
            APCTableViewRow *row = [APCTableViewRow new];
            row.item = field;
            row.itemType = kAPCSettingsItemTypeReminderOnOff;
            [rowItems addObject:row];
        }
        
        APCTableViewSection *section = [APCTableViewSection new];
        section.sectionTitle = @"";
        section.rows = [NSArray arrayWithArray:rowItems];
        [items addObject:section];
    }
    
    self.items = items;
}

@end
