//
//  MockORKTask.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>

@interface MockORKTask : NSObject <ORKTask>

@end

@interface MockORKTaskWithOptionals : MockORKTask

@property (nonatomic) BOOL validateParameters_called;

@property (nonatomic, copy, readwrite, nullable) NSSet<HKObjectType *> *requestedHealthKitTypesForReading;
@property (nonatomic, copy, readwrite, nullable) NSSet<HKObjectType *> *requestedHealthKitTypesForWriting;
@property (nonatomic, readwrite) ORKPermissionMask requestedPermissions;
@property (nonatomic, readwrite) BOOL providesBackgroundAudioPrompts;

@end
