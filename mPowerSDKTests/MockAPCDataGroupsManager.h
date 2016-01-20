//
//  MockAPCDataGroupsManager.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface MockControlResult : ORKStepResult
@end

@interface MockPDResult : ORKStepResult
@end

@interface MockAPCDataGroupsManager : APCDataGroupsManager

@property (nonatomic, readwrite) BOOL hasChanges;
@property (nonatomic, readwrite) ORKFormStep * _Nullable surveyStep;
@property (nonatomic, readwrite) ORKStepResult * _Nullable surveyStepResult;

@end
