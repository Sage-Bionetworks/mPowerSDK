//
//  APHOnboardingManager.h
//  mPowerSDK
//
//  Created by Shannon Young on 2/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface APHOnboardingManager : APCOnboardingManager

- (ORKTaskViewController *)instantiateOnboardingTaskViewController;

@end
