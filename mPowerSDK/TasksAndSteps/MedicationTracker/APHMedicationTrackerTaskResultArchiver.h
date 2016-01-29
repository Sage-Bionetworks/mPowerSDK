//
//  APHMedicationTrackerTaskResultArchiver.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@class APHMedicationTrackerTask;

@interface APHMedicationTrackerTaskResultArchiver : APCTaskResultArchiver

@property (nonatomic) APHMedicationTrackerTask *task;

-(instancetype)initWithTask:(APHMedicationTrackerTask *)task;


@end
