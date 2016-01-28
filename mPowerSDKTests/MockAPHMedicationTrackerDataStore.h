//
//  MockAPHMedicationTrackerDataStore.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/21/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <mPowerSDK/mPowerSDK.h>
#import "MockAPCDataGroupsManager.h"
#import "MockAPCUser.h"

@interface MockAPHMedicationTrackerDataStore : APHMedicationTrackerDataStore

@property (nonatomic) NSDate *mockLastCompletionDate;

@property (nonatomic) BOOL commitChanges_called;
@property (nonatomic) BOOL reset_called;

@end
