//
//  MockAPHMedicationTrackerTask.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPHMedicationTrackerTask.h"

@implementation MockAPHMedicationTrackerTask

+ (NSDictionary *)defaultMapping {
    NSBundle *bundle = [NSBundle bundleForClass:[APHMedicationTrackerTask class]];
    NSString *path = [bundle pathForResource:@"MedicationTracking" ofType:@"json"];
    NSData *json = [NSData dataWithContentsOfFile:path];
    NSAssert1(json != nil, @"Dictionary not found. %@", path);
    NSError *parseError;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingMutableContainers error:&parseError];
    NSAssert1(parseError == nil, @"Error parsing data group mapping: %@", parseError);
    return dictionary;
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
    if (_mockDataGroupsManager == nil) {
        _mockDataGroupsManager = [MockAPCDataGroupsManager new];
    }
    return _mockDataGroupsManager;
}

- (APCDataGroupsManager *)dataGroupsManager {
    return self.mockDataGroupsManager;
}

@end
