// 
//  APHPhonationTaskViewController.m 
//  mPower 
// 
// Copyright (c) 2015, Sage Bionetworks. All rights reserved. 
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

#import "APHPhonationTaskViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <APCAppCore/APCAppCore.h>
#import <PDScores/PDScores.h>
#import "APHAppDelegate.h"
#import "APHDataKeys.h"

    //
    //        Step Identifiers
    //
static  NSString *const kInstructionStepIdentifier            = @"instruction";
static  NSString *const kInstruction1StepIdentifier           = @"instruction1";
static  NSString *const kCountdownStepIdentifier              = @"countdown";
static  NSString *const kAudioStepIdentifier                  = @"audio";
static  NSString *const kConclusionStepIdentifier             = @"conclusion";

static  NSString *kTaskIdentifier                             = @"Voice Activity";

static  NSTimeInterval  kGetSoundingAaahhhInterval            = 10.0;

static const NSInteger kPhonationActivitySchemaRevision       = 3;

@interface APHPhonationTaskViewController ( )  <ORKTaskViewControllerDelegate>

@end

@implementation APHPhonationTaskViewController

#pragma  mark  -  Initialisation

+ (ORKOrderedTask *)createOrkTask:(APCTask *) __unused scheduledTask
{
    NSDictionary  *audioSettings = @{ AVFormatIDKey         : @(kAudioFormatAppleLossless),
                                      AVNumberOfChannelsKey : @(1),
                                      AVSampleRateKey       : @(44100.0)
                                      };
    
    ORKOrderedTask  *orkTask = [ORKOrderedTask audioTaskWithIdentifier:kTaskIdentifier
                                                intendedUseDescription:nil
                                                     speechInstruction:nil
                                                shortSpeechInstruction:nil
                                                              duration:kGetSoundingAaahhhInterval
                                                     recordingSettings:audioSettings
                                                               options:0];
    
    //  Adjust apperance and text for the task
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    //
    //    set up initial steps, which may have an extra step injected
    //    after the first if the user needs to say where they are in
    //    their medication schedule
    //
    NSString *localizedTaskName = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_TITLE", nil, [NSBundle mainBundle], @"Voice", @"Title for Voice activity");
    [orkTask.steps[0] setTitle:localizedTaskName];
    
    ORKInstructionStep *instructionStep = (ORKInstructionStep *)orkTask.steps[1];
    [instructionStep setTitle:localizedTaskName];
    [instructionStep setText:NSLocalizedString(@"Take a deep breath and say “Aaaaah” into the microphone for as long as you can. "
                                               @"Keep a steady volume so the audio bars remain blue.", nil)];
    [instructionStep setDetailText:NSLocalizedString(@"Tap Next to begin the test.", nil)];
    
    [orkTask.steps.lastObject setTitle:kConclusionStepThankYouTitle];
    [orkTask.steps.lastObject setText:kConclusionStepViewDashboard];
    
    ORKOrderedTask  *replacementTask = [self modifyTaskWithPreSurveyStepIfRequired:orkTask
                                                                          andTitle:(NSString *)kTaskIdentifier];
    return  replacementTask;
}

#pragma  mark  -  Task View Controller Delegate Methods

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    ORKStep  *step = stepViewController.step;
    
    if ([step.identifier isEqualToString: kAudioStepIdentifier]) {
        [[UIView appearance] setTintColor:[UIColor appTertiaryBlueColor]];
    } else if ([step.identifier isEqualToString: kConclusionStepIdentifier]) {
        [[UIView appearance] setTintColor:[UIColor appTertiaryColor1]];
    } else {
        [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    }
}

- (void)taskViewController: (ORKTaskViewController *) taskViewController didFinishWithReason: (ORKTaskViewControllerFinishReason)reason error: (NSError *) error
{
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];
    
    if (reason  == ORKTaskViewControllerFinishReasonFailed) {
        if (error != nil) {
            APCLogError2 (error);
        }
    }
    [super taskViewController: taskViewController didFinishWithReason: reason error: error];
}

#pragma  mark  -  Results For Dashboard

- (NSString *)createResultSummary
{
    ORKTaskResult  *taskResults = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext * context) {
        
        ORKFileResult  *fileResult = nil;
        BOOL  found = NO;
        for (ORKStepResult  *stepResult  in  taskResults.results) {
            if (stepResult.results.count > 0) {
                for (id  object  in  stepResult.results) {
                    if ([object isKindOfClass:[ORKFileResult class]] == YES) {
                        found = YES;
                        fileResult = object;
                        break;
                    }
                }
                if (found == YES) {
                    break;
                }
            }
        }
        
        double scoreSummary = [PDScores scoreFromPhonationTest: fileResult.fileURL];
        scoreSummary = isnan(scoreSummary) ? 0 : scoreSummary;
        
        NSDictionary  *summary = @{APHPhonationScoreSummaryOfRecordsKey : @(scoreSummary)};
        
        NSError  *error = nil;
        NSData  *data = [NSJSONSerialization dataWithJSONObject:summary options:0 error:&error];
        NSString  *contentString = nil;
        if (data == nil) {
            APCLogError2 (error);
        } else {
            contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        if (contentString.length > 0)
        {
            [APCResult updateResultSummary:contentString forTaskResult:taskResults inContext:context];
        }
    };
    return nil;
}

#pragma  mark  - Settings

- (APCSignUpPermissionsType)requiredPermission {
    return kAPCSignUpPermissionsTypeMicrophone;
}

- (void) updateSchemaRevision
{
    if (self.scheduledTask) {
        self.scheduledTask.taskSchemaRevision = [NSNumber numberWithInteger:kPhonationActivitySchemaRevision];
    }
}


#pragma  mark  - View Controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_NAV_TITLE", nil, [NSBundle mainBundle], @"Voice Activity", @"Nav bar title for Voice activity view");
   
   // Once you give Audio permission to the application. Your app will not show permission prompt again.
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // Microphone enabled
        } else {
            // Microphone disabled
            //Inform the user that they will to enable the Microphone
            UIAlertController * alert = [UIAlertController simpleAlertWithTitle:NSLocalizedStringWithDefaultValue(@"APH_PHONATION_ENABLE_MIC_ALERT_MSG", nil, [NSBundle mainBundle], @"You need to enable access to microphone.", @"Alert message when microphone access not enabled for this app when trying to perform Voice activity.") message:nil];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
