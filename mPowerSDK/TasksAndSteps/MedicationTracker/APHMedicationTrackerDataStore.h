//
//  APHMedicationTrackerDataStore.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/21/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ResearchKit/ResearchKit.h>
#import <APCAppCore/APCAppCore.h>

NS_ASSUME_NONNULL_BEGIN

@class APHMedication;

@interface APHMedicationTrackerDataStore : NSObject

+ (instancetype)defaultStore;

@property (nonatomic, copy) NSDate * _Nullable lastCompletionDate;
@property (nonatomic, copy) ORKStepResult * _Nullable momentInDayResult;
@property (nonatomic, copy) NSArray <APHMedication*> * _Nullable selectedMedications;
@property (nonatomic) BOOL skippedSelectMedicationsSurveyQuestion;

@property (nonatomic, readonly) NSArray <NSString*> * _Nullable trackedMedications;
@property (nonatomic, readonly) BOOL hasNoTrackedMedication;
@property (nonatomic, readonly) BOOL hasSelectedMedicationOrSkipped;
@property (nonatomic, readonly) BOOL shouldIncludeMomentInDayStep;
@property (nonatomic, readonly) BOOL hasChanges;

@property (nonatomic, readonly) NSUserDefaults *storedDefaults;

/**
 * Initialize with a user defaults that has a suite name (for sharing defaults across different apps)
 */
- (instancetype)initWithUserDefaultsWithSuiteName:(NSString * _Nullable)suiteName;

- (void)commitChanges;
- (void)reset;

@end

NS_ASSUME_NONNULL_END