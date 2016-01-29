//
//  APHMedicationTrackerTaskResultArchiver.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHMedicationTrackerTaskResultArchiver.h"
#import "APHMedicationTrackerTask.h"
#import "APHMedication.h"

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
    for (APHMedication *med in selectedMeds) {
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
