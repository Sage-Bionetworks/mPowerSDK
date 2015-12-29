// 
//  APHIntervalTappingTaskViewController.m 
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
 
#import "APHIntervalTappingTaskViewController.h"
#import "APHScoreCalculator.h"
#import <AVFoundation/AVFoundation.h>
#import "APHDataKeys.h"
#import "APHLocalization.h"
#import "APHActivityManager.h"

    //
    //        Step Identifiers
    //
static NSString *const kIntroductionStepIdentifier    = @"instruction";
static NSString *const kInstruction1StepIdentifier    = @"instruction1";
static NSString *const kConclusionStepIdentifier      = @"conclusion";

static  NSString       *kTaskViewControllerTitle      = @"Tapping Activity";
static  NSString       *kIntervalTappingTitle         = @"Tapping Activity";

static NSString * const kItemKey                    = @"item";
static NSString * const kIdentifierKey              = @"identifier";
static NSString * const kStartDateKey               = @"startDate";
static NSString * const kEndDateKey                 = @"endDate";
static NSString * const kUserInfoKey                = @"userInfo";


static  NSTimeInterval  kTappingStepCountdownInterval = 20.0;

static const NSInteger kTappingActivitySchemaRevision = 9;

@interface APHIntervalTappingTaskViewController  ( ) <NSObject>

@property  (nonatomic, assign)  BOOL                 preferStatusBarShouldBeHidden;

@end

@implementation APHIntervalTappingTaskViewController

#pragma  mark  -  Task Creation Methods

+ (ORKOrderedTask *)createOrkTask:(APCTask *) __unused scheduledTask
{
    ORKOrderedTask  *orkTask = [ORKOrderedTask twoFingerTappingIntervalTaskWithIdentifier:kIntervalTappingTitle
                                                                   intendedUseDescription:nil
                                                                                 duration:kTappingStepCountdownInterval
                                                                                  options:0
                                                                              handOptions:APCTapHandOptionBoth];
    
    // Modify the first step to explain why this activity is valuable to the Parkinson's study
    ORKInstructionStep *firstStep = (ORKInstructionStep *)orkTask.steps.firstObject;
    [firstStep setText:NSLocalizedStringWithDefaultValue(@"APH_TAPPING_INTRO_TEXT", nil, APHLocaleBundle(), @"Speed of finger tapping can reflect severity of motor symptoms in Parkinson disease. This activity measures your tapping speed for each hand. Your medical provider may measure this differently.", @"Introductory text for the tapping activity.")];
    [firstStep setDetailText:@""];
    
    // Modify the last step to change the language of the conclusion
    ORKStep *finalStep = orkTask.steps.lastObject;
    [finalStep setTitle:kConclusionStepThankYouTitle];
    [finalStep setText:kConclusionStepViewDashboard];
    

    
    ORKOrderedTask  *replacementTask = [[APHActivityManager defaultManager] modifyTaskWithPreSurveyStepIfRequired:orkTask
                                                                          andTitle:(NSString *)kIntervalTappingTitle];
    
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    return  replacementTask;
}


#pragma  mark  -  Results For Dashboard

- (NSString *)createResultSummary
{
    ORKTaskResult  *taskResults = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext * context) {

        // Start with a dictionary that has all the required keys preset to zero
        __block NSMutableDictionary *summary = [@{ APHRightSummaryNumberOfRecordsKey: @(0),
                                                   APHLeftSummaryNumberOfRecordsKey:  @(0),
                                                   APHRightScoreSummaryOfRecordsKey:  @(0),
                                                   APHLeftScoreSummaryOfRecordsKey:   @(0)} mutableCopy];
        
        // Use a block to morph the keys if a tapping result is found
        void (^addResult)(ORKTappingIntervalResult*) = ^(ORKTappingIntervalResult  * _Nonnull tapsterResults) {

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF = 0"];
            NSArray *allSamples = [tapsterResults.samples valueForKey:@"buttonIdentifier"];
            NSArray *tapSamples = [allSamples filteredArrayUsingPredicate:predicate];
            
            double scoreSummary = [[APHScoreCalculator sharedCalculator] scoreFromTappingResult:tapsterResults];
            
            scoreSummary = isnan(scoreSummary) ? 0 : scoreSummary;
            
            NSUInteger  numberOfSamples = allSamples.count - tapSamples.count;
            
            BOOL rightHand = [tapsterResults.identifier hasSuffix:APCRightHandIdentifier];
            NSString *numRecordsKey = rightHand ? APHRightSummaryNumberOfRecordsKey : APHLeftSummaryNumberOfRecordsKey;
            NSString *scoreKey = rightHand ? APHRightScoreSummaryOfRecordsKey : APHLeftScoreSummaryOfRecordsKey;
            summary[numRecordsKey] = @(numberOfSamples);
            summary[scoreKey] = @(scoreSummary);
        };
        
        // Iterate through all the steps to look for tapping results
        for (ORKStepResult  *stepResult  in  taskResults.results) {
            for (id  object  in  stepResult.results) {
                if ([object isKindOfClass:[ORKTappingIntervalResult class]] == YES) {
                    addResult(object);
                    break;  // if result is found, break
                }
            }
        }

        // Convert the dictionary into json serializaed data and then to UTF8 string
        NSError  *error = nil;
        NSData  *data = [NSJSONSerialization dataWithJSONObject:summary options:0 error:&error];
        NSString  *contentString = nil;
        if (data == nil) {
            APCLogError2 (error);
        } else {
            contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        // If string length is non-zero then update result summary
        if (contentString.length > 0)
        {
            [APCResult updateResultSummary:contentString forTaskResult:taskResults inContext:context];
        }
    };
    return nil;
}

#pragma  mark  -  Task View Controller Delegate Methods

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    if ([stepViewController.step.identifier hasPrefix:APCTapTappingStepIdentifier] == YES) {
        self.preferStatusBarShouldBeHidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden: YES];
    }
    
    if ([stepViewController.step.identifier isEqualToString:kConclusionStepIdentifier] == YES) {
        self.preferStatusBarShouldBeHidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden: NO];
        [[UIView appearance] setTintColor:[UIColor appTertiaryColor1]];
    }
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error
{
    if (reason == ORKTaskViewControllerFinishReasonFailed) {
        if (error != nil) {
            APCLogError2 (error);
        }
    }
    [super taskViewController:taskViewController didFinishWithReason:reason error:error];
}

#pragma  mark  -  View Controller Methods

- (BOOL)prefersStatusBarHidden
{
    return  self.preferStatusBarShouldBeHidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.topItem.title = kTaskViewControllerTitle;
    
    self.preferStatusBarShouldBeHidden = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

/*********************************************************************************/
#pragma mark - Add Task-Specific Results — Interval Tapping
/*********************************************************************************/



- (void) updateSchemaRevision
{
    if (self.scheduledTask) {
        self.scheduledTask.taskSchemaRevision = [NSNumber numberWithInteger:kTappingActivitySchemaRevision];
    }
}

@end
