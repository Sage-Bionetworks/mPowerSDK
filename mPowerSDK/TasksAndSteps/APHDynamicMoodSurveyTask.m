// 
//  APHDynamicMoodSurveyTask.m 
//  mPowerSDK
//
// Copyright (c) 2015, 2016, Sage Bionetworks. All rights reserved.
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
 
#import "APHDynamicMoodSurveyTask.h"
#import "APHLocalization.h"

static  NSString  *MainStudyIdentifier  = @"com.breastcancer.moodsurvey";
static  NSString  *kMoodSurveyTaskIdentifier  = @"Mood Survey";

static  NSString  *kMoodSurveyStep101   = @"moodsurvey101";
static  NSString  *kMoodSurveyStep102   = @"moodsurvey102";
static  NSString  *kMoodSurveyStep103   = @"moodsurvey103";
static  NSString  *kMoodSurveyStep104   = @"moodsurvey104";
static  NSString  *kMoodSurveyStep105   = @"moodsurvey105";
static  NSString  *kMoodSurveyStep106   = @"moodsurvey106";
static  NSString  *kMoodSurveyStep107   = @"moodsurvey107";
static  NSString  *kMoodSurveyStep108   = @"moodsurvey108";

static  NSString  *kCustomMoodSurveyStep101   = @"customMoodSurveyStep101";
static  NSString  *kCustomMoodSurveyStep102   = @"customMoodSurveyStep102";
static  NSString  *kCustomMoodSurveyStep103   = @"customMoodSurveyStep103";

static NSInteger const kNumberOfCompletionsUntilDisplayingCustomSurvey = 6;

static NSInteger const kTextAnswerFormatWithMaximumLength = 90;

typedef NS_ENUM(NSUInteger, APHDynamicMoodSurveyType) {
    APHDynamicMoodSurveyTypeIntroduction = 0,
    APHDynamicMoodSurveyTypeCustomInstruction,
    APHDynamicMoodSurveyTypeCustomQuestionEntry,
    APHDynamicMoodSurveyTypeClarity,
    APHDynamicMoodSurveyTypeMood,
    APHDynamicMoodSurveyTypeEnergy,
    APHDynamicMoodSurveyTypeSleep,
    APHDynamicMoodSurveyTypeExercise,
    APHDynamicMoodSurveyTypeCustomSurvey,
    APHDynamicMoodSurveyTypeConclusion
};

@interface APHDynamicMoodSurveyTask()
@property (nonatomic, strong) NSDictionary *keys;
@property (nonatomic, strong) NSDictionary *backwardKeys;

@property (nonatomic, strong) NSString *customSurveyQuestion;

@property (nonatomic) NSInteger currentState;
@property (nonatomic) NSInteger currentCount;
@property (nonatomic, strong) NSDictionary *currentOrderedSteps;


@end
@implementation APHDynamicMoodSurveyTask

- (instancetype) initAddingSteps {
    
    NSArray* moodValueForIndex = @[@(5), @(4), @(3), @(2), @(1)];
    
    NSDictionary  *questionAnswerDictionary = @{
                                                
                                                
                                                
                                                kMoodSurveyStep102 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_GREAT", nil, APHLocaleBundle(), @"perfectly crisp!", @"Mood Survey Mental Clarity question Great answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_GOOD", nil, APHLocaleBundle(), @"crisp", @"Mood Survey Mental Clarity question Good answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_AVERAGE", nil, APHLocaleBundle(), @"\"not great, but not too bad\"", @"Mood Survey Mental Clarity question Averge answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_BAD", nil, APHLocaleBundle(), @"foggy", @"Mood Survey Mental Clarity question Bad answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_TERRIBLE", nil, APHLocaleBundle(), @"poor", @"Mood Survey Mental Clarity question Terrible answer")
                                                                       ],
                                                
                                                kMoodSurveyStep103 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_GREAT", nil, APHLocaleBundle(), @"fantastic!", @"Mood Survey Mood question Great answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_GOOD", nil, APHLocaleBundle(), @"better than usual", @"Mood Survey Mood question Good answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_AVERAGE", nil, APHLocaleBundle(), @"normal", @"Mood Survey Mood question Averge answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_BAD", nil, APHLocaleBundle(), @"down", @"Mood Survey Mood question Bad answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_TERRIBLE", nil, APHLocaleBundle(), @"at my lowest", @"Mood Survey Mood question Terrible answer")
                                                                       ],
                                                
                                                kMoodSurveyStep104 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_GREAT", nil, APHLocaleBundle(), @"no hurt", @"Mood Survey Pain Level question Great answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_GOOD", nil, APHLocaleBundle(), @"hurts a little bit", @"Mood Survey Pain Level question Good answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_AVERAGE", nil, APHLocaleBundle(), @"hurts even more", @"Mood Survey Pain Level question Averge answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_BAD", nil, APHLocaleBundle(), @"hurts a whole lot", @"Mood Survey Pain Level question Bad answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_TERRIBLE", nil, APHLocaleBundle(), @"hurts worst", @"Mood Survey Pain Level question Terrible answer")
                                                                       ],
                                                
                                                kMoodSurveyStep105 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_GREAT", nil, APHLocaleBundle(), @"best sleep ever", @"Mood Survey Sleep Quality question Great answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_GOOD", nil, APHLocaleBundle(), @"better sleep than usual", @"Mood Survey Sleep Quality question Good answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_AVERAGE", nil, APHLocaleBundle(), @"OK sleep", @"Mood Survey Sleep Quality question Averge answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_BAD", nil, APHLocaleBundle(), @"I wish I slept more", @"Mood Survey Sleep Quality question Bad answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_TERRIBLE", nil, APHLocaleBundle(), @"no sleep", @"Mood Survey Sleep Quality question Terrible answer")
                                                                       ],
                                                
                                                kMoodSurveyStep106 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_GREAT", nil, APHLocaleBundle(), @"strenuous exercise (heart beats rapidly)", @"Mood Survey Exercise question Great answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_GOOD", nil, APHLocaleBundle(), @"moderate exercise (tiring but not exhausting)", @"Mood Survey Exercise question Good answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_AVERAGE", nil, APHLocaleBundle(), @"mild exercise (some effort)", @"Mood Survey Exercise question Averge answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_BAD", nil, APHLocaleBundle(), @"minimal exercise (no effort)", @"Mood Survey Exercise question Bad answer"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_TERRIBLE", nil, APHLocaleBundle(), @"no exercise", @"Mood Survey Exercise question Terrible answer")
                                                                       ],
                                                
                                                kMoodSurveyStep107 : @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_GREAT_PLACEHOLDER", nil, APHLocaleBundle(), @"great", @"Mood Survey Custom question Great answer (placeholder step)"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_GOOD_PLACEHOLDER", nil, APHLocaleBundle(), @"good", @"Mood Survey Custom question Good answer (placeholder step)"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_AVERAGE_PLACEHOLDER", nil, APHLocaleBundle(), @"average", @"Mood Survey Custom question Averge answer (placeholder step)"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_BAD_PLACEHOLDER", nil, APHLocaleBundle(), @"bad", @"Mood Survey Custom question Bad answer (placeholder step)"),
                                                                       NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_TERRIBLE_PLACEHOLDER", nil, APHLocaleBundle(), @"terrible", @"Mood Survey Custom question Terrible answer (placeholder step)")
                                                                       ],
                                                };
    
    NSMutableArray *steps = [NSMutableArray array];
    
    {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:kMoodSurveyStep101];
        step.detailText = nil;
        
        
        [steps addObject:step];
    }
    
    
    /**** Custom Survey Steps */
    
    {
        ORKInstructionStep *step = [[ORKInstructionStep alloc] initWithIdentifier:kCustomMoodSurveyStep101];
        step.title = NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOMIZE_TITLE", nil, APHLocaleBundle(), @"Customize Survey", @"Title (prompt) for page explaining about customizing Mood survey with your own question");
        step.detailText = NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOMIZE_TEXT", nil, APHLocaleBundle(), @"You now have the ability to create your own survey question. Tap Get Started to enter your question.", @"Text explaining about customizing Mood survey with your own question");

        [steps addObject:step];
    }
    
    {
        ORKQuestionStep *step = [[ORKQuestionStep alloc] initWithIdentifier:kCustomMoodSurveyStep102];
        
        step.text = NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_BAD", nil, APHLocaleBundle(), @"Customize your question.", @"Prompt for entering text for custom Mood survey question");
        
        
        ORKAnswerFormat *textAnswerFormat = [ORKAnswerFormat textAnswerFormatWithMaximumLength:kTextAnswerFormatWithMaximumLength];

        [step setAnswerFormat:textAnswerFormat];
        
        [steps addObject:step];
    }
    
    /*****/
    
    
    
    {
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyClarity-1g"],
                                  [UIImage imageNamed:@"MoodSurveyClarity-2g"],
                                  [UIImage imageNamed:@"MoodSurveyClarity-3g"],
                                  [UIImage imageNamed:@"MoodSurveyClarity-4g"],
                                  [UIImage imageNamed:@"MoodSurveyClarity-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyClarity-1p"],
                                          [UIImage imageNamed:@"MoodSurveyClarity-2p"],
                                          [UIImage imageNamed:@"MoodSurveyClarity-3p"],
                                          [UIImage imageNamed:@"MoodSurveyClarity-4p"],
                                          [UIImage imageNamed:@"MoodSurveyClarity-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep102];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep102
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_CLARITY_PROMPT", nil, APHLocaleBundle(), @"Today, my thinking is:", @"Prompt for Mood survey question about mental clarity")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    {
        
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyMood-1g"],
                                  [UIImage imageNamed:@"MoodSurveyMood-2g"],
                                  [UIImage imageNamed:@"MoodSurveyMood-3g"],
                                  [UIImage imageNamed:@"MoodSurveyMood-4g"],
                                  [UIImage imageNamed:@"MoodSurveyMood-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyMood-1p"],
                                          [UIImage imageNamed:@"MoodSurveyMood-2p"],
                                          [UIImage imageNamed:@"MoodSurveyMood-3p"],
                                          [UIImage imageNamed:@"MoodSurveyMood-4p"],
                                          [UIImage imageNamed:@"MoodSurveyMood-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep103];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep103
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_MOOD_PROMPT", nil, APHLocaleBundle(), @"Today, my mood is:", @"Prompt for Mood survey question about mood")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    {
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyPain-1g"],
                                  [UIImage imageNamed:@"MoodSurveyPain-2g"],
                                  [UIImage imageNamed:@"MoodSurveyPain-3g"],
                                  [UIImage imageNamed:@"MoodSurveyPain-4g"],
                                  [UIImage imageNamed:@"MoodSurveyPain-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyPain-1p"],
                                          [UIImage imageNamed:@"MoodSurveyPain-2p"],
                                          [UIImage imageNamed:@"MoodSurveyPain-3p"],
                                          [UIImage imageNamed:@"MoodSurveyPain-4p"],
                                          [UIImage imageNamed:@"MoodSurveyPain-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep104];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep104
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_PAIN_PROMPT", nil, APHLocaleBundle(), @"Today, my pain level is:", @"Prompt for Mood survey question about pain level")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    {
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveySleep-1g"],
                                  [UIImage imageNamed:@"MoodSurveySleep-2g"],
                                  [UIImage imageNamed:@"MoodSurveySleep-3g"],
                                  [UIImage imageNamed:@"MoodSurveySleep-4g"],
                                  [UIImage imageNamed:@"MoodSurveySleep-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveySleep-1p"],
                                          [UIImage imageNamed:@"MoodSurveySleep-2p"],
                                          [UIImage imageNamed:@"MoodSurveySleep-3p"],
                                          [UIImage imageNamed:@"MoodSurveySleep-4p"],
                                          [UIImage imageNamed:@"MoodSurveySleep-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep105];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep105
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_SLEEP_PROMPT", nil, APHLocaleBundle(), @"The quality of my sleep last night was:", @"Prompt for Mood Survey question about sleep quality")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    {
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyExercise-1g"],
                                  [UIImage imageNamed:@"MoodSurveyExercise-2g"],
                                  [UIImage imageNamed:@"MoodSurveyExercise-3g"],
                                  [UIImage imageNamed:@"MoodSurveyExercise-4g"],
                                  [UIImage imageNamed:@"MoodSurveyExercise-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyExercise-1p"],
                                          [UIImage imageNamed:@"MoodSurveyExercise-2p"],
                                          [UIImage imageNamed:@"MoodSurveyExercise-3p"],
                                          [UIImage imageNamed:@"MoodSurveyExercise-4p"],
                                          [UIImage imageNamed:@"MoodSurveyExercise-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep106];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep106
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_EXERCISE_PROMPT", nil, APHLocaleBundle(), @"The most I exercised in the last day was:", @"Prompt for Mood Survey question about exercise level")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    {
        NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyCustom-1g"],
                                  [UIImage imageNamed:@"MoodSurveyCustom-2g"],
                                  [UIImage imageNamed:@"MoodSurveyCustom-3g"],
                                  [UIImage imageNamed:@"MoodSurveyCustom-4g"],
                                  [UIImage imageNamed:@"MoodSurveyCustom-5g"]];
        
        NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyCustom-1p"],
                                          [UIImage imageNamed:@"MoodSurveyCustom-2p"],
                                          [UIImage imageNamed:@"MoodSurveyCustom-3p"],
                                          [UIImage imageNamed:@"MoodSurveyCustom-4p"],
                                          [UIImage imageNamed:@"MoodSurveyCustom-5p"]];
        
        NSArray *textDescriptionChoice = [questionAnswerDictionary objectForKey:kMoodSurveyStep107];
        
        
        NSMutableArray *answerChoices = [NSMutableArray new];
        
        for (NSUInteger i = 0; i<[imageChoices count]; i++) {
            
            ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
            
            [answerChoices addObject:answerOption];
        }
        
        ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep107
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_PROMPT", nil, APHLocaleBundle(), @"Custom Survey Question?", @"Placeholder for prompt for Mood Survey custom question")
                                                                     answer:format];
        
        [steps addObject:step];
    }
    
    
    {
        
        ORKQuestionStep *step = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep108
                                                                      title:NSLocalizedStringWithDefaultValue(@"APH_MOOD_108_PROMPT", nil, APHLocaleBundle(), @"What level exercise are you getting today?", @"(Does not appear to be actually used~emm2016-02-11)")
                                                                     answer:nil];
        
        [steps addObject:step];
    }
    self  = [super initWithIdentifier:kMoodSurveyTaskIdentifier steps:steps];
    
    return self;
}

- (ORKStep *)stepAfterStep:(ORKStep *)step withResult:(ORKTaskResult *)result
{
    BOOL completedNumberOfTimes = NO;
    
    //Check if we have reached the threshold to display customizing a survey question.
    APCAppDelegate * delegate = (APCAppDelegate*)[UIApplication sharedApplication].delegate;
    
    if (delegate.dataSubstrate.currentUser.dailyScalesCompletionCounter == kNumberOfCompletionsUntilDisplayingCustomSurvey && delegate.dataSubstrate.currentUser.customSurveyQuestion == nil) {
        completedNumberOfTimes = YES;
        
        ORKStepResult *stepResult = [result stepResultForStepIdentifier:kCustomMoodSurveyStep102];
        ORKTextQuestionResult *textQuestionResult = (ORKTextQuestionResult *) stepResult.results.firstObject;
        NSString *skipQuestion = [textQuestionResult textAnswer];
        
        if (skipQuestion != nil) {
            if ([step.identifier isEqualToString:kMoodSurveyStep108])
            {
                [delegate.dataSubstrate.currentUser setCustomSurveyQuestion:skipQuestion];
            }
            
            self.customSurveyQuestion = skipQuestion;
        } else {
            [delegate.dataSubstrate.currentUser setCustomSurveyQuestion:skipQuestion];
            self.customSurveyQuestion = skipQuestion;
        }
    }
    
    if (delegate.dataSubstrate.currentUser.customSurveyQuestion) {
        self.customSurveyQuestion = delegate.dataSubstrate.currentUser.customSurveyQuestion;
    }

    //set the basic state
    [self setFlowState:0];
    
    
    if ([step.identifier isEqualToString:kMoodSurveyStep108] && delegate.dataSubstrate.currentUser.customSurveyQuestion && delegate.dataSubstrate.currentUser.dailyScalesCompletionCounter == kNumberOfCompletionsUntilDisplayingCustomSurvey)
    {
        [self setFlowState:4];
    }
    else if (delegate.dataSubstrate.currentUser.customSurveyQuestion)
    {
        //Used only if the custom question is already being set in profile.
        [self setFlowState:1];
    }
    
    else if (self.customSurveyQuestion != nil && ![step.identifier isEqualToString:kCustomMoodSurveyStep102] && delegate.dataSubstrate.currentUser.dailyScalesCompletionCounter != kNumberOfCompletionsUntilDisplayingCustomSurvey)
    {
        //If there is a custom question present custom survey
        [self setFlowState:2];
    }
    
    else if (completedNumberOfTimes && self.customSurveyQuestion == nil)

    {
        [self setFlowState:3];
        
    }

    else if (completedNumberOfTimes)
    
    {
        //This is the Daily Check-in with custom survey question and with custom survey
        [self setFlowState:4];
    }

    
    if (step == nil)
    {
        step = self.steps[0];
        self.currentCount = 1;
    }
    
    else if ([[self.steps[self.steps.count - 1] identifier] isEqualToString:step.identifier])
    {
        step = nil;
    }
    else
    {
        NSNumber *index = (NSNumber *) self.keys[step.identifier];
        
        step = self.steps[[index intValue]];
        
        self.currentCount = [index integerValue];
    
    }
    
    if ([step.identifier isEqualToString:kMoodSurveyStep107] && self.customSurveyQuestion != nil) {
        step = [self customQuestionStep:self.customSurveyQuestion];
    }
    
    return step;
}

- (ORKStep *)stepBeforeStep:(ORKStep *)step withResult:(ORKTaskResult *) __unused result
{
    if ([[self.steps[0] identifier] isEqualToString:step.identifier]) {
        step = nil;
    }
    
    else
    {
        NSNumber *index = (NSNumber *) self.backwardKeys[step.identifier];
        
        step = self.steps[[index intValue]];
    }
    
    if ([step.identifier isEqualToString:kMoodSurveyStep107] && self.customSurveyQuestion != nil) {
        step = [self customQuestionStep:self.customSurveyQuestion];
    }
    
    return step;
}

- (ORKTaskProgress)progressOfCurrentStep:(ORKStep *)step withResult:(ORKTaskResult *) __unused result
{
    
    return ORKTaskProgressMake([[self.currentOrderedSteps objectForKey:step.identifier] integerValue] - 1, self.currentOrderedSteps.count);
}

- (void) setFlowState:(NSInteger)state {
    
    self.currentState = state;
    
    switch (state) {
        case 0:
        {
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeExercise),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeClarity),
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kMoodSurveyStep102       : @(2),
                                            kMoodSurveyStep103       : @(3),
                                            kMoodSurveyStep104       : @(4),
                                            kMoodSurveyStep105       : @(5),
                                            kMoodSurveyStep106       : @(6),
                                            kMoodSurveyStep108       : @(7)
                                            };
            
        }
            break;
        case 1:
        {
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeConclusion),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kMoodSurveyStep107       : @(2),
                                            kMoodSurveyStep102       : @(3),
                                            kMoodSurveyStep103       : @(4),
                                            kMoodSurveyStep104       : @(5),
                                            kMoodSurveyStep105       : @(6),
                                            kMoodSurveyStep106       : @(7),
                                            kMoodSurveyStep108       : @(8)
                                            };

        }
            break;
        case 2:
        {
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeConclusion),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kMoodSurveyStep107       : @(2),
                                            kMoodSurveyStep102       : @(3),
                                            kMoodSurveyStep103       : @(4),
                                            kMoodSurveyStep104       : @(5),
                                            kMoodSurveyStep105       : @(6),
                                            kMoodSurveyStep106       : @(7),
                                            kMoodSurveyStep108       : @(8)
                                            };


        }
            break;
            
        case 3:
        {
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kCustomMoodSurveyStep102 : @(APHDynamicMoodSurveyTypeCustomInstruction),
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeCustomQuestionEntry),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeCustomInstruction),
                                            kCustomMoodSurveyStep101 : @(APHDynamicMoodSurveyTypeCustomQuestionEntry),
                                            kCustomMoodSurveyStep102 : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kCustomMoodSurveyStep101 : @(2),
                                            kCustomMoodSurveyStep102 : @(3),
                                            kMoodSurveyStep102       : @(4),
                                            kMoodSurveyStep103       : @(5),
                                            kMoodSurveyStep104       : @(6),
                                            kMoodSurveyStep105       : @(7),
                                            kMoodSurveyStep106       : @(8),
                                            kMoodSurveyStep108       : @(9)
                                            };

        }
            break;
            
        case 4:
        {
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kCustomMoodSurveyStep102 : @(APHDynamicMoodSurveyTypeCustomInstruction),
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeCustomQuestionEntry),
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeExercise),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeCustomInstruction),
                                            kCustomMoodSurveyStep101 : @(APHDynamicMoodSurveyTypeCustomQuestionEntry),
                                            kCustomMoodSurveyStep102 : @(APHDynamicMoodSurveyTypeCustomSurvey),
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kCustomMoodSurveyStep101 : @(2),
                                            kCustomMoodSurveyStep102 : @(3),
                                            kMoodSurveyStep107       : @(4),
                                            kMoodSurveyStep102       : @(5),
                                            kMoodSurveyStep103       : @(6),
                                            kMoodSurveyStep104       : @(7),
                                            kMoodSurveyStep105       : @(8),
                                            kMoodSurveyStep106       : @(9),
                                            kMoodSurveyStep108       : @(10)
                                            };
        }
            break;
            
        default:{
            self.backwardKeys           = @{
                                            kMoodSurveyStep101       : [NSNull null],
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeIntroduction),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeClarity),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : @(APHDynamicMoodSurveyTypeExercise),
                                            
                                            };
            
            self.keys                   = @{
                                            kMoodSurveyStep101       : @(APHDynamicMoodSurveyTypeClarity),
                                            kCustomMoodSurveyStep101 : [NSNull null],
                                            kCustomMoodSurveyStep102 : [NSNull null],
                                            kMoodSurveyStep102       : @(APHDynamicMoodSurveyTypeMood),
                                            kMoodSurveyStep103       : @(APHDynamicMoodSurveyTypeEnergy),
                                            kMoodSurveyStep104       : @(APHDynamicMoodSurveyTypeSleep),
                                            kMoodSurveyStep105       : @(APHDynamicMoodSurveyTypeExercise),
                                            kMoodSurveyStep106       : @(APHDynamicMoodSurveyTypeConclusion),
                                            kMoodSurveyStep107       : [NSNull null],
                                            kMoodSurveyStep108       : [NSNull null]
                                            };
            
            self.currentOrderedSteps    = @{
                                            kMoodSurveyStep101       : @(1),
                                            kMoodSurveyStep102       : @(2),
                                            kMoodSurveyStep103       : @(3),
                                            kMoodSurveyStep104       : @(4),
                                            kMoodSurveyStep105       : @(5),
                                            kMoodSurveyStep106       : @(6),
                                            kMoodSurveyStep108       : @(7)
                                            };
           
        }
            break;
    }
}

- (ORKQuestionStep *) customQuestionStep:(NSString *) __unused question {
    
    NSArray* moodValueForIndex = @[@(5), @(4), @(3), @(2), @(1)];
    
    NSArray *imageChoices = @[[UIImage imageNamed:@"MoodSurveyCustom-1g"],
                              [UIImage imageNamed:@"MoodSurveyCustom-2g"],
                              [UIImage imageNamed:@"MoodSurveyCustom-3g"],
                              [UIImage imageNamed:@"MoodSurveyCustom-4g"],
                              [UIImage imageNamed:@"MoodSurveyCustom-5g"]];
    
    NSArray *selectedImageChoices = @[[UIImage imageNamed:@"MoodSurveyCustom-1p"],
                                      [UIImage imageNamed:@"MoodSurveyCustom-2p"],
                                      [UIImage imageNamed:@"MoodSurveyCustom-3p"],
                                      [UIImage imageNamed:@"MoodSurveyCustom-4p"],
                                      [UIImage imageNamed:@"MoodSurveyCustom-5p"]];
    
    NSArray *textDescriptionChoice = @[NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_GREAT", nil, APHLocaleBundle(), @"Great", @"Mood Survey Custom question Great answer"),
                                        NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_GOOD", nil, APHLocaleBundle(), @"Good", @"Mood Survey Custom question Good answer"),
                                        NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_AVERAGE", nil, APHLocaleBundle(), @"Average", @"Mood Survey Custom question Averge answer"),
                                        NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_BAD", nil, APHLocaleBundle(), @"Bad", @"Mood Survey Custom question Bad answer"),
                                        NSLocalizedStringWithDefaultValue(@"APH_MOOD_CUSTOM_TERRIBLE", nil, APHLocaleBundle(), @"Terrible", @"Mood Survey Custom question Terrible answer")
                                      ];
    
    NSMutableArray *answerChoices = [NSMutableArray new];
    
    for (NSUInteger i = 0; i<[imageChoices count]; i++) {
        
        ORKImageChoice *answerOption = [ORKImageChoice choiceWithNormalImage:imageChoices[i] selectedImage:selectedImageChoices[i] text:textDescriptionChoice[i] value:[moodValueForIndex objectAtIndex:i]];
        
        [answerChoices addObject:answerOption];
    }
    
    ORKImageChoiceAnswerFormat *format = [[ORKImageChoiceAnswerFormat alloc] initWithImageChoices:answerChoices];
    
    ORKQuestionStep *questionStep = [ORKQuestionStep questionStepWithIdentifier:kMoodSurveyStep107
                                                                          title:self.customSurveyQuestion
                                                                         answer:format];
    
    return questionStep;
}

@end
