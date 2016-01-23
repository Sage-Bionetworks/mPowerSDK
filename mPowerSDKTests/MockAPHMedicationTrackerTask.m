//
//  MockAPHMedicationTrackerTask.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPHMedicationTrackerTask.h"

@implementation MockAPHMedicationTrackerTask

+ (NSString*)pathForDefaultMapping {
    NSBundle *bundle = [NSBundle bundleForClass:[APHMedicationTrackerTask class]];
    return [bundle pathForResource:@"MedicationTracking" ofType:@"json"];
}

- (MockAPHMedicationTrackerDataStore *)mockDataStore {
    if (_mockDataStore == nil) {
        _mockDataStore = [MockAPHMedicationTrackerDataStore new];
    }
    return _mockDataStore;
}

- (APHMedicationTrackerDataStore *)dataStore {
    return self.mockDataStore;
}

- (MockAPCDataGroupsManager *)mockDataGroupsManager {
    return self.mockDataStore.mockDataGroupsManager;
}

@end
