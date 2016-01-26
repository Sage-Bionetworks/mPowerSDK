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
#import "APHMedicationTrackerDataStore.h"

@interface APHParkinsonActivityViewController ()

@property (nonatomic, strong) APCDataArchive *medicationTrackerArchive;

@property (nonatomic, readonly) APHMedicationTrackerTask *medicationTrackerTask;
@property (nonatomic, readonly) APHMedicationTrackerDataStore *dataStore;

@end

static const NSInteger APHMedicationTrackerSchemaRevision = 1;

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

- (APHMedicationTrackerTask*)medicationTrackerTask {
    if ([self.task isKindOfClass:[APHMedicationTrackerTask class]]) {
        return (APHMedicationTrackerTask*)self.task;
    }
    return nil;
}

- (APHMedicationTrackerDataStore*)dataStore {
    return self.medicationTrackerTask.dataStore ?: [APHMedicationTrackerDataStore defaultStore];
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
        ORKResult *medSelectionResult = [baseTaskResult resultForIdentifier:APHMedicationTrackerSelectionStepIdentifier];
        ORKResult *medFrequencyResult = [baseTaskResult resultForIdentifier:APHMedicationTrackerFrequencyStepIdentifier];
        ORKResult *momentInDayResult = [baseTaskResult resultForIdentifier:APHMedicationTrackerMomentInDayStepIdentifier];
        
        if (medSelectionResult) {
            [medResults addObject:medSelectionResult];
            [baseResults removeObject:medSelectionResult];
        }
        if (medFrequencyResult) {
            [medResults addObject:medFrequencyResult];
            [baseResults removeObject:medFrequencyResult];
        }
        
        // For the moment in day result, we want to push to cache if discovered and pull from
        // cache if not found
        if (momentInDayResult != nil && [momentInDayResult isKindOfClass:[ORKStepResult class]]) {
            self.dataStore.momentInDayResult = (ORKStepResult*)momentInDayResult;
        }
        else {
            ORKResult *momentInDayResult = self.dataStore.momentInDayResult;
            NSAssert(momentInDayResult != nil, @"Cached MomentInDay result is missing.");
            if (momentInDayResult != nil) {
                [baseResults insertObject:momentInDayResult atIndex:0];
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
    [self.taskResultArchiver appendArchive:self.archive withTaskResult:baseTaskResult];
    
    // if there is a med results then archive that separately
    if (medicationTrackerTaskResult) {
        self.medicationTrackerArchive = [[APCDataArchive alloc] initWithReference:APHMedicationTrackerTaskIdentifier schemaRevision:@(APHMedicationTrackerSchemaRevision)];
        [self.taskResultArchiver appendArchive:self.medicationTrackerArchive withTaskResult:medicationTrackerTaskResult];
    }
}

- (void)uploadResultSummary: (NSString *)resultSummary
{
    // Save datastore changes
    if ([self.dataStore hasChanges]) {
        [self.dataStore commitChanges];
    }

#warning FIXME!!!!
//    // Save user data groups
//    if ([self.dataGroupsManager hasChanges]) {
//        typeof(self) __weak weakSelf = self;
//        [self.user updateDataGroups:self.dataGroupsManager.dataGroups onCompletion:^(NSError *error) {
//            if ((error == nil) && ![weakSelf hasChanges]) {
//                [weakSelf reset];
//            }
//        }];
//    }
    
    // Encrypt and Upload the medication selection result
    if (self.medicationTrackerArchive) {
        APCDataArchiveUploader *archiveUploader = [[APCDataArchiveUploader alloc]init];
        [archiveUploader encryptAndUploadArchive:self.medicationTrackerArchive withCompletion:nil];
    }
    
    [super uploadResultSummary:resultSummary];
}

@end
