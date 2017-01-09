//
//  APHParkinsonActivityViewController.m
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

#import "APHParkinsonActivityViewController.h"
#import "APHAppDelegate.h"
#import "APHLocalization.h"
#import "APHActivityManager.h"
#import "APHMedicationTrackerTask.h"
#import "APHMedicationTracker.h"
#import "APHMedicationTrackerTaskResultArchiver.h"

@interface APHParkinsonActivityViewController ()

@end

static  NSString *const kSecondInstructionStepIdentifier    = @"instruction1";

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

- (id<ORKTaskResultSource>)defaultResultSource {
    return self.medicationTrackerTask;
}

- (APHMedicationTrackerTask*)medicationTrackerTask {
    if ([self.task isKindOfClass:[APHMedicationTrackerTask class]]) {
        return (APHMedicationTrackerTask*)self.task;
    }
    return nil;
}

- (APCUser*)user {
    return [[[APCAppDelegate sharedAppDelegate] dataSubstrate] currentUser];
}

- (APHMedicationTrackerDataStore*)dataStore {
    return self.medicationTrackerTask.dataStore ?: [APHMedicationTrackerDataStore sharedStore];
}

@synthesize dataGroupsManager = _dataGroupsManager;
- (APCDataGroupsManager *)dataGroupsManager {
    if (self.medicationTrackerTask != nil) {
        return self.medicationTrackerTask.dataGroupsManager;
    }
    else if (_dataGroupsManager == nil) {
        _dataGroupsManager = [[APCAppDelegate sharedAppDelegate] dataGroupsManagerForUser:self.user];
    }
    return _dataGroupsManager;
}

- (UIColor*)tintColorForStep:(ORKStep*)step {
    if ([[step.identifier lowercaseString] containsString:@"conclusion"]) {
        return [UIColor appTertiaryColor1];
    }
    return [UIColor appPrimaryColor];
}

- (BOOL)prefersStatusBarHidden
{
    return self.preferStatusBarShouldBeHidden;
}

- (BOOL)preferStatusBarShouldBeHiddenForStep:(ORKStep*)step {
    return NO;
}

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController stepViewControllerWillAppear:(ORKStepViewController *)stepViewController
{
    // Update tint color and status bar
    ORKStep *step = stepViewController.step;
    [[UIView appearance] setTintColor:[self tintColorForStep:step]];
    self.preferStatusBarShouldBeHidden = [self preferStatusBarShouldBeHiddenForStep:step];
    
    // Modify the second instruction step continue button to override the logic that is introduced by the
    // Diagnosis and Medication survey.
    if ([stepViewController.step.identifier isEqualToString:kSecondInstructionStepIdentifier]) {
        stepViewController.continueButtonTitle = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_GET_STARTED", nil, APHLocaleBundle(),
                                                                                   @"Get Started",
                                                                                   @"Text to get started with the activity.");
    }
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error {
    
    // Switch the tint color back to the appPrimaryColor
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    if ((reason == ORKTaskViewControllerFinishReasonSaved) || (reason == ORKTaskViewControllerFinishReasonCompleted)) {
        [self saveChangesIfNeeded];
    }
    else {
        if ((reason == ORKTaskViewControllerFinishReasonFailed) && (error != nil)) {
            APCLogError2 (error);
        }
        [self resetChangesIfNeeded];
    }
    
    [super taskViewController:taskViewController didFinishWithReason:reason error:error];
}

#pragma  mark  -  View Controller Methods

- (void) archiveResults
{
    ORKTaskResult * baseTaskResult = nil;
    ORKTaskResult * medicationTrackerTaskResult = nil;
    
    if ((self.medicationTrackerTask != nil) && (self.medicationTrackerTask.subTask == nil)) {
        // If the medication tracker task was *not* run as a subcomponent of another task
        // it is the base result;
        baseTaskResult = self.result;
    }
    else {
        
        // If this is a task then the base result is the task and we may have medication selection
        // results to strip out of it.
        baseTaskResult = [self.result copy];
        NSMutableArray *baseResults = [baseTaskResult.results mutableCopy];
        NSMutableArray *medResults = [NSMutableArray new];
        
        // Get the results to munge
        NSArray *medResultIdentifiers = @[APCDataGroupsStepIdentifier,
                                          APHMedicationTrackerSelectionStepIdentifier,
                                          APHMedicationTrackerFrequencyStepIdentifier];
        for (NSString *medId in medResultIdentifiers) {
            ORKResult *medResult = [baseTaskResult resultForIdentifier:medId];
            if (medResult !=  nil) {
                [medResults addObject:medResult];
                [baseResults removeObject:medResult];
            }
        }
        
        // For the moment in day result, we want to push to cache if discovered and pull from
        // cache if not found
        NSArray *momentInDaySteps = @[APHMedicationTrackerActivityTimingStepIdentifier, APHMedicationTrackerMomentInDayStepIdentifier];
        NSPredicate *momentInDayFilter = [NSPredicate predicateWithFormat:@"%K IN %@", NSStringFromSelector(@selector(identifier)), momentInDaySteps];
        NSArray *momentInDayResults = [baseTaskResult.results filteredArrayUsingPredicate:momentInDayFilter];
        if (momentInDayResults.count == momentInDaySteps.count) {
            self.dataStore.momentInDayResults = momentInDayResults;
        }
        else {
            momentInDayResults = self.dataStore.momentInDayResults;
            NSAssert(momentInDayResults != nil, @"Cached MomentInDay result is missing.");
            if (momentInDayResults != nil) {
                [baseResults insertObjects:momentInDayResults
                                 atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, momentInDayResults.count)]];
            }
        }
        
        // point the mutated results back to the base results
        baseTaskResult.results = baseResults;
        
        // If there are med selection results, add to a separate task result
        if (medResults.count > 0) {
            medicationTrackerTaskResult = [[ORKTaskResult alloc] initWithIdentifier:APHMedicationTrackerTaskIdentifier];
            medicationTrackerTaskResult.results = medResults;
        }
    }

    // get a fresh archive for the base results
    self.archive = [[APCDataArchive alloc] initWithReference:self.task.identifier task:self.scheduledTask];
    [self appendArchive:self.archive withTaskResult:baseTaskResult];
    
    // if there is a med results then archive that separately
    if (medicationTrackerTaskResult) {
        
        // Create an archive for the medication survey
        NSNumber *schemaRevision = [[APHActivityManager defaultManager] schemaRevisionForSchemaIdentifier:APHMedicationTrackerTaskIdentifier];

        self.medicationTrackerArchive = [[APCDataArchive alloc] initWithReference:APHMedicationTrackerTaskIdentifier schemaRevision:schemaRevision];
        [self appendArchive:self.medicationTrackerArchive withTaskResult:medicationTrackerTaskResult];
        
        // Look for a scheduled task and update that task if need be
        [[APCScheduler defaultScheduler] startAndFinishNextScheduledTaskWithID:APHMedicationTrackerSurveyIdentifier
                                                                     startDate:self.result.startDate
                                                                       endDate:self.result.endDate];

    }
}

- (void)appendArchive:(APCDataArchive*)archive withTaskResult:(ORKTaskResult *)result {
    APCTaskResultArchiver *taskArchiver = self.taskResultArchiver;
    if (([result resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier] != nil) &&
        ![taskArchiver isKindOfClass:[APHMedicationTrackerTaskResultArchiver class]]) {
        taskArchiver = [[APHMedicationTrackerTaskResultArchiver alloc] initWithTask:self.medicationTrackerTask];
    }
    [taskArchiver appendArchive:archive withTaskResult:result];
}

- (void)uploadResultSummary: (NSString *)resultSummary
{
    [self saveChangesIfNeeded];
    
    // Encrypt and Upload the medication selection result
    if (self.medicationTrackerArchive) {
        APCDataArchiveUploader *archiveUploader = [[APCDataArchiveUploader alloc] init];
        [archiveUploader encryptAndUploadArchive:self.medicationTrackerArchive withCompletion:nil];
    }
    
    [super uploadResultSummary:resultSummary];
}

- (void)saveChangesIfNeeded {
    if (self.dataStore.hasChanges) {
        [self.dataStore commitChanges];
    }
    if (self.dataGroupsManager.hasChanges) {
        [self.user updateDataGroups:self.dataGroupsManager.dataGroups onCompletion:nil];
    }
}

- (void)resetChangesIfNeeded {
    // Because the data store is a shared singleton, it needs to be reset if the results of this survey
    // should not be saved.
    [self.dataStore reset];
}


- (void) updateSchemaRevision
{
    if (self.scheduledTask && self.task) {
        self.scheduledTask.taskSchemaRevision = [[APHActivityManager defaultManager] schemaRevisionForSchemaIdentifier:self.task.identifier];
    }
}

@end
