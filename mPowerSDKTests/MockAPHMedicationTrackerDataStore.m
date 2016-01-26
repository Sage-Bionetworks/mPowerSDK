//
//  MockAPHMedicationTrackerDataStore.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/21/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPHMedicationTrackerDataStore.h"

@implementation MockAPHMedicationTrackerDataStore

- (instancetype)init {
    return [self initWithUserDefaultsWithSuiteName:[[NSUUID UUID] UUIDString]];
}

- (NSDate *)lastCompletionDate {
    // Override the drop thru to look at the current user
    return self.mockLastCompletionDate;
}

- (void)setLastCompletionDate:(NSDate *)lastCompletionDate {
    self.mockLastCompletionDate = lastCompletionDate;
}

@end
