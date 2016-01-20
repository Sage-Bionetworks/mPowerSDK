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

- (MockAPCDataGroupsManager *)mockDataGroupsManager {
    if (_mockDataGroupsManager == nil) {
        _mockDataGroupsManager = [MockAPCDataGroupsManager new];
    }
    return _mockDataGroupsManager;
}

- (APCDataGroupsManager *)dataGroupsManager {
    return self.mockDataGroupsManager;
}

@end
