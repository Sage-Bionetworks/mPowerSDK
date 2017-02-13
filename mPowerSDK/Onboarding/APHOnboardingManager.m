//
//  APHOnboardingManager.m
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

#import "APHOnboardingManager.h"
#import "APHLocalization.h"
#import "APHAppDelegate.h"
#import "APHWebViewStepViewController.h"
#import <ResearchKit/ResearchKit.h>
@import BridgeAppSDK;

NSString * const APHOnboardingSignUpTaskIdentifier = @"onboarding";
NSString * const APHOnboardingSignInTaskIdentifier = @"signin";
NSString * const APHConsentTaskIdentifier = @"consent";
NSString * const APHOnboardingVerificationTaskIdentifier = @"onboardingVerification";
NSString * const APHOnboardingReconsentTaskIdentifier = @"onboardingReconsent";

NSString * const APHInclusionCriteriaStepIdentifier = @"inclusionCriteria";
NSString * const APHIneligibleStepIdentifier = @"ineligibleInstruction";
NSString * const APHEligibleStepIdentifier = @"eligibleInstruction";
NSString * const APHReconsentIntroductionStepIdentifier = @"reconsentIntroduction";
NSString * const APHConsentCompletionStepIdentifier = @"consentCompletion";
NSString * const APHPasscodeStepIdentifier = @"passcode";
NSString * const APHVerificationStepIdentifier = @"verification";
NSString * const APHPermissionsIntroStepIdentifier = @"permissionsIntro";

@interface ORKStepViewController (APHOnboarding)

- (void)onboardingCancelAction;

@end

@interface APHOnboardingManager () 

@end

@implementation APHOnboardingManager

- (ORKTaskViewController *)instantiateConsentViewController {
    
    // syoung 2/22/2016 TODO: cleanup the steps management to remove the need to
    // instantiate the APCOnboarding (and inherit from APCOnboardingManager.
    if (!self.onboarding) {
        [self instantiateOnboardingForType:kAPCOnboardingTaskTypeSignIn];
    }
    
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:APHConsentTaskIdentifier
                                                                                  steps:[self consentSteps:YES]];
    ORKTaskViewController *vc = [[ORKTaskViewController alloc] initWithTask:task restorationData:nil delegate:self];
    return vc;
}

- (ORKTaskViewController *)instantiateOnboardingTaskViewController:(BOOL)signUp {
    
    // syoung 2/22/2016 TODO: cleanup the steps management to remove the need to
    // instantiate the APCOnboarding (and inherit from APCOnboardingManager.
    if (!self.onboarding) {
        APCOnboardingTaskType taskType = signUp ? kAPCOnboardingTaskTypeSignUp : kAPCOnboardingTaskTypeSignIn;
        [self instantiateOnboardingForType:taskType];
    }
    
    NSString *taskIdentifier;
    if (self.user.isSignedUp && self.user.isSignedIn && !self.user.isConsented) {
        // This is a reconsent flow
        taskIdentifier = APHConsentTaskIdentifier;
    }
    else if (signUp) {
        // User tapped the "Join Study" button
        taskIdentifier = APHOnboardingSignUpTaskIdentifier;
    }
    else {
        // User tapped the "Sign in" button
        taskIdentifier = APHOnboardingSignInTaskIdentifier;
    }
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:taskIdentifier
                                                                                  steps:[self buildSteps:signUp]];
    ORKTaskViewController *vc = [[ORKTaskViewController alloc] initWithTask:task restorationData:nil delegate:self];
    return vc;
}

- (NSMutableArray <ORKStep *> *)buildSteps:(BOOL)signUp {
    
    // Build the steps
    NSMutableArray *steps = [NSMutableArray new];
    
    // Beginning steps are different depending upon whether or not this is an
    // initial registration and/or reconsent
    if (!signUp) {
        [steps addObjectsFromArray:[self signInSteps]];
    }
    else {
        if (!self.user.isSignedUp) {
            // If the user is not signed up then need to check for eligibility
            [steps addObjectsFromArray:[self eligibilitySteps]];
        }
        if (!self.user.isUserConsented) {
            // Need to add the consent flow if the user is not consented
            [steps addObjectsFromArray:[self consentSteps: self.user.isSignedUp]];
        }
        if (!self.user.isSignedUp) {
            // Next is registration for the user who is *not* signed up
            [steps addObjectsFromArray:[self registrationSteps]];

            // Bridge-1623 add step to get referral code from user
            [steps addObjectsFromArray:[self referralCodeSteps]];
        }
    }
    
    // If the user does not have an ORKpasscode, then add one
    if (!self.hasORKPasscode) {
        NSArray *passcodeSteps = [self passcodeSteps];
        if (passcodeSteps.count > 0) {
            if (self.user.isSignedIn && !self.user.isUserConsented) {
                // If the user is signed in but needs to reconsent then
                // insert passcode before final step
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(steps.count-1, passcodeSteps.count)];
                [steps insertObjects:passcodeSteps atIndexes:indexSet];
            }
            else {
                // Then following registration, we ask the user to add a passcode
                [steps addObjectsFromArray:passcodeSteps];
            }
        }
    }
    
    // If the user is being reconsented but has already signed in then do not need to add these steps
    if (!self.user.isSignedIn) {
        // If the user is signed up but *not* verified (signed in) then
        // show the email verification and finish profile setup
        if (signUp) {
            [steps addObjectsFromArray:[self verificationSteps]];
        }
        // The profile and permission steps need to be added to the flow b/c this
        // is a new device/user.
        [steps addObjectsFromArray:[self profileSteps]];
    }
    
    return steps;
}

- (NSArray <ORKStep *> *)eligibilitySteps {
    SBASurveyFactory *factory = [[SBASurveyFactory alloc] initWithJsonNamed:@"EligibilityRequirements"];
    return factory.steps;
}

- (NSArray <ORKStep *> *)consentSteps:(BOOL)isReconsent {
    
    SBAConsentDocumentFactory *factory = [[SBAConsentDocumentFactory alloc] initWithJsonNamed:@"APHConsentSection"];
    NSArray <ORKStep *> *steps = factory.steps;
    if (!isReconsent && [steps.firstObject.identifier isEqualToString:APHReconsentIntroductionStepIdentifier]) {
        // Strip out the reconsent introduction if not applicable
        steps = [steps subarrayWithRange:NSMakeRange(1, steps.count - 1)];
    }
    
    return steps;
}

- (NSArray <ORKStep *> *)registrationSteps {
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_REGISTRATION_TITLE", nil, APHLocaleBundle(), @"Registration", @"Title for registration view");
    NSString *text = NSLocalizedStringWithDefaultValue(@"APH_REGISTRATION_TEXT", nil, APHLocaleBundle(), @"Sage Bionetworks, a non-profit biomedical research institute, is helping to collect data for this study and distribute it to the study investigators and other researchers. Please provide a unique email address and password to create a secure account.", @"Text for registration view");
    ORKRegistrationStepOption options = ORKRegistrationStepDefault |
                                        ORKRegistrationStepIncludeGivenName  |
                                        ORKRegistrationStepIncludeFamilyName |
                                        ORKRegistrationStepIncludeGender |
                                        ORKRegistrationStepIncludeDOB;
    return @[[[ORKRegistrationStep alloc] initWithIdentifier:kAPCSignUpGeneralInfoStepIdentifier title:title text:text options:options]];
}

- (NSArray <ORKStep *> *)passcodeSteps {
    ORKPasscodeStep *step = [[ORKPasscodeStep alloc] initWithIdentifier:APHPasscodeStepIdentifier];
    step.title = NSLocalizedStringWithDefaultValue(@"APH_PASSCODE_TITLE", nil, APHLocaleBundle(), @"Identification", @"Title for passcode view");
    step.text = NSLocalizedStringWithDefaultValue(@"APH_PASSCODE_TEXT", nil, APHLocaleBundle(), @"Select a 4-digit passcode. Setting up a passcode will help provide quick and secure access to this application.", @"Text for passcode view");
    return @[step];
}

- (NSArray <ORKStep *> *)verificationSteps {
    return @[[[ORKStep alloc] initWithIdentifier:APHVerificationStepIdentifier]];
}

- (NSArray <ORKStep *> *)referralCodeSteps {
    return @[[[ORKStep alloc] initWithIdentifier:kAPCReferralCodeStepIdentifier]];
}

- (NSArray <ORKStep *> *)signInSteps {
    return @[[[ORKStep alloc] initWithIdentifier:kAPCSignInStepIdentifier]];
}

- (NSArray <ORKStep *> *)profileSteps {
    
    // Explanation of the HealthKit modal
    ORKInstructionStep *permissionsIntroStep = [[ORKInstructionStep alloc] initWithIdentifier:APHPermissionsIntroStepIdentifier];
    permissionsIntroStep.title = NSLocalizedStringWithDefaultValue(@"APH_PERMISSIONS_INTRO_TITLE", nil, APHLocaleBundle(), @"Set up permissions and profile", @"Title for permissions and profile steps");
    permissionsIntroStep.text = NSLocalizedStringWithDefaultValue(@"APH_PERMISSIONS_INTRO_TEXT", nil, APHLocaleBundle(), @"On the next screen, you can authorize the app to access your general health information stored in HealthKit like height, weight or steps taken. Press “Allow” to select the information the app may access.", @"Title for permissions and profile steps");
    
    // Medical Info
    ORKStep *medicalInfoStep = [[ORKStep alloc] initWithIdentifier:kAPCSignUpMedicalInfoStepIdentifier];
    
    // Permissions
    ORKStep *permissionsStep = [[ORKStep alloc] initWithIdentifier:kAPCSignUpPermissionsStepIdentifier];
    
    // Final step
    ORKStep *finalStep = [[ORKStep alloc] initWithIdentifier:kAPCSignUpThankYouStepIdentifier];
    
    return @[permissionsIntroStep, medicalInfoStep, permissionsStep, finalStep];
}

- (APCScene *)sceneForStep:(ORKStep *)step {
    
    // Look for the scene in the parent
    APCScene *scene = [self onboarding:self.onboarding sceneOfType:step.identifier];
    scene.step = step;
    
    // If it's nil, look in this class
    if (scene == nil) {
        
        // Check if this is inclusion
        if ([step.identifier isEqualToString:APHInclusionCriteriaStepIdentifier]) {
            scene = [[APCScene alloc] initWithStep:step];
            scene.storyboardId = @"APHInclusionCriteriaViewController";
            scene.storyboardName = @"APHOnboarding";
            scene.bundle = [[APHAppDelegate sharedAppDelegate] storyboardBundle];
        }
        
        // Use the custom view controller if there is an image and instruction and no title
        else if ([step isKindOfClass:[ORKInstructionStep class]] &&
            [(ORKInstructionStep*)step image] != nil &&
            step.title.length == 0) {
            scene = [[APCScene alloc] initWithStep:step];
            scene.storyboardId = @"APHInstructionStepViewController";
            scene.storyboardName = @"APHOnboarding";
            scene.bundle = [[APHAppDelegate sharedAppDelegate] storyboardBundle];
        }
        
        // Verify email step
        else if ([step.identifier isEqualToString:APHVerificationStepIdentifier]) {
            scene = [[APCScene alloc] initWithStep:step];
            scene.storyboardName = @"APCEmailVerify";
            scene.bundle = [NSBundle appleCoreBundle];
        }
        
        // If this step will fall through to an ORKFormStepViewController then
        // create a scene so it will *not* show the step with the results prefilled
        // for the consent quiz.
        else if ([step isKindOfClass:[ORKFormStep class]] && ![step isKindOfClass:[ORKConsentReviewStep class]]) {
            scene = [[APCScene alloc] initWithStep:step];
        }
    }
    
    return scene;
}

#pragma mark - ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error {

    if ((reason == ORKTaskViewControllerFinishReasonCompleted) && self.user.isUserConsented) {
        // finish onboarding
        self.user.signedIn = YES;
        self.user.signedUp = YES;
        [self onboardingDidFinishAsSignIn];
    }
    else if (reason == ORKTaskViewControllerFinishReasonDiscarded)  {
        // remove the passcode and user info if the flow is cancelled
        [APCKeychainStore resetKeyChain];
        self.user.signedIn = NO;
        self.user.signedUp = NO;
        self.user.consented = NO;
        self.user.userConsented = NO;
    }
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
}

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *)taskViewController viewControllerForStep:(ORKStep *)step {
    return [[self sceneForStep:step] instantiateStepViewController];
}

- (BOOL)shouldCheckConsentResultForTaskViewController:(ORKTaskViewController *)taskViewController nextStep:(ORKStep *)nextStep {
    return [nextStep.identifier isEqualToString:APHConsentCompletionStepIdentifier];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController {
    
    // Tracking of data is handled by associating onboarding step identifiers
    self.onboarding.currentStep = stepViewController.step;
    
    if ([self shouldCheckConsentResultForTaskViewController:taskViewController nextStep: stepViewController.step]) {
        if (![self checkForConsentWithTaskViewController:taskViewController]) {
            [self userDeclinedConsent];
            [self taskViewController:taskViewController didFinishWithReason:ORKTaskViewControllerFinishReasonDiscarded error:nil];
            return;
        }
        // Do not allow user to go back from this step
        stepViewController.backButtonItem = nil;
    }
    
    if ([stepViewController.step.identifier isEqualToString:kAPCSignInStepIdentifier]) {
        
        APCSignInViewController *signInVC = nil;
        if ([stepViewController isKindOfClass:[APCSignInViewController class]]) {
            signInVC = (APCSignInViewController*)stepViewController;
        }
        else if ([stepViewController isKindOfClass:[APCContainerStepViewController class]] &&
                 [((APCContainerStepViewController*)stepViewController).childViewController isKindOfClass:[APCSignInViewController class]]) {
            signInVC = (APCSignInViewController*)((APCContainerStepViewController*)stepViewController).childViewController;
        }
        if (signInVC) {
            stepViewController.backButtonItem = [[UIBarButtonItem alloc] initWithTitle:[Localization buttonCancel]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:stepViewController
                                                                                action:@selector(onboardingCancelAction)];
            stepViewController.cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:[Localization buttonNext]
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:signInVC
                                                                                action:@selector(signIn)];
        }
        
    }
    else if (![stepViewController.step isKindOfClass:[ORKRegistrationStep class]] && ![stepViewController.step.identifier isEqualToString:kAPCReferralCodeStepIdentifier]) {
        // Override the cancel button (but only if not the registration or referralCode steps, which don't have other button to tie into)
        stepViewController.cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:[Localization buttonCancel]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:stepViewController
                                                                            action:@selector(onboardingCancelAction)];
    }
    
    
    // Do not allow back button for certain steps
    NSArray *noBackButton = @[APHConsentCompletionStepIdentifier,
                              APHPasscodeStepIdentifier,
                              APHVerificationStepIdentifier,
                              APHPermissionsIntroStepIdentifier];
    if ([noBackButton containsObject:stepViewController.step.identifier]) {
        stepViewController.backButtonItem = nil;
    }
    
    // For the last step, do not show any button in the top right
    if ([stepViewController.step.identifier isEqualToString:kAPCSignUpThankYouStepIdentifier]) {
        stepViewController.cancelButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectZero]];
    }
}

- (BOOL)taskViewController:(ORKTaskViewController *)taskViewController hasLearnMoreForStep:(ORKStep *)step {
    return [self usesLearnMoreViewControllerForStep:step];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController learnMoreForStep:(ORKStepViewController *)stepViewController {
    ORKStep *step = stepViewController.step;
    if (![self usesLearnMoreViewControllerForStep:step]) {
        return;
    }
    NSString *htmlContent = ((SBAInstructionStep *)step).learnMoreHTMLContent;
    APHWebViewStepViewController *vc = [APHWebViewStepViewController instantiateWithHTMLContent:htmlContent];
    UINavigationController *navVc = [[UINavigationController alloc] initWithRootViewController:vc];
    navVc.modalPresentationStyle = UIModalPresentationFormSheet;
    [stepViewController presentViewController:navVc animated:YES completion:nil];
}

- (BOOL)usesLearnMoreViewControllerForStep:(ORKStep *)step  {
    return [step isKindOfClass:[SBAInstructionStep class]] &&
    (((SBAInstructionStep*)step).learnMoreHTMLContent != nil);
}

#pragma mark - passcode handling

// Switching to use the new ResearchKit passcode but need to keep reverse compatibilility
// for existing users. TODO: refactor syoung 02/24/2016

- (BOOL)hasORKPasscode {
    return [ORKPasscodeViewController isPasscodeStoredInKeychain];
}

- (BOOL)hasPasscode {
    return [self hasORKPasscode] || [super hasPasscode];
}

- (UIViewController *)instantiatePasscodeViewControllerWithDelegate:(id)delegate {
    if ([self hasORKPasscode]) {
        return [ORKPasscodeViewController passcodeAuthenticationViewControllerWithText:nil delegate:delegate];
    }
    else {
        return [super instantiatePasscodeViewControllerWithDelegate:delegate];
    }
}

- (UIViewController *)instantiateChangePasscodeViewController {
    if ([self hasORKPasscode]) {
        return [ORKPasscodeViewController passcodeEditingViewControllerWithText:nil delegate:self passcodeType:ORKPasscodeType4Digit];
    }
    else {
        return [super instantiateChangePasscodeViewController];
    }
}

- (void)passcodeViewControllerDidFinishWithSuccess:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)passcodeViewControllerDidFailAuthentication:(UIViewController *)viewController {
    // TODO: Implement? syoung 2/24/2016
}

- (void)passcodeViewControllerDidCancel:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}


@end

@implementation ORKStepViewController (APHOnboarding)

- (void)onboardingCancelAction {
    // Call through to cancel the onboarding flow
    [self.taskViewController.delegate taskViewController:self.taskViewController
                                     didFinishWithReason:ORKTaskViewControllerFinishReasonDiscarded
                                                   error:nil];
}

@end
