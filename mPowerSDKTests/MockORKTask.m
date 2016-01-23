//
//  MockORKTask.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/22/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockORKTask.h"

@implementation MockORKTask

- (NSString *)identifier {
    return @"MockORKTask";
}

- (ORKStep *)stepAfterStep:(ORKStep *)step withResult:(ORKTaskResult *)result {
    return nil;
}

- (ORKStep *)stepBeforeStep:(ORKStep *)step withResult:(ORKTaskResult *)result {
    return nil;
}

@end

@implementation MockORKTaskWithOptionals

- (instancetype)init {
    if ((self = [super init])) {
        self.requestedHealthKitTypesForReading = [NSSet setWithArray:@[[HKObjectType workoutType]]];
        self.requestedHealthKitTypesForWriting = [NSSet setWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex]]];
        self.requestedPermissions = ORKPermissionCoreMotionActivity;
        self.providesBackgroundAudioPrompts = YES;
    }
    return self;
}

- (void)validateParameters {
    self.validateParameters_called = YES;
}

@synthesize requestedHealthKitTypesForReading;
@synthesize requestedHealthKitTypesForWriting;
@synthesize requestedPermissions;
@synthesize providesBackgroundAudioPrompts;

@end
