//
//  MockAPHMedicationTrackerTask.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <mPowerSDK/mPowerSDK.h>
#import "MockAPHMedicationTrackerDataStore.h"

@interface MockAPHMedicationTrackerTask : APHMedicationTrackerTask

@property (nonatomic) MockAPHMedicationTrackerDataStore *mockDataStore;
@property (nonatomic, readonly) MockAPCDataGroupsManager *mockDataGroupsManager;

@end
