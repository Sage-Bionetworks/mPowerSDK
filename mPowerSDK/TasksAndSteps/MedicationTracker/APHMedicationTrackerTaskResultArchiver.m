//
//  APHMedicationTrackerTaskResultArchiver.m
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

#import "APHMedicationTrackerTaskResultArchiver.h"
#import "APHMedicationTrackerTask.h"
@import BridgeAppSDK;

@implementation APHMedicationTrackerTaskResultArchiver

- (instancetype)initWithTask:(APHMedicationTrackerTask *)task {
    if ((self = [super init])) {
        _task = task;
    }
    return self;
}

- (void)appendArchive:(APCDataArchive *)archive withTaskResult:(ORKTaskResult *)result {
    [super appendArchive:archive withTaskResult:result];
    
    // build the selection table
    NSArray *selectedMeds = [self.task selectedMedicationFromResult:result];
    NSMutableArray *items = [NSMutableArray new];
    for (SBAMedication *med in selectedMeds) {
        [items addObject:[med dictionaryRepresentation]];
    }
    NSDate *startDate = result.startDate ?: [NSDate date];
    NSDate *endDate = result.endDate ?: result.startDate;
    NSDictionary *dictionary = @{ @"items" : items,
                                  @"startDate" : startDate,
                                  @"endDate"   : endDate};
    NSString *filename = [self filenameForFileResultIdentifier:APHMedicationTrackerSelectionStepIdentifier
                                                stepIdentifier:nil
                                                     extension:@"json"];
    [archive insertDictionaryIntoArchive:dictionary filename:filename];
}

- (BOOL)appendArchive:(APCDataArchive *)archive withResult:(ORKResult *)result forStepResult:(ORKStepResult *)stepResult {
    // Do not call through for the selection and frequency steps. These are handled elsewhere.
    if (![stepResult.identifier isEqualToString:APHMedicationTrackerSelectionStepIdentifier] &&
        ![stepResult.identifier isEqualToString:APHMedicationTrackerFrequencyStepIdentifier]) {
        return [super appendArchive:archive withResult:result forStepResult:stepResult];
    }
    return YES;
}

@end
