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

#import "APHMomentInDayStepManager.h"
#import "APHLocalization.h"

//
//    keys for the extra step ('Pre-Survey') that;'s injected
//        into Parkinson Activities to ask the Patient if they
//        have taken their medications
//
NSString  *const kMomentInDayStepIdentifier             = @"momentInDay";

NSString  *const kMomentInDayFormat                     = @"momentInDayFormat";

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
//    elapsed time delay before asking the patient if they took their medications
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowSurvey         = 20.0 * 60.0;
static  NSTimeInterval  kMinimumAmountOfTimeToShowSurveyIfNoMeds = 30.0 * 24.0 * 60.0 * 60.0;

static NSArray <ORKTextChoice *>    * kMomentInDayChoices    = nil;
static NSString                     * kMomentInDayNoneChoice = nil;

@interface APHMomentInDayStepManager ()

@property (nonatomic) NSUserDefaults *storedDefaults;
@property NSDictionary *stashedDictionary;

@end

@implementation APHMomentInDayStepManager

+ (instancetype)defaultManager
{
    static APHMomentInDayStepManager * __manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __manager = [[APHMomentInDayStepManager alloc] init];
    });
    return __manager;
}

+ (void)initialize
{
    void (^localizeBlock)() = [^{
        
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
        kMomentInDayNoneChoice = @"I don't take Parkinson medications";
        [choices addObject:[ORKTextChoice choiceWithText:NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_NOT_APPLICABLE", nil, APHLocaleBundle(), @"I don't take Parkinson medications", @"Timing option text in pre-activity medication timing survey for someone who doesn't take medication.")
                                                   value:kMomentInDayNoneChoice]];
        
        // Copy the arrays to static values
        kMomentInDayChoices = [choices copy];

    } copy];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull __unused note) {
        localizeBlock();
    }];
    localizeBlock();
}



- (ORKFormStep * _Nonnull)createMomentInDayStep
{
    NSString *title = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_INTRO", nil, APHLocaleBundle(), @"We would like to understand how your performance on this activity could be affected by the timing of your medication.", @"Explanation of purpose of pre-activity medication timing survey.");
    ORKFormStep *step = [[ORKFormStep alloc] initWithIdentifier:kMomentInDayStepIdentifier title:nil text:title];
    
    step.optional = NO;
    
    NSString *itemText = NSLocalizedStringWithDefaultValue(@"APH_MOMENT_IN_DAY_QUESTION", nil, APHLocaleBundle(), @"When was the last time you took any of your PARKINSON MEDICATIONS?", @"Prompt for timing of medication in pre-activity medication timing survey.");
    
    ORKAnswerFormat  *format = [ORKTextChoiceAnswerFormat
                                choiceAnswerFormatWithStyle:ORKChoiceAnswerStyleSingleChoice
                                textChoices:kMomentInDayChoices];
    
    ORKFormItem  *item = [[ORKFormItem alloc] initWithIdentifier:kMomentInDayFormat
                                                            text:itemText
                                                    answerFormat:format];
    [step setFormItems:@[item]];
        
    return step;
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

- (ORKChoiceQuestionResult * _Nullable)stashedMomentInDayResult
{
    ORKChoiceQuestionResult  *aResult = nil;
    NSDictionary  *stashedSurvey = [self stashedSurvey];
    NSString *surveyId = stashedSurvey[kMomentInDayIdentifierKey];
    NSString *answer = stashedSurvey[kMomentInDayChoiceAnswerKey];
    
    if ((surveyId != nil) && (answer != nil)) {
        aResult = [[ORKChoiceQuestionResult alloc] initWithIdentifier:surveyId];
        aResult.questionType = [stashedSurvey[kMomentInDayQuestionTypeKey] unsignedIntegerValue];
        aResult.startDate = stashedSurvey[kMomentInDayStartDateKey];
        aResult.endDate = stashedSurvey[kMomentInDayEndDateKey];
        aResult.choiceAnswers = @[answer];
    }
    
    return aResult;
}

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

@end
