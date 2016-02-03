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

static NSString * const kItemKey                    = @"item";
static NSString * const kIdentifierKey              = @"identifier";
static NSString * const kStartDateKey               = @"startDate";
static NSString * const kEndDateKey                 = @"endDate";
static NSString * const kUserInfoKey                = @"userInfo";


static const NSInteger kTappingActivitySchemaRevision = 9;

@interface APHIntervalTappingTaskViewController  ( ) <NSObject>



@end

@implementation APHIntervalTappingTaskViewController

#pragma  mark  -  Task Creation Methods

+ (id<ORKTask>)createOrkTask:(APCTask *) __unused scheduledTask
{
    return  [[APHActivityManager defaultManager] createTaskForSurveyId:APHTappingActivitySurveyIdentifier];
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


- (BOOL)preferStatusBarShouldBeHiddenForStep:(ORKStep*)step {
    return [step.identifier hasPrefix:APCTapTappingStepIdentifier];
}


#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_NAV_TITLE", nil, APHLocaleBundle(), @"Tapping Activity", @"Nav bar title for the tapping activity view.");
    
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
