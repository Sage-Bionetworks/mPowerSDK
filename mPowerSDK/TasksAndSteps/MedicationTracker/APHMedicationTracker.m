//
//  APHMedicationTrackerDataStore.m
//  mPowerSDK
//
// Copyright (c) 2016, Sage Bionetworks. All rights reserved.
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

#import "APHMedicationTracker.h"
#import <APCAppCore/APCAppCore.h>

NSString * const APHMedicationTrackerMomentInDayStepIdentifier      = @"momentInDay";
NSString * const APHMedicationTrackerMomentInDayFormItemIdentifier  = @"momentInDayFormat";
NSString * const APHMedicationTrackerActivityTimingStepIdentifier   = @"medicationActivityTiming";

//
//    elapsed time delay before asking the user tracking questions again
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMomentInDaySurvey         = 20.0 * 60.0;

//
//    elapsed time delay before asking the user if their tracked data has changed
//
static  NSTimeInterval  kMinimumAmountOfTimeToShowMedChangedSurvey         = 30.0 * 24.0 * 60.0 * 60.0;

@implementation APHMedication

+ (Class)classForKeyedUnarchiver {
    return [SBAMedication classForKeyedUnarchiver];
}

@end


@implementation APHMedicationTrackerDataStore

+ (NSString *)lastTrackingSurveyDateKey {
    return @"lastMedicationSurveyDate";
}

+ (NSString *)selectedItemsKey {
    return @"selectedMedications";
}

+ (NSString *)noTrackedItemsAnswer {
    return @"No Tracked Medication";
}



- (NSArray *)momentInDayResultDefaultIdMap {
    // syoung 04/07/2016 TODO: refactor to not use hardcoded values
    return @[@[APHMedicationTrackerMomentInDayStepIdentifier, APHMedicationTrackerMomentInDayFormItemIdentifier],
             @[APHMedicationTrackerActivityTimingStepIdentifier, APHMedicationTrackerActivityTimingStepIdentifier]];
}

- (NSDate *)lastCompletionDate {
    if (super.lastCompletionDate == nil) {
        // Allow custom setting if last completion date and only access the app delegate the last
        // completion date is not set.
        super.lastCompletionDate = [[[[APCAppDelegate sharedAppDelegate] dataSubstrate] currentUser] taskCompletion];
    }
    return super.lastCompletionDate;
}

- (BOOL)hasNoTrackedItems {
    NSArray *trackedObjects = self.trackedItems;
    return (trackedObjects != nil) && (trackedObjects.count == 0);
}

- (BOOL)hasSelected {
    return (self.selectedItems != nil);
}

- (BOOL)shouldIncludeMomentInDayStep {
    if (self.trackedItems.count == 0) {
        return NO;
    }
    
    if (self.lastCompletionDate == nil || self.momentInDayResults == nil) {
        return YES;
    }
    
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastCompletionDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMomentInDaySurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (BOOL)shouldIncludeChangedQuestion {
    if (!self.hasSelected) {
        // Should not ask if there has been a change if the question has never been asked
        return NO;
    }
    NSTimeInterval numberOfSecondsSinceTaskCompletion = [[NSDate date] timeIntervalSinceDate: self.lastTrackingSurveyDate];
    NSTimeInterval minInterval = kMinimumAmountOfTimeToShowMedChangedSurvey;
    
    return (numberOfSecondsSinceTaskCompletion > minInterval);
}

- (void)updateSelectedItems:(NSArray<SBATrackedDataObject *> *)items
             stepIdentifier:(NSString *)stepIdentifier
                     result:(ORKTaskResult*)result {
    
    ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:stepIdentifier];
    ORKChoiceQuestionResult *selectionResult = (ORKChoiceQuestionResult *)[stepResult.results firstObject];
    
    if (selectionResult == nil) {
        return;
    }
    if (![selectionResult isKindOfClass:[ORKChoiceQuestionResult class]]) {
        NSAssert(NO, @"The Medication selection result was not of the expected class of ORKChoiceQuestionResult");
        return;
    }
    
    // Get the selected ids
    NSArray *selectedIds = selectionResult.choiceAnswers;
    
    // Get the selected meds by filtering this list
    NSString *identifierKey = NSStringFromSelector(@selector(identifier));
    NSPredicate *idsPredicate = [NSPredicate predicateWithFormat:@"%K IN %@", identifierKey, selectedIds];
    NSArray *sort = @[[NSSortDescriptor sortDescriptorWithKey:identifierKey ascending:YES]];
    NSArray *selectedItems = [[items filteredArrayUsingPredicate:idsPredicate] sortedArrayUsingDescriptors:sort];
    if (selectedItems.count > 0) {
        // Map frequency from the previously stored results
        NSPredicate *frequencyPredicate = [NSPredicate predicateWithFormat:@"%K > 0", NSStringFromSelector(@selector(frequency))];
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[frequencyPredicate, idsPredicate]];
        NSArray *previousItems = [[self.selectedItems filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:sort];
        
        if (previousItems.count > 0) {
            // If there are frequency results to map, then map them into the returned results
            // (which may be a different object from the med list in the data store)
            NSEnumerator *enumerator = [previousItems objectEnumerator];
            SBATrackedDataObject *previousItem = [enumerator nextObject];
            for (SBATrackedDataObject *item in selectedItems) {
                if ([previousItem.identifier isEqualToString:item.identifier]) {
                    item.frequency = previousItem.frequency;
                    previousItem = [enumerator nextObject];
                    if (previousItem == nil) { break; }
                }
            }
        }
    }
    
    self.selectedItems = selectedItems;
}

- (void)updateFrequencyForStepIdentifier:(NSString *)stepIdentifier
                                  result:(ORKTaskResult *)result {
    
    ORKStepResult *frequencyResult = (ORKStepResult *)[result resultForIdentifier:stepIdentifier];
    
    if (frequencyResult != nil) {
        
        // Get the selected items array
        NSArray *selectedItems = self.selectedItems;
        
        // If there are frequency results to map, then map them into the returned results
        // (which may be a different object from the med list in the data store)
        for (SBATrackedDataObject *item in selectedItems) {
            ORKScaleQuestionResult *scaleResult = (ORKScaleQuestionResult *)[frequencyResult resultForIdentifier:item.identifier];
            if ([scaleResult isKindOfClass:[ORKScaleQuestionResult class]]) {
                item.frequency = [scaleResult.scaleAnswer unsignedIntegerValue];
            }
        }
        
        // Set it back to the selected Items
        self.selectedItems = selectedItems;
    }
}

@end
