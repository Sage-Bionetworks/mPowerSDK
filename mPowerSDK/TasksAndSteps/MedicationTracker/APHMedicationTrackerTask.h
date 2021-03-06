//
//  APHMedicationTrackerTask.h
//  mPowerSDK
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

#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
@import BridgeAppSDK;

@class APHMedication, APCDataGroupsManager, APHMedicationTrackerDataStore, APHTextChoice;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const APHInstruction0StepIdentifier;
extern NSString * const APHMedicationTrackerConclusionStepIdentifier;
extern NSString * const APHMedicationTrackerTaskIdentifier;
extern NSString * const APHMedicationTrackerNoneAnswerIdentifier;
extern NSString * const APHMedicationTrackerSkipAnswerIdentifier;
extern NSString * const APHMedicationTrackerIntroductionStepIdentifier;
extern NSString * const APHMedicationTrackerChangedStepIdentifier;
extern NSString * const APHMedicationTrackerSelectionStepIdentifier;
extern NSString * const APHMedicationTrackerFrequencyStepIdentifier;


typedef NS_ENUM(NSUInteger, APHMedicationTimingChoice) {
    APHMedicationTimingChoiceBefore = 0,
    APHMedicationTimingChoiceAfter = 1,
    APHMedicationTimingChoiceOther = NSNotFound
};

@interface APHMedicationTrackerTask : NSObject <ORKTask, ORKTaskResultSource, NSSecureCoding, NSCopying>

+ (NSDictionary*)defaultMapping;

@property (nonatomic, readwrite) APCDataGroupsManager *dataGroupsManager;
@property (nonatomic, readonly) APHMedicationTrackerDataStore *dataStore;
@property (nonatomic, readonly) NSArray <SBAMedication *> *medications;
@property (nonatomic, readonly) NSArray <ORKStep *> *medicationTrackerSteps;
@property (nonatomic, readonly) id <ORKTask> _Nullable subTask;

/**
 * If the dictionary is nil, then the default embedded json file MedicationTracking will
 * be used to define the mapping.
 */
- (instancetype)initWithDictionaryRepresentation:(NSDictionary * _Nullable)dictionary;

/**
 * Allow for the injection of the medication tracking survey questions before a activity
 * decribed by the subtask.
 */
- (instancetype)initWithDictionaryRepresentation:(NSDictionary * _Nullable)dictionary
                                         subTask:(id <ORKTask> _Nullable)subTask;

/**
 * Map the selected medication and frequency against the list of all possible answers
 */
- (NSArray <APHMedication*> *)selectedMedicationFromResult:(ORKTaskResult*)result;

/**
 * Index of a given medication timing choice (used in graphing)
 */
- (NSUInteger)indexForMedicationActivityTimingChoice:(id <NSCopying, NSCoding, NSObject> _Nullable)choiceValue;

/**
 * Timing choice to include in the result sumamary for the given task result
 */
- (id <NSCopying, NSCoding, NSObject> )timingChoiceFromTaskResult:(ORKTaskResult *)result;

// @protected
- (ORKStep*)createStepFromMappingDictionary:(NSDictionary*)stepDictionary;
- (BOOL)shouldUpdateAndIncludeStep:(ORKStep*)step;

@end

NS_ASSUME_NONNULL_END
