//
//  MockAPCDataGroupsManager.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPCDataGroupsManager.h"

@implementation MockAPCDataGroupsManager

@synthesize hasChanges = _hasChanges;
@synthesize surveyStep = _surveyStep;
@synthesize surveyStepResult = _surveyStepResult;

- (void)setSurveyAnswerWithStepResult:(ORKStepResult *)surveyAnswerWithStepResult {
    _surveyStepResult = surveyAnswerWithStepResult;
    self.hasChanges = YES;
}

- (BOOL)needsUserInfoDataGroups {
    return self.surveyStepResult == nil;
}

- (BOOL)isStudyControlGroup {
    return [self.surveyStepResult isKindOfClass:[MockControlResult class]];
}

@end

@implementation MockPDResult

- (instancetype)init {
    return [self initWithStepIdentifier:APCDataGroupsStepIdentifier results:nil];
}

@end

@implementation MockControlResult

- (instancetype)init {
    return [self initWithStepIdentifier:APCDataGroupsStepIdentifier results:nil];
}

@end
