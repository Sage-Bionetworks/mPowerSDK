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
@synthesize surveyStepResult = _surveyStepResult;

- (NSArray *)dataGroups {
    if ([self.surveyStepResult isKindOfClass:[MockPDResult class]]) {
        return @[@"parkinsons"];
    }
    else if ([self.surveyStepResult isKindOfClass:[MockControlResult class]]) {
        return @[@"control"];
    }
    return nil;
}

- (ORKFormStep *)surveyStep {
    return [[ORKFormStep alloc] initWithIdentifier:APCDataGroupsStepIdentifier];
}

- (void)setSurveyAnswerWithStepResult:(ORKStepResult *)surveyAnswerWithStepResult {
    _surveyStepResult = surveyAnswerWithStepResult;
    self.hasChanges = YES;
}

- (BOOL)needsUserInfoDataGroups {
    return (self.surveyStepResult == nil) || ([self.surveyStepResult isKindOfClass:[MockSkipResult class]]);
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

@implementation MockSkipResult

- (instancetype)init {
    return [self initWithStepIdentifier:APCDataGroupsStepIdentifier results:nil];
}

@end
