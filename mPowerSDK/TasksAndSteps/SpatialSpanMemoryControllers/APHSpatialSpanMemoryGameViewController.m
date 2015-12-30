// 
//  APHSpatialSpanMemoryGameViewController.m 
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
 
#import "APHSpatialSpanMemoryGameViewController.h"
#import "APHLocalization.h"
#import "APHActivityManager.h"

    //
    //        Step Identifiers
    //
static  NSString *const kInstructionStepIdentifier    = @"instruction1";
static  NSString       *kConclusionStepIdentifier     = @"conclusion";

        NSString *const kSpatialMemoryScoreSummaryKey = @"spatialMemoryScoreSummaryKey";

static NSString * const kIdentifierKey              = @"identifier";
static NSString * const kStartDateKey               = @"startDate";
static NSString * const kEndDateKey                 = @"endDate";
static NSString * const kUserInfoKey                = @"userInfo";
static NSString * const kItemKey                    = @"item";






@interface APHSpatialSpanMemoryGameViewController ()

@end

@implementation APHSpatialSpanMemoryGameViewController

#pragma  mark  -  Task Creation Methods

+ (ORKOrderedTask *)createOrkTask:(APCTask *) __unused scheduledTask
{
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    return [[APHActivityManager defaultManager] createOrderedTaskForSurveyId:APHMemoryActivitySurveyIdentifier];
}

#pragma  mark  -  Task View Controller Delegate Methods

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    
    if ([stepViewController.step.identifier isEqualToString:kConclusionStepIdentifier]) {
        [[UIView appearance] setTintColor:[UIColor appTertiaryColor1]];
    }
    [stepViewController.step setTitle:@"Good Job!"];
  
    if ([stepViewController.step.identifier isEqualToString:kInstructionStepIdentifier]) {
        UILabel *label = ((UILabel *)((UIView *)((UIView *)((UIView *) ((UIScrollView *)stepViewController.view.subviews[0]).subviews[0]).subviews[0]).subviews[0]).subviews[2]);
        label.text = NSLocalizedStringWithDefaultValue(@"APH_MEMORY_STEP_INSTRUCTION", nil, APHLocaleBundle(),
                                                       @"Some of the flowers will light up one at a time. "
                                                       @"Tap those flowers in the same order they lit up.\n\n"
                                                       @"To begin, tap Next, then watch closely.",
                                                       @"Instruction text for memory activity in Parkinson");
    }
}

- (void) taskViewController: (ORKTaskViewController *) taskViewController didFinishWithReason: (ORKTaskViewControllerFinishReason)reason error: (NSError *) error
{
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];

    if (reason == ORKTaskViewControllerFinishReasonFailed) {
        if (error != nil) {
            APCLogError2 (error);
        }
    }
    [super taskViewController: taskViewController didFinishWithReason: reason error: error];
}

#pragma mark - Results for Dashboard

- (NSString *)createResultSummary
{
    ORKTaskResult  *taskResults = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext * context) {
        ORKSpatialSpanMemoryResult  *memoryResults = nil;
        BOOL  found = NO;
        for (ORKStepResult  *stepResult  in  taskResults.results) {
            if (stepResult.results.count > 0) {
                for (id  object  in  stepResult.results) {
                    if ([object isKindOfClass:[ORKSpatialSpanMemoryResult class]] == YES) {
                        found = YES;
                        memoryResults = object;
                        break;
                    }
                }
                if (found == YES) {
                    break;
                }
            }
        }
        
        // Create the summary dictionary
        NSDictionary *summary = @{kSpatialMemoryScoreSummaryKey: @(memoryResults.score)};
        
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

#pragma  mark  -  View Controller Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"APH_MEMORY_NAV_TITLE", nil, APHLocaleBundle(), @"Memory Activity", @"Nav bar title for Memory activity view");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
