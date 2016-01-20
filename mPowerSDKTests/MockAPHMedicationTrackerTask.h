//
//  MockAPHMedicationTrackerTask.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <mPowerSDK/mPowerSDK.h>
#import "MockAPCDataGroupsManager.h"

@interface MockAPHMedicationTrackerTask : APHMedicationTrackerTask

@property (nonatomic) MockAPCDataGroupsManager *mockDataGroupsManager;

@end
