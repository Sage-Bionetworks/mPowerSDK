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

- (instancetype)initWithUserDefaultsWithSuiteName:(NSString *)suiteName {
    if ((self = [super initWithUserDefaultsWithSuiteName:suiteName])) {
        _mockDataGroupsManager = [MockAPCDataGroupsManager new];
        self.dataGroupsManager = _mockDataGroupsManager;
        _mockUser = [MockAPCUser new];
        self.user = _mockUser;
    }
    return self;
}

- (NSDate *)lastCompletionDate {
    // Override the drop thru to look at the current user
    return self.mockLastCompletionDate;
}

- (void)setLastCompletionDate:(NSDate *)lastCompletionDate {
    self.mockLastCompletionDate = lastCompletionDate;
}

@end
