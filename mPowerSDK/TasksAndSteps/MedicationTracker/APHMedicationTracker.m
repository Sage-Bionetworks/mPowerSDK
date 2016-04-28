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

@end
