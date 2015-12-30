//
//  APHMomentInDayStep.m
//  mPowerSDK
//
//  Copyright (c) 2015 Apple, Inc. All rights reserved.
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
#import "APHAppDelegate.h"


//
//    keys for the extra step ('Pre-Survey') that;'s injected
//        into Parkinson Activities to ask the Patient if they
//        have taken their medications
//
NSString  *const kMomentInDayStepIdentifier             = @"momentInDay";
NSString  *const kMomentInDayFormat                     = @"momentInDayFormat";
NSString  *const kMomentInDayNoneChoice                 = @"I don't take Parkinson medications";

//
//    key for Parkinson Stashed Question Result
//        from 'When Did You Take Your Medicine' Pre-Survey Question
//
NSString  *const kMomentInDayUserDefaultsKey            = @"MomentInDayUserDefaults";

//
//    keys for Parkinson Stashed Question Result Dictionary
//        from 'When Did You Take Your Medicine' Pre-Survey Question
//
NSString  *const kMomentInDayChoiceAnswerKey            = @"MomentInDayChoiceAnswer";
NSString  *const kMomentInDayQuestionTypeKey            = @"MomentInDayQuestionType";
NSString  *const kMomentInDayIdentifierKey              = @"MomentInDayIdentifier";
NSString  *const kMomentInDayStartDateKey               = @"MomentInDayStartDate";
NSString  *const kMomentInDayEndDateKey                 = @"MomentInDayEndDate";
NSString  *const kMomentInDayChoiceNoneKey              = @"MomentInDayNoneChoice";

//
// constants for setting up the tapping activity
//
NSString       *const kIntervalTappingTitleIdentifier       = @"Tapping Activity";
NSTimeInterval  const kTappingStepCountdownInterval         = 20.0;

//
// constants for setting up the tapping activity
//
NSString       *const kVoiceTitleIdentifier                 = @"Voice Activity";
NSTimeInterval  const kGetSoundingAaahhhInterval            = 10.0;

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
static  NSUInteger      kNumberOfStepsPerLeg                  = 20;
static  NSTimeInterval  kStandStillDuration                   = 30.0;

//
//    elapsed time delay before asking the patient if they took their medications
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowSurvey         = 20.0 * 60.0;
static  NSTimeInterval  kMinimumAmountOfTimeToShowSurveyIfNoMeds = 30.0 * 24.0 * 60.0 * 60.0;

@interface APHActivityManager ()

@property (nonatomic) NSUserDefaults *storedDefaults;
@property (nonatomic) NSDate *lastCompletionDate;
@property NSDictionary *stashedDictionary;

- (ORKFormStep *)createMomentInDayStep;
- (BOOL)shouldIncludeMomentInDayStep:(NSDate * _Nullable)lastCompletionDate;

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


#pragma mark - private properties

- (NSUserDefaults *)storedDefaults
{
    if (_storedDefaults == nil) {
        _storedDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _storedDefaults;
}

- (NSDictionary *)stashedSurvey
{
    return [self.storedDefaults objectForKey:kMomentInDayUserDefaultsKey];
}

- (void)setStashedSurvey:(NSDictionary *)dictionary
{
    if (dictionary) {
        [self.storedDefaults setObject:dictionary forKey:kMomentInDayUserDefaultsKey];
    }
    else {
        [self.storedDefaults removeObjectForKey:kMomentInDayUserDefaultsKey];
    }
    [self.storedDefaults synchronize];
}

- (NSDate *)lastCompletionDate
{
    if (_lastCompletionDate == nil) {
        // Allow custom setting of last completion date and only access the app delegate the last
        // completion date is not set.
        APHAppDelegate  *appDelegate = (APHAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate isKindOfClass:[APHAppDelegate class]]) {
            return appDelegate.dataSubstrate.currentUser.taskCompletion;
        }
    }
    return _lastCompletionDate;
}

#pragma mark - task manipulation

- (ORKOrderedTask *)createOrderedTaskForSurveyId:(NSString *)surveyId
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
    
    return [self modifyTaskIfRequired:task];
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
    
    //
    //    set up initial steps, which may have an extra step injected
    //    after the first if the user needs to say where they are in
    //    their medication schedule
    //
    NSString *localizedTaskName = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_TITLE", nil, APHLocaleBundle(),  @"Voice", @"Title for Voice activity");
    [orkTask.steps[0] setTitle:localizedTaskName];
    
    ORKInstructionStep *instructionStep = (ORKInstructionStep *)orkTask.steps[1];
    [instructionStep setTitle:localizedTaskName];
    [instructionStep setText:NSLocalizedStringWithDefaultValue(@"APH_PHONATION_STEP_INSTRUCTION", nil, APHLocaleBundle(), @"Take a deep breath and say “Aaaaah” into the microphone for as long as you can. Keep a steady volume so the audio bars remain blue.", @"Instructions for performing the voice activity.")];
    [instructionStep setDetailText:NSLocalizedStringWithDefaultValue(@"APH_NEXT_STEP_INSTRUCTION", nil, APHLocaleBundle(), @"Tap Next to begin the test.", @"Detail insctruction for how to begin a task.")];

    return  orkTask;
}

- (ORKOrderedTask *)createCustomMemoryTask
{
    return [ORKOrderedTask spatialSpanMemoryTaskWithIdentifier:kMemorySpanTitleIdentifier
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
    
    NSString  *titleFormat = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_TEXT_INSTRUCTION", nil, APHLocaleBundle(), @"Turn around and stand still for %@ seconds", @"Written instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *titleString = [NSString stringWithFormat:titleFormat, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    NSString  *spokenInstructionFormat = NSLocalizedStringWithDefaultValue(@"APH_WALKING_STAND_STILL_SPOKEN_INSTRUCTION", nil, APHLocaleBundle(), @"Turn around and stand still for %@ seconds", @"Spoken instructions for the standing-still step of the walking activity, to be filled in with the number of seconds to stand still.");
    NSString  *spokenInstructionString = [NSString stringWithFormat:spokenInstructionFormat, APHLocalizedStringFromNumber(@(kStandStillDuration))];
    
    ORKActiveStep *activeStep = (ORKActiveStep *)orkTask.steps[5];
    [activeStep setTitle:titleString];
    [activeStep setSpokenInstruction:spokenInstructionString];
    
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

- (ORKOrderedTask *)modifyTaskIfRequired:(ORKOrderedTask *)task
{
    ORKOrderedTask  *replacementTask = task;
    
    if ([self shouldIncludeMomentInDayStep:self.lastCompletionDate])
    {
        ORKStep *step = [self createMomentInDayStep];
        NSMutableArray  *newSteps = [task.steps mutableCopy];
        if ([newSteps count] >= 1) {
            [newSteps insertObject:step atIndex:1];
        }
        replacementTask = [[ORKOrderedTask alloc] initWithIdentifier:task.identifier steps:newSteps];
    }
    
    // Replace the language in the last step
    [replacementTask.steps.lastObject setTitle:NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_TEXT", nil, APHLocaleBundle(), @"Thank You!", @"Main text shown to participant upon completion of an activity.") ];
    [replacementTask.steps.lastObject setText:NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_DETAIL", nil, APHLocaleBundle(), @"The results of this activity can be viewed on the dashboard", @"Detail text shown to participant upon completion of an activity.")];
    
    return  replacementTask;
}

- (ORKFormStep * _Nonnull)createMomentInDayStep
{
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_INTRO", nil, APHLocaleBundle(), @"We would like to understand how your performance on this activity could be affected by the timing of your medication.", @"Explanation of purpose of pre-activity medication timing survey.");
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:kMomentInDayStepIdentifier title:nil text:title];
    
    step.optional = NO;
    
    NSString *itemText = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_QUESTION", nil, APHLocaleBundle(), @"When was the last time you took any of your PARKINSON MEDICATIONS?", @"Prompt for timing of medication in pre-activity medication timing survey.");
    
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:[self momentInDayChoices]];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:kMomentInDayFormat
                                                            text:itemText
                                                    answerFormat:format];
    [step setFormItems:@[item]];
        
    return step;
}

- (NSArray <ORKTextChoice *> *) momentInDayChoices
{
    NSString *formatMinutes = NSLocalizedStringWithDefaultValue(@"APH_MINUTES_RANGE_FORMAT", nil, APHLocaleBundle(),
                                                                @"%1$@-%2$@ minutes ago", @"Format for a time interval of %1$@ to %2$@ minutes ago where %1$@ is the localized number for the smaller value and %2$@ is the localized number for the larger value.");
    NSString *formatHours = NSLocalizedStringWithDefaultValue(@"APH_HOURS_RANGE_FORMAT", nil, APHLocaleBundle(),
                                                              @"%1$@-%2$@ hours ago", @"Format for a time interval of %1$@ to %2$@ hours ago where %1$@ is the localized number for the smaller value and %2$@ is the localized number for the larger value.");
    NSString *formatMoreThanHoursAgo = NSLocalizedStringWithDefaultValue(@"APH_MORE_THAN_HOURS_FORMAT", nil, APHLocaleBundle(), @"More than %@ hours ago", @"Timing option text in pre-activity medication timing survey for more than %@ hours ago.");
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    __block NSMutableArray <ORKTextChoice *> *choices = [NSMutableArray array];
    
    // NOTE: See BRIDGE-138 for details. syoung 12/28/2015 Having the choices map to a result that is in English
    // is intentional and should *not* be localized.
    void (^addInterval)(NSUInteger, NSUInteger) = ^(NSUInteger minTime, NSUInteger maxTime) {
        
        NSString *text = nil;
        NSString *value = nil;
        if (minTime < maxTime) {
            if ((minTime % 60 == 0) && (maxTime % 60 == 0)) {
                NSUInteger minHours = minTime/60;
                NSUInteger maxHours = maxTime/60;
                value = [NSString stringWithFormat:@"%1$@-%2$@ hours ago", @(minHours), @(maxHours)];
                text = [NSString stringWithFormat:formatHours, [numberFormatter stringForObjectValue:@(minHours)], [numberFormatter stringForObjectValue:@(maxHours)]];
            }
            else {
                value = [NSString stringWithFormat:@"%1$@-%2$@ minutes ago", @(minTime), @(maxTime)];
                text = [NSString stringWithFormat:formatMinutes, [numberFormatter stringForObjectValue:@(minTime)], [numberFormatter stringForObjectValue:@(maxTime)]];
            }
        }
        else {
            NSUInteger hours = minTime/60;
            value = [NSString stringWithFormat:@"More than %@ hours ago", @(hours)];
            text = [NSString stringWithFormat:formatMoreThanHoursAgo, [numberFormatter stringForObjectValue:@(hours)]];
        }
        
        [choices addObject:[ORKTextChoice choiceWithText:text value:value]];
    };
    
    addInterval(0, 30);
    addInterval(30, 60);
    addInterval(1 * 60, 2 * 60);
    addInterval(2 * 60, 4 * 60);
    addInterval(4 * 60, 8 * 60);
    addInterval(8 * 60, 0);
    
    // Add the "not sure" choice to both the choices array and the map
    [choices addObject:[ORKTextChoice choiceWithText:
                        NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_NOT_SURE", nil, APHLocaleBundle(), @"Not sure", @"Timing option text in pre-activity medication timing survey for someone who is unsure of when medication was last taken.")
                                               value:@"Not sure"]];
    
    // Add the "not applicable" choice to both arrays
    
    [choices addObject:[ORKTextChoice choiceWithText:NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_NOT_APPLICABLE", nil, APHLocaleBundle(), @"I don't take Parkinson medications", @"Timing option text in pre-activity medication timing survey for someone who doesn't take medication.")
                                               value:kMomentInDayNoneChoice]];
    
    // Copy the arrays to static values
    return [choices copy];

}

- (BOOL)shouldIncludeMomentInDayStep:(NSDate * _Nullable)lastCompletionDate
{
    NSDictionary  *stashedSurvey = [self stashedSurvey];
    
    if (lastCompletionDate == nil || stashedSurvey == nil) {
        return YES;
    }
    
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: lastCompletionDate];
    BOOL noMeds = [stashedSurvey[kMomentInDayChoiceNoneKey] boolValue];
    NSTimeInterval minInterval = noMeds ? kMinimumAmountOfTimeToShowSurveyIfNoMeds : kMinimumAmountOfTimeToShowSurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (void)saveMomentInDayResult:(ORKStepResult * _Nullable)stepResult
{
    if ([stepResult.results count] > 0) {
        id  object = [stepResult.results lastObject];
        if ([object isKindOfClass:[ORKChoiceQuestionResult class]] == YES) {
            ORKChoiceQuestionResult  *result = (ORKChoiceQuestionResult *)object;
            NSString *answer = result.choiceAnswers.lastObject;
            if (answer != nil) {
                NSDictionary  *dictionary = @{
                                              kMomentInDayChoiceAnswerKey : answer,
                                              kMomentInDayQuestionTypeKey : @(result.questionType),
                                              kMomentInDayIdentifierKey   : result.identifier,
                                              kMomentInDayStartDateKey    : result.startDate,
                                              kMomentInDayEndDateKey      : result.endDate,
                                              kMomentInDayChoiceNoneKey   : @([kMomentInDayNoneChoice isEqualToString:answer])
                                              };
                [self setStashedSurvey:dictionary];
            }
        }
    }
}

- (ORKStepResult * _Nullable)stashedMomentInDayResult
{
    ORKStepResult *aResult = nil;
    NSDictionary  *stashedSurvey = [self stashedSurvey];
    NSString *surveyId = stashedSurvey[kMomentInDayIdentifierKey];
    NSString *answer = stashedSurvey[kMomentInDayChoiceAnswerKey];
    
    if ((surveyId != nil) && (answer != nil)) {
        ORKChoiceQuestionResult *stashedResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:surveyId];
        stashedResult.questionType = [stashedSurvey[kMomentInDayQuestionTypeKey] unsignedIntegerValue];
        stashedResult.startDate = stashedSurvey[kMomentInDayStartDateKey];
        stashedResult.endDate = stashedSurvey[kMomentInDayEndDateKey];
        stashedResult.choiceAnswers = @[answer];
        
        aResult = [[ORKStepResult alloc] initWithStepIdentifier:kMomentInDayStepIdentifier
                                                        results:@[stashedResult]];
    }
    
    return aResult;
}



@end
