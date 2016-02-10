//
//  APHOnboardingManager.m
//  mPowerSDK
//
//  Created by Shannon Young on 2/19/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHOnboardingManager.h"
#import "APHLocalization.h"
#import "APHAppDelegate.h"
#import <ResearchKit/ResearchKit.h>
@import BridgeAppSDK;

NSString * const APHOnboardingSignUpTaskIdentifier = @"onboarding";
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

@interface APHOnboardingManager () <ORKTaskViewControllerDelegate, ORKPasscodeDelegate>

@end

@implementation APHOnboardingManager

- (ORKTaskViewController *)instantiateOnboardingTaskViewController {
    SBANavigableOrderedTask *task = [[SBANavigableOrderedTask alloc] initWithIdentifier:APHOnboardingSignUpTaskIdentifier
                                                                                  steps:[self buildSteps]];
    ORKTaskViewController *vc = [[ORKTaskViewController alloc] initWithTask:task restorationData:nil delegate:self];
    
    return vc;
}

- (NSMutableArray <ORKStep *> *)buildSteps {
    
    // syoung 2/22/2016 TODO: cleanup the steps management to remove the need to
    // instantiate the APCOnboarding (and inherit from APCOnboardingManager.
    [self instantiateOnboardingForType:kAPCOnboardingTaskTypeSignUp];
    
    // Build the steps
    NSMutableArray *steps = [NSMutableArray new];
    if (!self.user.isSignedUp) {
        // If the user is not signed up then need to check for eligibility
        [steps addObjectsFromArray:[self eligibilitySteps]];
    }
    if (!self.user.isUserConsented) {
        // Need to add the consent flow if the user is not consented
        [steps addObjectsFromArray:[self consentSteps]];
    }
    if (!self.user.isSignedUp) {
        // Next is registration for the user who is *not* signed up
        [steps addObject:[self registrationStep]];
    }
    if (!self.hasORKPasscode) {
        if (self.user.isSignedIn && !self.user.isUserConsented) {
            // If the user is signed in but needs to reconsent then
            // insert passcode before final step
            [steps insertObject:[self passcodeStep] atIndex:steps.count-1];
        }
        else {
            // Then following registration, we ask the user to add a passcode
            [steps addObject:[self passcodeStep]];
        }
    }
    if (!self.user.isSignedIn) {
        // If the user is signed up but *not* verified (signed in) then
        // show the email verification and finish profile setup
        [steps addObject:[self verificationStep]];
        [steps addObjectsFromArray:[self profileSteps]];
    }
    
    return steps;
}

- (NSArray <ORKStep *> *)eligibilitySteps {
    SBASurveyFactory *factory = [[SBASurveyFactory alloc] initWithJsonNamed:@"EligibilityRequirements"];
    return factory.steps;
}

- (NSArray <ORKStep *> *)consentSteps {
    SBAConsentDocumentFactory *factory = [[SBAConsentDocumentFactory alloc] initWithJsonNamed:@"APHConsentSection"];
    NSArray <ORKStep *> *steps = factory.steps;
    if (!self.user.isSignedUp && [steps.firstObject.identifier isEqualToString:APHReconsentIntroductionStepIdentifier]) {
        // Strip out the reconsent introduction if not applicable
        steps = [steps subarrayWithRange:NSMakeRange(1, steps.count - 1)];
    }
    return steps;
}

- (ORKStep *)registrationStep {
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_REGISTRATION_TITLE", nil, APHLocaleBundle(), @"Registration", @"Title for registration view");
    NSString *text = NSLocalizedStringWithDefaultValue(@"APH_REGISTRATION_TEXT", nil, APHLocaleBundle(), @"Sage Bionetworks, a non-profit biomedical research institute, is helping to collect data for this study and distribute it to the study investigators and other researchers. Please provide a unique email address and password to create a secure account.", @"Text for registration view");
    ORKRegistrationStepOption options = ORKRegistrationStepDefault |
                                        ORKRegistrationStepIncludeGivenName  |
                                        ORKRegistrationStepIncludeFamilyName |
                                        ORKRegistrationStepIncludeGender |
                                        ORKRegistrationStepIncludeDOB;
    return [[ORKRegistrationStep alloc] initWithIdentifier:kAPCSignUpGeneralInfoStepIdentifier title:title text:text options:options];
}

- (ORKStep *)passcodeStep {
    ORKPasscodeStep *step = [[ORKPasscodeStep alloc] initWithIdentifier:APHPasscodeStepIdentifier];
    step.title = NSLocalizedStringWithDefaultValue(@"APH_PASSCODE_TITLE", nil, APHLocaleBundle(), @"Identification", @"Title for passcode view");
    step.text = NSLocalizedStringWithDefaultValue(@"APH_PASSCODE_TEXT", nil, APHLocaleBundle(), @"Select a 4-digit passcode. Setting up a passcode will help provide quick and secure access to this application.", @"Text for passcode view");
    return step;
}

- (ORKStep *)verificationStep {
    return [[ORKStep alloc] initWithIdentifier:APHVerificationStepIdentifier];
}

- (NSArray <ORKStep *> *)profileSteps {
    
    // Explanation of the HealthKit modal
    ORKInstructionStep *permissionsIntroStep = [[ORKInstructionStep alloc] initWithIdentifier:APHPermissionsIntroStepIdentifier];
    permissionsIntroStep.title = NSLocalizedStringWithDefaultValue(@"APH_PERMISSIONS_INTRO_TITLE", nil, APHLocaleBundle(), @"Set up permissions and profile", @"Title for permissions and profile steps");
    permissionsIntroStep.text = NSLocalizedStringWithDefaultValue(@"APH_PERMISSIONS_INTRO_TEXT", nil, APHLocaleBundle(), @"On the next screen, you will be prompted to grant access to read and write some of your general and health information, such as height, weight, and steps taken so you don't have to enter it again.", @"Title for permissions and profile steps");
    
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
        else if ([step isKindOfClass:[ORKFormStep class]]) {
            scene = [[APCScene alloc] initWithStep:step];
        }
    }
    
    return scene;
}

#pragma mark - ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error {

    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        // finish onboarding
        [self onboardingDidFinish];
    }
    else if (reason == ORKTaskViewControllerFinishReasonDiscarded) {
        // remove the passcode and user info if the flow is cancelled
        [ORKPasscodeViewController removePasscodeFromKeychain];
        self.user.email = nil;
        self.user.password = nil;
        self.user.signedIn = NO;
        self.user.signedUp = NO;
    }
    [taskViewController dismissViewControllerAnimated:YES completion:nil];
}

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *)taskViewController viewControllerForStep:(ORKStep *)step {
    return [[self sceneForStep:step] instantiateStepViewController];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController {
    
    // Tracking of data is handled by associating onboarding step identifiers
    self.onboarding.currentStep = stepViewController.step;
    
    if ([stepViewController.step.identifier isEqualToString:APHConsentCompletionStepIdentifier]) {
        [self checkForConsentWithTaskViewController:taskViewController];
    }
    
    if (![stepViewController.step isKindOfClass:[ORKRegistrationStep class]]) {
        // Override the cancel button (but only if not the registration step which has no other button to tie into)
        stepViewController.cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:ORKLocalizedString(@"BUTTON_CANCEL", nil)
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:stepViewController
                                                                            action:@selector(onboardingCancelAction)];
    }
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

#pragma mark - handle user consent

- (ORKConsentSignatureResult *)findConsentSignatureResult:(ORKTaskResult*)taskResult {
    for (ORKStepResult *stepResult in taskResult.results) {
        for (ORKResult *result in stepResult.results) {
            if ([result isKindOfClass:[ORKConsentSignatureResult class]]) {
                return (ORKConsentSignatureResult*)result;
            }
        }
    }
    return nil;
}

- (ORKConsentSharingStep *)findConsentSharingStep:(ORKTaskViewController *)taskViewController {
    NSArray *steps = ((ORKOrderedTask*)taskViewController.task).steps;
    for (ORKStep *step in steps) {
        if ([step isKindOfClass:[ORKConsentSharingStep class]]) {
            return (ORKConsentSharingStep*)step;
        }
    }
    return nil;
}

- (void)checkForConsentWithTaskViewController:(ORKTaskViewController *)taskViewController {
    
    // search for the consent signature
    ORKConsentSignatureResult *consentResult = [self findConsentSignatureResult:taskViewController.result];
        
    //  if no signature (no consent result) then assume the user failed the quiz
    if (consentResult != nil && consentResult.signature.requiresName && (consentResult.signature.givenName && consentResult.signature.familyName)) {
        
        // extract the user's sharing choice
        ORKConsentSharingStep *sharingStep = [self findConsentSharingStep:taskViewController];
        APCUserConsentSharingScope sharingScope = APCUserConsentSharingScopeNone;
        
        for (ORKStepResult* result in taskViewController.result.results) {
            if ([result.identifier isEqualToString:sharingStep.identifier]) {
                for (ORKChoiceQuestionResult *choice in result.results) {
                    if ([choice isKindOfClass:[ORKChoiceQuestionResult class]]) {
                        NSNumber *answer = [choice.choiceAnswers firstObject];
                        if ([answer isKindOfClass:[NSNumber class]]) {
                            if (0 == answer.integerValue) {
                                sharingScope = APCUserConsentSharingScopeStudy;
                            }
                            else if (1 == answer.integerValue) {
                                sharingScope = APCUserConsentSharingScopeAll;
                            }
                            else {
                                APCLogDebug(@"Unknown sharing choice answer: %@", answer);
                            }
                        }
                        else {
                            APCLogDebug(@"Unknown sharing choice answer(s): %@", choice.choiceAnswers);
                        }
                    }
                }
                break;
            }
        }
        
        // signal the onboarding manager that we're done here
        [self userDidConsentWithResult:consentResult sharingScope:sharingScope];
        
    } else {
        [self userDeclinedConsent];
        [taskViewController dismissViewControllerAnimated:YES completion:nil];
    }
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
