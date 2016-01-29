//
//  MockAPCTaskResultArchiver.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/28/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>
#import <mPowerSDK/mPowerSDK.h>

@interface MockAPCTaskResultArchiver : APHMedicationTrackerTaskResultArchiver

@property (nonatomic) NSMutableDictionary *archivedResults;

@end
