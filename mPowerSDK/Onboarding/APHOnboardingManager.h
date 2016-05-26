//
//  APHOnboardingManager.h
//  mPowerSDK
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <APCAppCore/APCAppCore.h>

extern NSString * const APHConsentTaskIdentifier;
extern NSString * const APHOnboardingSignUpTaskIdentifier;
extern NSString * const APHOnboardingSignInTaskIdentifier;
extern NSString * const APHConsentTaskIdentifier;
extern NSString * const APHOnboardingVerificationTaskIdentifier;
extern NSString * const APHOnboardingReconsentTaskIdentifier;

extern NSString * const APHInclusionCriteriaStepIdentifier;
extern NSString * const APHIneligibleStepIdentifier;
extern NSString * const APHEligibleStepIdentifier;
extern NSString * const APHReconsentIntroductionStepIdentifier;
extern NSString * const APHConsentCompletionStepIdentifier;
extern NSString * const APHPasscodeStepIdentifier;
extern NSString * const APHVerificationStepIdentifier;
extern NSString * const APHPermissionsIntroStepIdentifier;

@interface APHOnboardingManager : APCOnboardingManager <ORKTaskViewControllerDelegate, ORKPasscodeDelegate>

- (ORKTaskViewController *)instantiateOnboardingTaskViewController:(BOOL)signUp;
- (ORKTaskViewController *)instantiateConsentViewController;

// protected - Exposed publicly so that the target app can override
- (NSMutableArray <ORKStep *> *)buildSteps:(BOOL)signUp;
- (NSArray <ORKStep *> *)signInSteps;
- (NSArray <ORKStep *> *)eligibilitySteps;
- (NSArray <ORKStep *> *)consentSteps:(BOOL)isReconsent;
- (NSArray <ORKStep *> *)registrationSteps;
- (NSArray <ORKStep *> *)passcodeSteps;
- (NSArray <ORKStep *> *)verificationSteps;
- (NSArray <ORKStep *> *)profileSteps;
- (APCScene *)sceneForStep:(ORKStep *)step;

@end
