// 
//  APHWalkingTaskViewController.m 
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

#import "APHWalkingTaskViewController.h"
#import <HealthKit/HealthKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ConverterForPDScores.h"
#import <PDScores/PDScores.h>
#import "APHAppDelegate.h"

    //
    //        Step Identifiers
    //
static NSString* const  kFileResultsKey                       = @"items";
static NSString* const  kNumberOfStepsTotalOnReturn           = @"numberOfSteps";
static NSString* const  kNumberOfStepsTotalOnReturnKey        = @"numberOfSteps";
static NSString* const  kPedometerPrefixFileIdentifier        = @"pedometer";

static  NSString       *kWalkingActivityTitle                 = @"Walking Activity";

static  NSUInteger      kNumberOfStepsPerLeg                  = 20;
static  NSTimeInterval  kStandStillDuration                   = 30.0;

    //
    //    Walking Activity Step Identifier Keys
    //        depending on Research Kit not to change the Identifier Keys
    //
static  NSString * const kInformationalStepIdentifier         = @"instruction";
static  NSString * const kInstructionalStepIdentifier         = @"instruction1";
static  NSString * const kCountdownStepIdentifier             = @"countdown";
static  NSString * const kWalkingOutboundStepIdentifier       = @"walking.outbound";
static  NSString * const kWalkingReturnStepIdentifier         = @"walking.return";
static  NSString * const kWalkingRestStepIdentifier           = @"walking.rest";
static  NSString * const kConclusionStepIdentifier            = @"conclusion";

static  NSString       *kScoreForwardGainRecordsKey           = @"ScoreForwardGainRecords";
static  NSString       *kScorePostureRecordsKey               = @"ScorePostureRecords";

        NSString * const kGaitScoreKey                        = @"GaitScoreKey";

static const NSInteger kWalkingActivitySchemaRevision         = 5;

@interface APHWalkingTaskViewController  ( )

@end

@implementation APHWalkingTaskViewController

#pragma  mark  -  Initialisation

+ (ORKOrderedTask *)createOrkTask:(APCTask *) __unused scheduledTask
{
    ORKOrderedTask  *orkTask = [ORKOrderedTask shortWalkTaskWithIdentifier:kWalkingActivityTitle
                                                    intendedUseDescription:nil
                                                       numberOfStepsPerLeg:kNumberOfStepsPerLeg
                                                              restDuration:kStandStillDuration
                                                                   options:ORKPredefinedTaskOptionNone];
    
    //
    //    replace various step titles and details with our own verbiage
    //
    ORKInstructionStep *instructionStep = (ORKInstructionStep *)orkTask.steps[0];
    [instructionStep setText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_DESCRIPTION", nil, [NSBundle mainBundle], @"This activity measures your gait (walk) and balance, which can be affected by Parkinson disease.", @"Description of purpose of walking activity.")];
    [instructionStep setDetailText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_CAUTION", nil, [NSBundle mainBundle], @"Please do not continue if you cannot safely walk unassisted.", @"Warning regarding performing walking activity.")];
    
    NSString  *titleFormat = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_TEXT_INSTRUCTION", nil, [NSBundle mainBundle], @"Turn around and stand still for %@ seconds", @"Written instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *titleString = [NSString stringWithFormat:titleFormat, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    NSString  *spokenInstructionFormat = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_SPOKEN_INSTRUCTION", nil, [NSBundle mainBundle], @"Turn around and stand still for %@ seconds", @"Spoken instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *spokenInstructionString = [NSString stringWithFormat:titleFormat, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    
    ORKActiveStep *activeStep = (ORKActiveStep *)orkTask.steps[5];
    [activeStep setTitle:titleString];
    [activeStep setSpokenInstruction:spokenInstructionString];
    
    [orkTask.steps[6] setTitle:kConclusionStepThankYouTitle];
    [orkTask.steps[6] setText:kConclusionStepViewDashboard];
    
    //
    //    remove the return walking step
    //
    BOOL        foundReturnStepIdentifier = NO;
    NSUInteger  indexOfReturnStep = 0;
    
    for (ORKStep *step  in  orkTask.steps) {
        if ([step.identifier isEqualToString:kWalkingReturnStepIdentifier] == YES) {
            foundReturnStepIdentifier = YES;
            break;
        }
        indexOfReturnStep = indexOfReturnStep + 1;
    }
    NSMutableArray  *copyOfTaskSteps = [orkTask.steps mutableCopy];
    if (foundReturnStepIdentifier == YES) {
        [copyOfTaskSteps removeObjectAtIndex:indexOfReturnStep];
    }
    orkTask = [[ORKOrderedTask alloc] initWithIdentifier:kWalkingActivityTitle steps:copyOfTaskSteps];
    
    ORKOrderedTask  *replacementTask = [self modifyTaskWithPreSurveyStepIfRequired:orkTask
                                                                          andTitle:(NSString *)kWalkingActivityTitle];
    return  replacementTask;
}

#pragma  mark  -  Create Dashboard Summary Results

- (NSString *)createResultSummary
{
    ORKTaskResult  *taskResults = self.result;
    
    APHWalkingTaskViewController  *weakSelf = self;
    
    self.createResultSummaryBlock = ^(NSManagedObjectContext * context) {
        BOOL  found = NO;
        NSURL  *urlGaitForward = nil;
        NSURL  *urlPosture     = nil;
        for (ORKStepResult  *stepResult  in  taskResults.results) {
            if (stepResult.results.count > 0) {
                for (id  object  in  stepResult.results) {
                    if ([object isKindOfClass:[ORKFileResult class]] == YES) {
                        ORKFileResult  *fileResult = object;
                        NSString *rawFilename = [ORKFileResult rawFilenameForFileResultIdentifier:fileResult.identifier stepIdentifier:stepResult.identifier];
                       if ([rawFilename hasPrefix: @"accelerometer_walking.outbound"]) {
                            urlGaitForward = fileResult.fileURL;
                        } else if ([rawFilename hasPrefix: @"accelerometer_walking.rest"]) {
                            urlPosture = fileResult.fileURL;
                        }
                        found = YES;
                        fileResult = object;
                    }
                }
            }
        }
        
        NSArray  *forwardSteps = [ConverterForPDScores convertPostureOrGain:urlGaitForward];
        double  forwardScores = 0.0;
        if (forwardSteps != nil) {
            forwardScores = [PDScores scoreFromGaitTest: forwardSteps];
        }
        forwardScores = isnan(forwardScores) ? 0.0 : forwardScores;
        
        NSArray  *posture = [ConverterForPDScores convertPostureOrGain:urlPosture];
        double  postureScores = 0.0;
        if (posture != nil) {
            postureScores = [PDScores scoreFromPostureTest: posture];
        }
        postureScores = isnan(postureScores) ? 0.0 : postureScores;
        
        double  avgScores = (forwardScores + postureScores) / 2.0;
        
        /************/
        
        NSDictionary   *walkingResults = nil;
        ORKStepResult  *stepResult = (ORKStepResult *)[weakSelf.result resultForIdentifier:kWalkingOutboundStepIdentifier];
        
        for (ORKFileResult *fileResult in stepResult.results) {
            NSString  *fileString = [fileResult.fileURL lastPathComponent];
            NSArray   *nameComponents = [fileString componentsSeparatedByString:@"_"];
            if ([[nameComponents objectAtIndex:0] isEqualToString:kPedometerPrefixFileIdentifier]) {
                walkingResults = [weakSelf computeTotalDistanceForDashboardItem:fileResult.fileURL];
            }
        }

        /***********/
        
        NSDictionary  *summary = @{
                                   kGaitScoreKey                  : @(avgScores),
                                   kScoreForwardGainRecordsKey    : @(forwardScores),
                                   kScorePostureRecordsKey        : @(postureScores),
                                   kNumberOfStepsTotalOnReturnKey : walkingResults == nil ? @0 : [walkingResults objectForKey:kNumberOfStepsTotalOnReturn]
                                  };
        
        NSError  *error = nil;
        NSData  *data = [NSJSONSerialization dataWithJSONObject:summary options:0 error:&error];
        NSString  *contentString = nil;
        if (data == nil) {
            APCLogError2 (error);
        } else {
            contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        if (contentString.length > 0) {
            [APCResult updateResultSummary:contentString forTaskResult:taskResults inContext:context];
        }
    };
    return  nil;
}

#pragma  mark  -  Task View Controller Delegate Methods

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    if ([stepViewController.step.identifier isEqualToString:kConclusionStepIdentifier]) {
        
        [[UIView appearance] setTintColor:[UIColor appTertiaryColor1]];
    }
    if ([stepViewController.step.identifier isEqualToString: kConclusionStepIdentifier]) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AVSpeechUtterance  *talk = [AVSpeechUtterance
                                    speechUtteranceWithString:NSLocalizedString(@"You have completed the activity.", @"Spoken message that the participant has completed the Walking activity.")];
        AVSpeechSynthesizer  *synthesiser = [[AVSpeechSynthesizer alloc] init];
        
        // see also in ORKVoiceEngine speakText: method. This apparently adjusts for a change between how iOS 8 and 9 interpret the speech rate value.
        float speechRate = AVSpeechUtteranceDefaultSpeechRate;
        if (! [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 9, .minorVersion = 0, .patchVersion = 0}]) {
            speechRate = AVSpeechUtteranceDefaultSpeechRate / 2.5;
        }
        talk.rate = speechRate;
        [synthesiser speakUtterance:talk];
    }
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error
{
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];

    if (reason == ORKTaskViewControllerFinishReasonFailed) {
        if (error != nil) {
            APCLogError2 (error);
        }
    }
    [super taskViewController: taskViewController didFinishWithReason: reason error: error];
}

#pragma  mark  - Settings

/*
 On older iphones that do not have an M7 chip, the CMMotionActivity api is not available. However,
 this activity will still work just using the accelerometer and gyroscope which do not require
 special permissions. On iPhones with the M7, we should still be requesting access to CoreMotion.
 */
- (APCSignUpPermissionsType)requiredPermission {
    if ([CMMotionActivityManager isActivityAvailable]) {
        return kAPCSignUpPermissionsTypeCoremotion;
    } else {
        return kAPCSignUpPermissionsTypeNone;
    }
    
}

#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"APH_WALKING_NAV_TITLE", nil, [NSBundle mainBundle], @"Walking Activity", @"Nav bar title for Walking activity view");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - Helper methods

- (NSDictionary *)computeTotalDistanceForDashboardItem:(NSURL *)fileURL{
    
    NSDictionary  *distanceResults = [self readFileResultsFor:fileURL];
    NSArray       *locations       = [distanceResults objectForKey:kFileResultsKey];
    
    int lastTotalNumberOfSteps = (int) [[[locations lastObject] objectForKey:kNumberOfStepsTotalOnReturn] integerValue];
    
    return  @{ @"numberOfSteps" : @(lastTotalNumberOfSteps) };
}

- (NSDictionary *) readFileResultsFor:(NSURL *)fileURL {
    
    NSError*        error       = nil;
    NSString*       contents    = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    NSDictionary*   results     = nil;
    
    APCLogError2(error);
    
    if (!error) {
        NSError  *error = nil;
        NSData   *data  = [contents dataUsingEncoding:NSUTF8StringEncoding];
        
        results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        APCLogError2(error);
    }
    return  results;
}

- (void) updateSchemaRevision
{
    if (self.scheduledTask) {
        self.scheduledTask.taskSchemaRevision = [NSNumber numberWithInteger:kWalkingActivitySchemaRevision];
    }
}


@end
