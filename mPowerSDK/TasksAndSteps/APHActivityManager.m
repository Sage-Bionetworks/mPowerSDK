//
//  APHMomentInDayStep.m
//  mPowerSDK
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

#import "APHActivityManager.h"
#import <AVFoundation/AVFoundation.h>
#import "APHLocalization.h"
#import "APHMedicationTrackerTask.h"
@import ResearchKit;

//
//    keys for the extra step ('Pre-Survey') that;'s injected
//        into Parkinson Activities to ask the Patient if they
//        have taken their medications
//
NSString  *const kMomentInDayStepIdentifier             = @"momentInDay";
NSString  *const kMomentInDayFormat                     = @"momentInDayFormat";
NSString  *const kMomentInDayNoneChoice                 = @"I don't take Parkinson medications";
NSString  *const kMomentInDayControlChoice              = @"Control Group";

//
//    key for Parkinson Stashed Question Result
//        from 'When Did You Take Your Medicine' Pre-Survey Question
//
NSString  *const kMomentInDayUserDefaultsKey            = @"MomentInDayUserDefaults";
NSString  *const kMedicationListDefaultsKey            = @"MedicationListUserDefaults";

//
// constants for setting up the tapping activity
//
NSString       *const kIntervalTappingTitleIdentifier       = @"Tapping Activity";
NSTimeInterval  const kTappingStepCountdownInterval         = 20.0;

//
// constants for setting up the voice activity
//
NSString       *const kVoiceTitleIdentifier                 = @"Voice Activity";
NSTimeInterval  const kGetSoundingAaahhhInterval            = 10.0;
NSString       *const kCountdownStepIdentifier              = @"countdown";

//
// constants for setting up the memory activity
//
NSString       *const kMemorySpanTitleIdentifier            = @"Memory Activity";
NSInteger       const kInitialSpan                          =  3;
NSInteger       const kMinimumSpan                          =  2;
NSInteger       const kMaximumSpan                          =  15;
NSTimeInterval  const kPlaySpeed                            = 1.0;
NSInteger       const kMaximumTests                         = 5;
NSInteger       const kMaxConsecutiveFailures               = 3;
BOOL            const kRequiresReversal                     = NO;

//
// constants for setting up the walking activity
//
static  NSString * const kWalkingOutboundStepIdentifier       = @"walking.outbound";
static  NSString * const kWalkingReturnStepIdentifier         = @"walking.return";
static  NSString * const kWalkingRestStepIdentifier           = @"walking.rest";
static  NSString       *kWalkingActivityTitle                 = @"Walking Activity";
static  NSUInteger      kNumberOfStepsPerLeg                  = 100;  // set to way more than 30 seconds worth
static  NSTimeInterval  kStandStillDuration                   = 30.0;
static  NSTimeInterval  kWalkDuration                         = 30.0; // we'll set the step duration back to this

//
// constants for setting up the tremor activity
//
static NSString *const kTremorAssessmentTitleIdentifier     = @"Tremor Activity";
static NSTimeInterval kTremorAssessmentStepDuration         = 10.0;


@interface APHActivityManager ()

@end

@implementation APHActivityManager

+ (instancetype)defaultManager
{
    static id __manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __manager = [[self alloc] init];
    });
    return __manager;
}

#pragma mark - task manipulation

- (id <ORKTask> _Nullable)createTaskForSurveyId:(NSString *)surveyId
{
    ORKOrderedTask *task = nil;
    
    if ([surveyId isEqualToString:APHTappingActivitySurveyIdentifier]) {
        task = [self createCustomTappingTask];
    }
    else if ([surveyId isEqualToString:APHVoiceActivitySurveyIdentifier]) {
        task = [self createCustomVoiceTask];
    }
    else if ([surveyId isEqualToString:APHMemoryActivitySurveyIdentifier]) {
        task = [self createCustomMemoryTask];
    }
    else if ([surveyId isEqualToString:APHWalkingActivitySurveyIdentifier]) {
        task = [self createCustomWalkingTask];
    }
    else if ([surveyId isEqualToString:APHTremorActivitySurveyIdentifier]) {
        task = [self createCustomTremorTask];
    }
    
    // Replace the language in the last step
    if ([surveyId isEqualToString:APHMemoryActivitySurveyIdentifier]) {
        [task.steps.lastObject setTitle:NSLocalizedStringWithDefaultValue(@"APH_MEMORY_CONCLUSION_TEXT", nil, APHLocaleBundle(), @"Good Job!", @"Main text shown to participant upon completion of memory activity.")];
    }
    else {
        [task.steps.lastObject setTitle:NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_TEXT", nil, APHLocaleBundle(), @"Thank You!", @"Main text shown to participant upon completion of an activity.")];
    }
    [task.steps.lastObject setText:NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_DETAIL", nil, APHLocaleBundle(), @"The results of this activity can be viewed on the dashboard", @"Detail text shown to participant upon completion of an activity.")];
    
    // Create a medication tracker task with this as a subtask
    return [[APHMedicationTrackerTask alloc] initWithDictionaryRepresentation:nil subTask:task];
}

- (ORKOrderedTask *)createCustomTappingTask
{
    ORKOrderedTask  *orkTask = [ORKOrderedTask twoFingerTappingIntervalTaskWithIdentifier:kIntervalTappingTitleIdentifier
                                                                   intendedUseDescription:nil
                                                                                 duration:kTappingStepCountdownInterval
                                                                                  options:0
                                                                              handOptions:APCTapHandOptionBoth];
    
    // Modify the first step to explain why this activity is valuable to the Parkinson's study
    ORKInstructionStep *firstStep = (ORKInstructionStep *)orkTask.steps.firstObject;
    [firstStep setText:NSLocalizedStringWithDefaultValue(@"APH_TAPPING_INTRO_TEXT", nil, APHLocaleBundle(), @"Speed of finger tapping can reflect severity of motor symptoms in Parkinson disease. This activity measures your tapping speed for each hand. Your medical provider may measure this differently.", @"Introductory text for the tapping activity.")];
    [firstStep setDetailText:@""];
    
    return  orkTask;
}

- (ORKOrderedTask *)createCustomVoiceTask
{
    NSDictionary  *audioSettings = @{ AVFormatIDKey         : @(kAudioFormatAppleLossless),
                                      AVNumberOfChannelsKey : @(1),
                                      AVSampleRateKey       : @(44100.0)
                                      };
    
    ORKOrderedTask  *orkTask = [ORKOrderedTask audioTaskWithIdentifier:kVoiceTitleIdentifier
                                                intendedUseDescription:nil
                                                     speechInstruction:nil
                                                shortSpeechInstruction:nil
                                                              duration:kGetSoundingAaahhhInterval
                                                     recordingSettings:audioSettings
                                                               options:0];

    NSString *localizedTaskName = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_TITLE", nil, APHLocaleBundle(),  @"Voice", @"Title for Voice activity");
    [orkTask.steps[0] setTitle:localizedTaskName];
    
    const NSUInteger instructionIdx = 1;
    if ((orkTask.steps.count > instructionIdx) &&
        [orkTask.steps[instructionIdx] isKindOfClass:[ORKInstructionStep class]])
    {
        ORKInstructionStep *instructionStep = (ORKInstructionStep *)orkTask.steps[instructionIdx];
        [instructionStep setTitle:localizedTaskName];
        [instructionStep setText:NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_INSTRUCTION", nil, APHLocaleBundle(), @"Take a deep breath and say “Aaaaah” into the microphone for as long as you can. Keep a steady volume so the audio bars remain blue.", @"Instructions for performing the voice activity.")];
        [instructionStep setDetailText:NSLocalizedStringWithDefaultValue(@"APH_NEXT_STEP_INSTRUCTION", nil, APHLocaleBundle(), @"Tap Next to begin the test.", @"Detail insctruction for how to begin a task.")];
    }
    
    // Inject a step to test audio levels
    const NSUInteger countdownIdx = 2;
    if ((orkTask.steps.count > countdownIdx) &&
        [orkTask.steps[countdownIdx].identifier isEqualToString:kCountdownStepIdentifier])
    {
        ORKStep *countdownStep = orkTask.steps[countdownIdx];
        countdownStep.text = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_VOLUME", nil, APHLocaleBundle(), @"Please wait while we check the ambient sound levels.", @"Text explaining that the phone is checking volume levels before a voice task.");
    }

    return  orkTask;
}

- (ORKOrderedTask *)createCustomMemoryTask
{
    ORKOrderedTask *orkTask = [ORKOrderedTask spatialSpanMemoryTaskWithIdentifier:kMemorySpanTitleIdentifier
                                        intendedUseDescription:nil
                                                   initialSpan:kInitialSpan
                                                   minimumSpan:kMinimumSpan
                                                   maximumSpan:kMaximumSpan
                                                     playSpeed:kPlaySpeed
                                                      maxTests:kMaximumTests
                                        maxConsecutiveFailures:kMaxConsecutiveFailures
                                             customTargetImage:nil
                                        customTargetPluralName:nil
                                               requireReversal:kRequiresReversal
                                                       options:ORKPredefinedTaskOptionNone];

    return orkTask;
}

- (ORKOrderedTask *)createCustomWalkingTask
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
    [instructionStep setText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_DESCRIPTION", nil, APHLocaleBundle(), @"This activity measures your gait (walk) and balance, which can be affected by Parkinson disease.", @"Description of purpose of walking activity.")];
    [instructionStep setDetailText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_CAUTION", nil, APHLocaleBundle(), @"Please do not continue if you cannot safely walk unassisted.", @"Warning regarding performing walking activity.")];
    
    ORKInstructionStep *instructionStep2 = (ORKInstructionStep *)orkTask.steps[1];
    [instructionStep2 setText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_DESCRIPTION_2", nil, APHLocaleBundle(), @"\u2022 Please wear a comfortable pair of walking shoes and find a flat, smooth surface for walking.\n\n\u2022 Try to walk continuously by turning at the ends of your path, as if you are walking around a cone.\n\n\u2022 Importantly, walk at your normal pace. You do not need to walk faster than usual.", @"Detailed instructions for performing walking activity.")];
    [instructionStep2 setDetailText:NSLocalizedStringWithDefaultValue(@"APH_WALKING_DESCRIPTION_2_DETAIL", nil, APHLocaleBundle(), @"Put your phone in a pocket or bag and follow the audio instructions.", @"Instructions for how to proceed to active step of walking activity.")];
    
    NSString  *titleFormatWalk = NSLocalizedStringWithDefaultValue(@"APH_WALKING_WALK_TEXT_INSTRUCTION", nil, APHLocaleBundle(), @"Walk back and forth for %@ seconds.", @"Written instructions for the walking step of the walking activity, to be filled in with the number of seconds to walk.");
    NSString  *titleStringWalk = [NSString stringWithFormat:titleFormatWalk, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    NSString  *spokenInstructionFormatWalk = NSLocalizedStringWithDefaultValue(@"APH_WALKING_WALK_SPOKEN_INSTRUCTION", nil, APHLocaleBundle(), @"Walk back and forth for %@ seconds.", @"Spoken instructions for the walking step of the walking activity, to be filled in with the number of seconds to walk.");
    NSString  *spokenInstructionStringWalk = [NSString stringWithFormat:spokenInstructionFormatWalk, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    
    ORKWalkingTaskStep *walkStep = (ORKWalkingTaskStep *)orkTask.steps[3];
    [walkStep setTitle:titleStringWalk];
    [walkStep setSpokenInstruction:spokenInstructionStringWalk];
    // we want to ignore steps and just go for 30 seconds, but can't disable step counting without disabling the
    // pedometer, so we've set way more steps than 30 seconds' worth, and here we'll to set the stepDuration
    // fallback value manually to 30 seconds.
    walkStep.stepDuration = kWalkDuration;
    
    NSString  *titleFormatStand = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_TEXT_INSTRUCTION", nil, APHLocaleBundle(), @"Turn around 360 degrees, then stand still, with your feet about shoulder-width apart. Rest your arms at your side and try to avoid moving for %@ seconds.", @"Written instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *titleStringStand = [NSString stringWithFormat:titleFormatStand, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    NSString  *spokenInstructionFormatStand = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_SPOKEN_INSTRUCTION", nil, APHLocaleBundle(), @"Turn around 360 degrees, then stand still, with your feet about shoulder-width apart. Rest your arms at your side and try to avoid moving for %@ seconds.", @"Spoken instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *spokenInstructionStringStand = [NSString stringWithFormat:spokenInstructionFormatStand, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    
    ORKActiveStep *standStep = (ORKActiveStep *)orkTask.steps[5];
    [standStep setTitle:titleStringStand];
    [standStep setSpokenInstruction:spokenInstructionStringStand];
    
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
    
    return  orkTask;
}

- (ORKOrderedTask *)createCustomTremorTask
{
    ORKTremorActiveTaskOption excludeTasks =
        ORKTremorActiveTaskOptionExcludeHandAtShoulderHeightElbowBent | ORKTremorActiveTaskOptionExcludeQueenWave;
    
    return [ORKOrderedTask tremorTestTaskWithIdentifier:kTremorAssessmentTitleIdentifier
                                 intendedUseDescription:nil
                                     activeStepDuration:kTremorAssessmentStepDuration
                                      activeTaskOptions:excludeTasks
                                                options:ORKPredefinedTaskOptionNone];
}

@end
