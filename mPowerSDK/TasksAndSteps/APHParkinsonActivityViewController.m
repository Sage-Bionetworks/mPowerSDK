//
//  APHParkinsonActivityViewController.m
//  mPower
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

#import "APHParkinsonActivityViewController.h"
#import "APHAppDelegate.h"
#import "APHLocalization.h"
#import "APHMomentInDayStepManager.h"

    //
    //    keys for Parkinson Conclusion Step View Controller
    //
NSString  *kConclusionStepThankYouTitle;
NSString  *kConclusionStepViewDashboard;


@interface APHParkinsonActivityViewController ()

@property  (nonatomic, strong)  NSArray  *stashedSteps;

@end

    //
    //    Common Super-Class for all four Parkinson Task View Controllers
    //

    //
    //    A Parkinson Activity may have an optional step inject at the
    //    beginning of the Activity to ask the patient if they have taken their medications
    //
    //    That extra step is included in the Activity Step Results to be uploaded
    //
    //    The Research Institution requires that this information be supplied even when
    //    the question is not asked, in which case, a cached copy of the most recent
    //    results is used, until such time as a new result may be created
    //
    //    modifyTaskWithPreSurveyStepIfRequired does the optional step injection if needed
    //
    //    stepViewControllerResultDidChange records the most recent copy of the cached result
    //
    //    taskViewController didFinishWithReason uses the cached result if the step results
    //    do not already contain the apropriate step result
    //
    //    the over-ridden  result  method ensures that the cached results are used if they exist
    //
@implementation APHParkinsonActivityViewController

+ (void)initialize
{
    void (^localizeBlock)() = [^{
        
        //
        //    keys for Parkinson Conclusion Step View Controller
        //
        kConclusionStepThankYouTitle           = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_TEXT", nil, APHLocaleBundle(), @"Thank You!", @"Main text shown to participant upon completion of an activity.");
        kConclusionStepViewDashboard           = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_DETAIL", nil, APHLocaleBundle(), @"The results of this activity can be viewed on the dashboard", @"Detail text shown to participant upon completion of an activity.");
    } copy];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull __unused note) {
        localizeBlock();
    }];
    localizeBlock();
}

#pragma mark - modify task

// TODO: syoung 12/28/2015 replace this with an instance property once the superclass
// has been refactored to use an instance method for the task creation rather than a class method.
+ (APHMomentInDayStepManager *)momentInDayStepManager
{
    static APHMomentInDayStepManager * __manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __manager = [[APHMomentInDayStepManager alloc] init];
    });
    return __manager;
}

+ (ORKOrderedTask *)modifyTaskWithPreSurveyStepIfRequired:(ORKOrderedTask *)task andTitle:(NSString *)taskTitle
{
    APHAppDelegate  *appDelegate = (APHAppDelegate *)[UIApplication sharedApplication].delegate;
    NSDate          *lastCompletionDate = appDelegate.dataSubstrate.currentUser.taskCompletion;
    
    ORKOrderedTask  *replacementTask = task;
    
    if ([[self momentInDayStepManager] shouldIncludeMomentInDayStep:lastCompletionDate])
    {
        ORKStep *step = [[self momentInDayStepManager] createMomentInDayStep];
        NSMutableArray  *newSteps = [task.steps mutableCopy];
        if ([newSteps count] >= 1) {
            [newSteps insertObject:step atIndex:1];
        }
        replacementTask = [[ORKOrderedTask alloc] initWithIdentifier:taskTitle steps:newSteps];
    }
                         
    return  replacementTask;
}


#pragma  mark  -  Task View Controller Delegate Methods

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error
{
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        
        ORKResult  *stepResult = [[taskViewController result] resultForIdentifier:kMomentInDayStepIdentifier];
    
        if (stepResult != nil && [stepResult isKindOfClass:[ORKStepResult class]]) {
            [[APHParkinsonActivityViewController momentInDayStepManager]  saveMomentInDayResult:(ORKStepResult*)stepResult];
        }
        else {
            ORKChoiceQuestionResult  *aResult = [[APHParkinsonActivityViewController momentInDayStepManager]  stashedMomentInDayResult];
            if (aResult != nil) {
                NSMutableArray  *stepResults = [NSMutableArray array];
                ORKStepResult  *aStepResult = [[ORKStepResult alloc] initWithStepIdentifier:kMomentInDayStepIdentifier results: @[ aResult ]];
                [stepResults addObject:aStepResult];
                for (ORKStepResult *stepResult in self.result.results) {
                    [stepResults addObject:stepResult];
                }
                self.stashedSteps = stepResults;
            }
        }
        
        
        APHAppDelegate *appDelegate = (APHAppDelegate *) [UIApplication sharedApplication].delegate;
        appDelegate.dataSubstrate.currentUser.taskCompletion = [NSDate date];
        
        [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    }
    [super taskViewController:taskViewController didFinishWithReason:reason error:error];
}

#pragma  mark  -  View Controller Methods

-(ORKTaskResult * __nonnull)result
{
    ORKTaskResult  *taskResult = [super result];
    
    if (self.stashedSteps != nil) {
        [taskResult setResults:self.stashedSteps];
    }
    return  taskResult;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Point the task result archiver at the shared filename translator
    self.taskResultArchiver = [[APCTaskResultArchiver alloc] init];
    NSString *path = [APHLocaleBundle() pathForResource:@"APHTaskResultFilenameTranslation" ofType:@"json"];
    [self.taskResultArchiver setFilenameTranslationDictionaryWithJSONFileAtPath:path];
    
}

@end
