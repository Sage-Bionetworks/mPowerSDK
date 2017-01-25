//
//  APHTasksReminderManager.m
//  mPowerSDK
//
//  Created by Josh Bruhin on 1/24/17.
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//

#import "APHTasksReminderManager.h"

@interface APCTasksReminderManager ()
- (void) cancelLocalNotificationsIfExist;
- (void) addNotificationCategoryIfNeeded;
@end

@implementation APHTasksReminderManager

- (void)updateTasksReminder {
    
    /*
     As per: https://sagebionetworks.jira.com/browse/BRIDGE-1660
     Have tasks be continually available to run at anytime and message to people to do them 1 time a day instead of 3 or 4.
     Instead of scheduling reminders, have app randomly pick a time during the day to remind people to do their activities
     if they have not already done tasks that day.
     
     - Should only remind them if they haven't done them yet today
     - Reminder should randomly come in the periods that aren't marked as sleeping time
     */
    
    
    [self cancelLocalNotificationsIfExist];

    if (self.reminderOn) {
        
        // We first must fetch tasks to see if any have been done today as we don't want to send
        // a notification today if one or more have.
        
        NSDate *today = [NSDate date];
        NSDate *yesterday = today.dayBefore;
        
        // creating and using a filter here eventhough we don't need one because we're looking for all
        // the tasks. But, the fetch method in APCScheduler that does not require a filter is crashing
        // because filter is nil, so it seem there's a bug there
        
        NSPredicate *filterForallTasks = [NSPredicate predicateWithFormat: @"%K == nil || %K == %@ || %K == %@",
                                          NSStringFromSelector(@selector(taskIsOptional)),
                                          NSStringFromSelector(@selector(taskIsOptional)),
                                          @(NO),
                                          NSStringFromSelector(@selector(taskIsOptional)),
                                          @(YES)];

        [[APCScheduler defaultScheduler] fetchTaskGroupsFromDate: yesterday
                                                          toDate: today
                                          forTasksMatchingFilter: filterForallTasks
                                                      usingQueue: [NSOperationQueue mainQueue]
                                                 toReportResults: ^(NSDictionary *taskGroups, NSError * __unused queryError)
         {
             NSArray *actualTaskGroups = taskGroups.allValues.firstObject;
             if (actualTaskGroups.count > 0) {
                 
                 BOOL includeToday = YES;
                 for (APCTaskGroup *taskGroup in actualTaskGroups) {
                     if ([taskGroup.dateFullyCompleted.dayBefore isEqualToDate:[NSDate date].dayBefore]) {
                         // same day
                         includeToday = NO;
                         break;
                     }
                 }
                 
                 [self scheduleDailyRandomReminderIncludeToday:includeToday];
             }
         }];  // first fetch:  required tasks, for a range of dates
    }
}

- (void)scheduleDailyRandomReminderIncludeToday:(BOOL)includeToday {
    
    // Schedule the Task notification
    UILocalNotification* taskNotification = [[UILocalNotification alloc] init];
    taskNotification.alertBody = gTaskReminderMessage;
    
    NSDate* normalFireDate = [self randomDailyFireDate];
    
    // if the fire date is within an hour of current time, then skip for today
    NSDate *hourFromNow = [[NSDate date] dateByAddingTimeInterval:[self oneMoreHour]];
    if ([normalFireDate isEarlierThanDate:hourFromNow]) {
        includeToday = NO;
    }
    
    normalFireDate = includeToday ? normalFireDate : [normalFireDate dateByAddingTimeInterval:[self oneMoreDay]];
    
    taskNotification.fireDate = normalFireDate;
    taskNotification.repeatInterval = NSCalendarUnitDay;
    taskNotification.timeZone = [NSTimeZone localTimeZone];
    taskNotification.soundName = UILocalNotificationDefaultSoundName;
    
    NSMutableDictionary *notificationInfo = [[NSMutableDictionary alloc] init];
    notificationInfo[kTaskReminderUserInfoKey] = kTaskReminderUserInfo; // Task Reminder
    
    taskNotification.userInfo = notificationInfo;
    taskNotification.category = kTaskReminderDelayCategory;
    
    //migration if notifications were registered without a category.
    [self addNotificationCategoryIfNeeded];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:taskNotification];
    
    APCLogEventWithData(kSchedulerEvent, (@{@"event_detail":[NSString stringWithFormat:@"Scheduled Reminder: %@. Body: %@", taskNotification, taskNotification.alertBody]}));
}



- (NSDate*)randomDailyFireDate {
    
    /*
     Get random time between user's wake time and sleep time, add that to the current date
     and schedule the repeating notifiction. Intentionally NOT checking for the case that
     the random time used occurs before the current time today. If the time IS before current time,
     rationale is that user is already in the app today so probably ok that they won't get
     a notification later today. If the random time is after current time, the user will get a
     notification later today.
     */
    
    APCAppDelegate *appDelegate = (APCAppDelegate *)[UIApplication sharedApplication].delegate;
    APCUser  *user = appDelegate.dataSubstrate.currentUser;
    
    // first get random date from sleep and wake times, we want the time components
    NSTimeInterval window = [user.sleepTime timeIntervalSinceDate:user.wakeUpTime];
    NSTimeInterval randomOffset = drand48() * window;
    NSDate *randomTime = [user.wakeUpTime dateByAddingTimeInterval:randomOffset];

    // make date for today with random time
    NSDateComponents *randomTimeComponents = [[NSCalendar currentCalendar]
                                              components:(NSCalendarUnitHour|NSCalendarUnitMinute)
                                              fromDate:randomTime];
    
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar]
                                         components:(NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear)
                                         fromDate:[NSDate date]];
    
    [todayComponents setHour:randomTimeComponents.hour];
    [todayComponents setMinute:randomTimeComponents.minute];
    
    return [[NSCalendar currentCalendar] dateFromComponents:todayComponents];
}

- (NSTimeInterval)oneMoreDay {
    return (NSTimeInterval)60*60*24;
}

- (NSTimeInterval)oneMoreHour {
    return (NSTimeInterval)60*60;
}


@end
