//
//  APHAppDelegate.m
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

@import APCAppCore;
#import "APHAppDelegate.h"
#import "APHProfileExtender.h"
#import "APHDataKeys.h"
#import "APHLocalization.h"
#import "APHOnboardingManager.h"

static NSString *const kMyThoughtsSurveyIdentifier                  = @"mythoughts";
static NSString *const kEnrollmentSurveyIdentifier                  = @"EnrollmentSurvey";
static NSString *const kStudyFeedbackSurveyIdentifier               = @"study_feedback";

/*********************************************************************************/
#pragma mark - Initializations Options
/*********************************************************************************/
static NSString *const kConsentPropertiesFileName   = @"APHConsentSection";

static NSString *const kVideoShownKey = @"VideoShown";

static NSString *const kJsonScheduleStringKey           = @"scheduleString";
static NSString *const kJsonTasksKey                    = @"tasks";
static NSString *const kJsonScheduleTaskIDKey           = @"taskID";
static NSString *const kJsonSchedulesKey                = @"schedules";

static NSString *const kAppStoreLink                    = @"https://appsto.re/us/GxN85.i";

@interface APHAppDelegate ()
@property (nonatomic) APHOnboardingManager *parkinsonOnboardingManager;

@end

@implementation APHAppDelegate

- (NSBundle*)storyboardBundle
{
    return [NSBundle bundleForClass:[APHAppDelegate class]];
}

#pragma mark - Private repo Overrides

- (NSString * _Nonnull)studyIdentifier {
    return @"studyname";
}

- (NSString * _Nonnull)appPrefix {
    return @"studyname";
}

- (HKUpdateFrequency)updateFrequency {
    return HKUpdateFrequencyImmediate;
}

- (NSInteger)environment {
#if DEBUG
    return SBBEnvironmentStaging;
#else
    return SBBEnvironmentProd;
#endif
}

- (NSArray <APCTaskReminder *> * _Nonnull)allTaskReminders {
    return @[
             [[APCTaskReminder alloc] initWithTaskID:APHWalkingActivitySurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_WALKING_ACTIVITY_LABEL", nil, APHLocaleBundle(), @"Walking Activity", @"Task reminder label for the walking activity.")],
             [[APCTaskReminder alloc] initWithTaskID:APHVoiceActivitySurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_VOICE_ACTIVITY_LABEL", nil, APHLocaleBundle(), @"Voice Activity", @"Task reminder label for the voice activity.")],
             [[APCTaskReminder alloc] initWithTaskID:APHTappingActivitySurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_TAPPING_ACTIVITY_LABEL", nil, APHLocaleBundle(), @"Tapping Activity", @"Task reminder label for the tapping activity.")],
             [[APCTaskReminder alloc] initWithTaskID:APHMemoryActivitySurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_MEMORY_ACTIVITY_LABEL", nil, APHLocaleBundle(), @"Memory Activity", @"Task reminder label for the memory activity.")],
             [[APCTaskReminder alloc] initWithTaskID:APHDailySurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_DAILY_SURVEY_LABEL", nil, APHLocaleBundle(), @"Daily Survey", @"Task reminder label for the daily check-in survey.")],
             [[APCTaskReminder alloc] initWithTaskID:kMyThoughtsSurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_MY_THOUGHTS_LABEL", nil, APHLocaleBundle(), @"My Thoughts", @"Task reminder label for the my thoughts survey.")],
             [[APCTaskReminder alloc] initWithTaskID:kEnrollmentSurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_ENROLLMENT_SURVEY_LABEL", nil, APHLocaleBundle(), @"Enrollment Survey", @"Task reminder label for the enrollment survey.")],
             [[APCTaskReminder alloc] initWithTaskID:kStudyFeedbackSurveyIdentifier reminderBody:NSLocalizedStringWithDefaultValue(@"APH_STUDY_FEEDBACK_LABEL", nil, APHLocaleBundle(), @"Study Feedback", @"Task reminder label for study feedback.")]];
}

- (NSDictionary * _Nonnull)appearanceInfo {
    return @{
             kPrimaryAppColorKey : [UIColor colorWithRed:255 / 255.0f green:0.0 blue:56 / 255.0f alpha:1.000],
             APHTappingActivitySurveyIdentifier : [UIColor appTertiaryPurpleColor],
             APHMemoryActivitySurveyIdentifier : [UIColor appTertiaryRedColor],
             APHVoiceActivitySurveyIdentifier : [UIColor appTertiaryBlueColor],
             APHWalkingActivitySurveyIdentifier : [UIColor appTertiaryYellowColor],
             APHEnrollmentSurveyIdentifier: [UIColor lightGrayColor],
             APHMyThoughtsSurveyIdentifier: [UIColor lightGrayColor],
             APHFeedbackSurveyIdentifier: [UIColor lightGrayColor],
             APHMedicationTrackerSurveyIdentifier: [UIColor colorWithRed:0.933
                                                                   green:0.267
                                                                    blue:0.380
                                                                   alpha:1.000]
             };
}

#pragma mark

- (BOOL)application:(UIApplication*) __unused application willFinishLaunchingWithOptions:(NSDictionary*) __unused launchOptions
{
    [super application:application willFinishLaunchingWithOptions:launchOptions];
    self.onboardingManager.showShareAppInOnboarding = YES;

    [self enableBackgroundDeliveryForHealthKitTypes];

    return YES;
}

- (NSURL *)appStoreLinkURL
{
    // The general link to the app store that is returned by using the app name will, in this case,
    // return a list of apps that meet the "mpower" search. Instead, override the default implementation
    // and link directly.
    return [NSURL URLWithString:kAppStoreLink];
}

- (NSString *)pathForResource:(NSString *)resourceName ofType:(NSString *)resourceType
{
    if ([[resourceType lowercaseString] isEqualToString:@"json"] ||
        ([resourceName hasPrefix:@"consent_"] && [resourceType isEqualToString:@"html"])) {
        // For the json resources, look in the shared framework bundle 
        return [[NSBundle bundleForClass:[APHAppDelegate class]] pathForResource:resourceName ofType:resourceType];
    }
    else {
        return [super pathForResource:resourceName ofType:resourceType];
    }
}

- (void)enableBackgroundDeliveryForHealthKitTypes
{
    NSArray* dataTypesWithReadPermission = [self healthKitQuantityTypesToRead];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKObjectType*   sampleType  = nil;

            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary*) dataType;

                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }

            if (sampleType)
            {
                [self.dataSubstrate.healthStore enableBackgroundDeliveryForType:sampleType
                                                                      frequency:self.updateFrequency
                                                                 withCompletion:^(BOOL success, NSError *error)
                 {
                     if (!success)
                     {
                         if (error)
                         {
                             APCLogError2(error);
                         }
                     }
                     else
                     {
                         APCLogDebug(@"Enabling background delivery for healthkit");
                     }
                 }];
            }
        }
    }
}

- (void)setUpInitializationOptions
{
    NSMutableDictionary * dictionary = [super defaultInitializationOptions];
    
    NSString *shareMessageFormat = NSLocalizedStringWithDefaultValue(@"APH_SHARE_MESSAGE_FORMAT", nil, APHLocaleBundle(), @"Please take a look at Parkinson mPower, a research study app about Parkinson Disease.  Download it for iPhone at %@", @"Sharing message format where %@ is the URL for the Parkinson app");
    NSString *shareMessage = [NSString stringWithFormat:shareMessageFormat, kAppStoreLink];

    dictionary = [self updateOptionsFor5OrOlder:dictionary];
    [dictionary addEntriesFromDictionary:@{
                                           kNewsFeedTabKey                      : @YES,
                                           kStudyIdentifierKey                  : self.studyIdentifier,
                                           kAppPrefixKey                        : self.appPrefix,
                                           kBridgeEnvironmentKey                : @(self.environment),
                                           kShareMessageKey                     : shareMessage
                                           }];
    
    [APCUser setShouldPerformTestUserEmailCheckOnSignup:YES];

    self.initializationOptions = dictionary;
}

- (NSDictionary*)researcherSpecifiedUnits
{
    NSDictionary* hkUnits =
  @{
    HKQuantityTypeIdentifierStepCount               : [HKUnit countUnit],
    HKQuantityTypeIdentifierBodyMass                : [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo],
    HKQuantityTypeIdentifierHeight                  : [HKUnit meterUnit],
    HKQuantityTypeIdentifierDistanceCycling         : [HKUnit meterUnit],
    HKQuantityTypeIdentifierDistanceWalkingRunning  : [HKUnit meterUnit],
    HKQuantityTypeIdentifierFlightsClimbed          : [HKUnit countUnit]
    };
    return hkUnits;
}

- (void)setUpTasksReminder
{
    // setup the task reminders
    [self.tasksReminder.reminders removeAllObjects];
    for (APCTaskReminder *reminder in self.allTaskReminders) {
        [self.tasksReminder manageTaskReminder:reminder];
    }

    if ([self doesPersisteStoreExist] == NO)
    {
        APCLogEvent(@"This app is being launched for the first time. Turn all reminders on");
        for (APCTaskReminder *reminder in self.tasksReminder.reminders) {
            [[NSUserDefaults standardUserDefaults] setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
        }

        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
            [self.tasksReminder setReminderOn:YES];
        }
        
        [[NSUserDefaults standardUserDefaults]synchronize];
    }
}

- (void)setUpAppAppearance
{
    [APCAppearanceInfo setAppearanceDictionary:self.appearanceInfo];
    [[UINavigationBar appearance] setTintColor:[UIColor appPrimaryColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor appSecondaryColor2],
                                                            NSFontAttributeName : [UIFont appNavBarTitleFont]
                                                            }];
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
}

- (id <APCProfileViewControllerDelegate>)profileExtenderDelegate
{
    if (self.profileExtender == nil) {
        self.profileExtender = [[APHProfileExtender alloc] init];
    }
    return self.profileExtender;
}

- (APCOnboardingManager *)onboardingManager {
    return self.parkinsonOnboardingManager;
}

- (APHOnboardingManager *)parkinsonOnboardingManager {
    if (_parkinsonOnboardingManager == nil) {
        _parkinsonOnboardingManager = [[APHOnboardingManager alloc] initWithProvider:self user:self.dataSubstrate.currentUser];
    }
    return _parkinsonOnboardingManager;
}

- (void)showOnBoarding
{
    [super showOnBoarding];

    [self showStudyOverview];
}

- (void)showNeedsEmailVerification
{
    [self showStudyOverviewAnimated:NO];
    UIViewController *taskVC = [self.parkinsonOnboardingManager instantiateOnboardingTaskViewController:YES];
    [self.window.rootViewController presentViewController:taskVC animated:NO completion:nil];
}

- (void)showStudyOverview
{
    [self showStudyOverviewAnimated:YES];
}

- (ORKTaskViewController *)consentViewController {
    return [self.parkinsonOnboardingManager instantiateConsentViewController];
}

- (void)showStudyOverviewAnimated:(BOOL)animated {
    UIViewController *studyController = [[UIStoryboard storyboardWithName:@"APHOnboarding" bundle:[self storyboardBundle]] instantiateViewControllerWithIdentifier:@"APHStudyOverviewVC"];
    if (animated) {
        [self setUpRootViewController:studyController];
    }
    else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:studyController];
        navController.navigationBar.translucent = NO;
        self.window.rootViewController = navController;
    }
}

- (BOOL)didHandleSignupFromViewController:(UIViewController *)viewController {
    UIViewController *taskVC = [self.parkinsonOnboardingManager instantiateOnboardingTaskViewController:YES];
    [viewController presentViewController:taskVC animated:YES completion:nil];
    return YES;
}

- (BOOL)didHandleSignInFromViewController:(UIViewController *)viewController {
    UIViewController *taskVC = [self.parkinsonOnboardingManager instantiateOnboardingTaskViewController:NO];
    [viewController presentViewController:taskVC animated:YES completion:nil];
    return YES;
}

- (BOOL)isVideoShown
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kVideoShownKey];
}

- (NSMutableDictionary *)updateOptionsFor5OrOlder:(NSMutableDictionary *)initializationOptions
{
    if (![APCDeviceHardware isiPhone5SOrNewer]) {
        [initializationOptions setValue:@"APHTasksAndSchedules_NoM7" forKey:kTasksAndSchedulesJSONFileNameKey];
    }
    return initializationOptions;
}

- (NSArray *)allSetTextBlocks
{
    NSArray *allSetBlockOfText = nil;

    NSString *activitiesAdditionalText = NSLocalizedStringWithDefaultValue(@"APH_ACTIVITIES_ADDITIONAL_INSTRUCTION", nil, APHLocaleBundle(), @"Please perform the activites each day when you are at your lowest before you take your Parkinson medications, after your medications take effect, and then a third time during the day.", @"Additional instructions for when to perform each of the activities.");
    
    allSetBlockOfText = @[@{kAllSetActivitiesTextAdditional: activitiesAdditionalText}];

    return allSetBlockOfText;
}

/*********************************************************************************/
#pragma mark - Helper Method for Datasubstrate Delegate Methods
/*********************************************************************************/

static NSDate *determineConsentDate(id object)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString      *filePath    = [[object applicationDocumentsDirectory] stringByAppendingPathComponent:@"db.sqlite"];
    NSDate        *consentDate = nil;

    if ([fileManager fileExistsAtPath:filePath]) {
        NSError      *error      = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        
        if (error != nil) {
            APCLogError2(error);
            consentDate = [[NSDate date] startOfDay];
        } else {
            consentDate = [attributes fileCreationDate];
        }
    }
    return consentDate;
}

/*********************************************************************************/
#pragma mark - Datasubstrate Delegate Methods
/*********************************************************************************/

- (void)setUpCollectors
{
    if (self.dataSubstrate.currentUser.userConsented)
    {
        if (!self.passiveDataCollector)
        {
            self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
        }

        [self configureDisplacementTracker];
        [self configureObserverQueries];
        [self configureMotionActivityObserver];
    }
}

- (void)configureMotionActivityObserver
{
    NSString*(^CoreMotionDataSerializer)(id) = ^NSString *(id dataSample)
    {
        CMMotionActivity* motionActivitySample  = (CMMotionActivity*)dataSample;
        NSString* motionActivity                = [CMMotionActivity activityTypeName:motionActivitySample];
        NSNumber* motionConfidence              = @(motionActivitySample.confidence);
        NSString* stringToWrite                 = [NSString stringWithFormat:@"%@,%@,%@\n",
                                                   motionActivitySample.startDate.toStringInISO8601Format,
                                                   motionActivity,
                                                   motionConfidence];
        return stringToWrite;
    };

    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;

        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = determineConsentDate(self);
                }
        return consentDate;
    };

    APCCoreMotionBackgroundDataCollector *motionCollector = [[APCCoreMotionBackgroundDataCollector alloc] initWithIdentifier:@"motionActivityCollector"
                                                                                                              dateAnchorName:@"APCCoreMotionCollectorAnchorName"
                                                                                                            launchDateAnchor:LaunchDate];

    NSArray*            motionColumnNames   = @[@"startTime",@"activityType",@"confidence"];
    APCPassiveDataSink* receiver            = [[APCPassiveDataSink alloc] initWithIdentifier:@"motionActivityCollector"
                                                                                 columnNames:motionColumnNames
                                                                          operationQueueName:@"APCCoreMotion Activity Collector"
                                                                               dataProcessor:CoreMotionDataSerializer
                                                                           fileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication];
    [motionCollector setReceiver:receiver];
    [motionCollector setDelegate:receiver];
    [motionCollector start];
    [self.passiveDataCollector addDataSink:motionCollector];
}

- (void)configureDisplacementTracker
{
    APCDisplacementTrackingCollector*           locationCollector   = [[APCDisplacementTrackingCollector alloc]
                                                                       initWithIdentifier:@"locationCollector"
                                                                       deferredUpdatesTimeout:60.0 * 60.0];
    NSArray*                                    locationColumns     = @[@"timestamp",
                                                                        @"distanceFromPreviousLocation",
                                                                        @"distanceUnit",
                                                                        @"direction",
                                                                        @"directionUnit",
                                                                        @"speed",
                                                                        @"speedUnit",
                                                                        @"floor",
                                                                        @"altitude",
                                                                        @"altitudeUnit",
                                                                        @"horizontalAccuracy",
                                                                        @"horizontalAccuracyUnit",
                                                                        @"verticalAccuracy",
                                                                        @"verticalAccuracyUnit"];
    APCPassiveDisplacementTrackingDataUploader* displacementSinker  = [[APCPassiveDisplacementTrackingDataUploader alloc]
                                                                       initWithIdentifier:@"displacementCollector"
                                                                       columnNames:locationColumns
                                                                       operationQueueName:@"APCDisplacement Tracker Sink"
                                                                       dataProcessor:nil
                                                                       fileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication];
    [locationCollector setReceiver:displacementSinker];
    [locationCollector setDelegate:displacementSinker];
    [locationCollector start];
    [self.passiveDataCollector addDataSink:locationCollector];
}

- (void)configureObserverQueries
{
    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;

        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = determineConsentDate(self);
        }
        return consentDate;
    };

    NSString *(^determineQuantitySource)(NSString *) = ^(NSString  *source)
            {
        NSString  *answer = nil;
        if (source == nil) {
            answer = @"not available";
        }
        else if ([UIDevice.currentDevice.name isEqualToString:source] == YES) {
            if ([APCDeviceHardware platformString] != nil) {
                answer = [APCDeviceHardware platformString];
            } else {
                answer = @"iPhone";    //    theoretically should not happen
            }
        }
        return answer;
    };

    NSString*(^QuantityDataSerializer)(id, HKUnit*) = ^NSString*(id dataSample, HKUnit* unit)
    {
        HKQuantitySample*   qtySample           = (HKQuantitySample *)dataSample;
        NSString*           startDateTimeStamp  = [qtySample.startDate toStringInISO8601Format];
        NSString*           endDateTimeStamp    = [qtySample.endDate toStringInISO8601Format];
        NSString*           healthKitType       = qtySample.quantityType.identifier;
        NSNumber*           quantityValue       = @([qtySample.quantity doubleValueForUnit:unit]);
        NSString*           quantityUnit        = unit.unitString;
        NSString*           sourceIdentifier    = qtySample.source.bundleIdentifier;
        NSString*           quantitySource      = qtySample.source.name;

        quantitySource = determineQuantitySource(quantitySource);

        NSString *stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                                   startDateTimeStamp,
                                   endDateTimeStamp,
                                   healthKitType,
                                   quantityValue,
                                   quantityUnit,
                                   quantitySource,
                                   sourceIdentifier];
        return stringToWrite;
    };

    NSString*(^WorkoutDataSerializer)(id) = ^(id dataSample)
    {
        HKWorkout*  sample                      = (HKWorkout*)dataSample;
        NSString*   startDateTimeStamp          = [sample.startDate toStringInISO8601Format];
        NSString*   endDateTimeStamp            = [sample.endDate toStringInISO8601Format];
        NSString*   healthKitType               = sample.sampleType.identifier;
        NSString*   activityType                = [HKWorkout apc_workoutActivityTypeStringRepresentation:(int)sample.workoutActivityType];
        double      energyConsumedValue         = [sample.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]];
        NSString*   energyConsumed              = [NSString stringWithFormat:@"%f", energyConsumedValue];
        NSString*   energyUnit                  = [HKUnit kilocalorieUnit].description;
        double      totalDistanceConsumedValue  = [sample.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
        NSString*   totalDistance               = [NSString stringWithFormat:@"%f", totalDistanceConsumedValue];
        NSString*   distanceUnit                = [HKUnit meterUnit].description;
        NSString*   sourceIdentifier            = sample.source.bundleIdentifier;
        NSString*   quantitySource              = sample.source.name;

        quantitySource = determineQuantitySource(quantitySource);

        NSError*    error                       = nil;
        NSString*   metaData                    = [NSDictionary apc_stringFromDictionary:sample.metadata error:&error];

        if (!metaData)
        {
            if (error)
            {
                APCLogError2(error);
            }

            metaData = @"";
        }

        NSString*   metaDataStringified         = [NSString stringWithFormat:@"\"%@\"", metaData];
        NSString*   stringToWrite               = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                                                   startDateTimeStamp,
                                                   endDateTimeStamp,
                                                   healthKitType,
                                                   activityType,
                                                   totalDistance,
                                                   distanceUnit,
                                                   energyConsumed,
                                                   energyUnit,
                                                   quantitySource,
                                                   sourceIdentifier,
                                                   metaDataStringified];
        return stringToWrite;
    };

    NSString*(^CategoryDataSerializer)(id) = ^NSString*(id dataSample)
    {
        HKCategorySample*   catSample       = (HKCategorySample *)dataSample;
        NSString*           stringToWrite   = nil;

        if ([catSample.categoryType.identifier isEqualToString:@"HKCategoryTypeIdentifierSleepAnalysis"])
        {
            NSString*           startDateTime   = [catSample.startDate toStringInISO8601Format];
            NSString*           healthKitType   = catSample.sampleType.identifier;
            NSString*           categoryValue   = nil;

            if (catSample.value == HKCategoryValueSleepAnalysisAsleep)
            {
                categoryValue = @"HKCategoryValueSleepAnalysisAsleep";
            }
            else
            {
                categoryValue = @"HKCategoryValueSleepAnalysisInBed";
            }

            NSString*           quantityUnit        = [[HKUnit secondUnit] unitString];
            NSString*           sourceIdentifier    = catSample.source.bundleIdentifier;
            NSString*           quantitySource      = catSample.source.name;

            quantitySource = determineQuantitySource(quantitySource);

            // Get the difference in seconds between the start and end date for the sample
            // Note: syoung 12/21/2015 merging from mPower-AppStore version commit 46de15ca7683a4c6a68af878212900af7ab4e848
            NSDateComponents* secondsSpentInBedOrAsleep = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond
                                                                                          fromDate:catSample.startDate
                                                                                            toDate:catSample.endDate
                                                                                           options:NSCalendarWrapComponents];
            NSString*           quantityValue   = [NSString stringWithFormat:@"%ld", (long)secondsSpentInBedOrAsleep.second];

            stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                             startDateTime,
                             healthKitType,
                             categoryValue,
                             quantityValue,
                             quantityUnit,
                             sourceIdentifier,
                             quantitySource];
        }
        return stringToWrite;
    };
    
    NSArray* dataTypesWithReadPermission = [self healthKitQuantityTypesToRead];
    
    if (!self.passiveDataCollector)
    {
        self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
    }

    // Just a note here that we are using n collectors to 1 data sink for quantity sample type data.
    NSArray*                    quantityColumnNames = @[@"startTime,endTime,type,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         quantityreceiver    =[[APCPassiveDataSink alloc] initWithQuantityIdentifier:@"HealthKitDataCollector"
                                                                                                columnNames:quantityColumnNames
                                                                                         operationQueueName:@"APCHealthKitQuantity Activity Collector"
                                                                                              dataProcessor:QuantityDataSerializer
                                                                                          fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    workoutColumnNames  = @[@"startTime,endTime,type,workoutType,total distance,unit,energy consumed,unit,source,sourceIdentifier,metadata"];
    APCPassiveDataSink*         workoutReceiver     = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitWorkoutCollector"
                                                                                         columnNames:workoutColumnNames
                                                                                  operationQueueName:@"APCHealthKitWorkout Activity Collector"
                                                                                       dataProcessor:WorkoutDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    categoryColumnNames = @[@"startTime,type,category value,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         sleepReceiver       = [[APCPassiveDataSink alloc] initWithIdentifier:@"HealthKitSleepCollector"
                                                                                         columnNames:categoryColumnNames
                                                                                  operationQueueName:@"APCHealthKitSleep Activity Collector"
                                                                                       dataProcessor:CategoryDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];

    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKSampleType* sampleType = nil;

            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary *) dataType;

                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }

            if (sampleType)
            {
                // This is really important to remember that we are creating as many user defaults as there are healthkit permissions here.
                NSString*                               uniqueAnchorDateName    = [NSString stringWithFormat:@"APCHealthKit%@AnchorDate", dataType];
                APCHealthKitBackgroundDataCollector*    collector               = nil;
                APCPassiveDataSink*                     receiver                = nil;

                //If the HKObjectType is a HKWorkoutType then set a different receiver/data sink.
                if (([sampleType isKindOfClass:[HKWorkoutType class]]) || ([sampleType isKindOfClass:[HKCategoryType class]]))
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    
                    receiver = [sampleType isKindOfClass:[HKWorkoutType class]] ? workoutReceiver : sleepReceiver;
                }
                else
                {
                    NSDictionary* hkUnitKeysAndValues = [self researcherSpecifiedUnits];

                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithQuantityTypeIdentifier:sampleType.identifier
                                                                                                 sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                                           launchDateAnchor:LaunchDate
                                                                                                healthStore:self.dataSubstrate.healthStore
                                                                                                       unit:[hkUnitKeysAndValues objectForKey:sampleType.identifier]];
                    receiver = quantityreceiver;
                }
                [collector setReceiver:receiver];
                [collector setDelegate:receiver];

                [collector start];
                [self.passiveDataCollector addDataSink:collector];
            }
        }
    }
}

/*********************************************************************************/
#pragma mark - APCOnboardingManagerProvider Methods
/*********************************************************************************/

- (APCScene *)inclusionCriteriaSceneForOnboarding:(APCOnboarding *) __unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.storyboardId = @"APHInclusionCriteriaViewController";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [self storyboardBundle];

    return scene;
}

-(APCPermissionsManager * __nonnull)permissionsManager
{
    return [[APCPermissionsManager alloc] initWithHealthKitCharacteristicTypesToRead:[self healthKitCharacteristicTypesToRead]
                                                        healthKitQuantityTypesToRead:[self healthKitQuantityTypesToRead]
                                                       healthKitQuantityTypesToWrite:[self healthKitQuantityTypesToWrite]
                                                                   userInfoItemTypes:[self userInfoItemTypes]
                                                               signUpPermissionTypes:[self signUpPermissionsTypes]];
}

- (NSArray *)healthKitCharacteristicTypesToRead
{
    return @[
             HKCharacteristicTypeIdentifierBiologicalSex,
             HKCharacteristicTypeIdentifierDateOfBirth
             ];
}

- (NSArray *)healthKitQuantityTypesToWrite
{
    return @[];
}

- (NSArray *)healthKitQuantityTypesToRead
{
    return @[
             HKQuantityTypeIdentifierBodyMass,
             HKQuantityTypeIdentifierHeight,
             HKQuantityTypeIdentifierStepCount,
             HKQuantityTypeIdentifierDistanceCycling,
             HKQuantityTypeIdentifierDistanceWalkingRunning,
             HKQuantityTypeIdentifierFlightsClimbed,
             @{kHKWorkoutTypeKey  : HKWorkoutTypeIdentifier},
             @{kHKCategoryTypeKey : HKCategoryTypeIdentifierSleepAnalysis}
             ];
}

- (NSArray *)signUpPermissionsTypes
{
    return @[
             @(kAPCSignUpPermissionsTypeLocation),
             @(kAPCSignUpPermissionsTypeCoremotion),
             @(kAPCSignUpPermissionsTypeMicrophone),
             @(kAPCSignUpPermissionsTypeLocalNotifications)
             ];
}

- (NSArray *)userInfoItemTypes
{
    return  @[
              @(kAPCUserInfoItemTypeEmail),
              @(kAPCUserInfoItemTypeDateOfBirth),
              @(kAPCUserInfoItemTypeBiologicalSex),
              @(kAPCUserInfoItemTypeHeight),
              @(kAPCUserInfoItemTypeWeight),
              @(kAPCUserInfoItemTypeWakeUpTime),
              @(kAPCUserInfoItemTypeSleepTime),
              @(kAPCUserInfoItemTypeDataGroups)
              ];
}


/*********************************************************************************/
#pragma mark - Tab Bar Stuff
/*********************************************************************************/


- (NSMutableArray <APCScene *> *)tabBarScenes
{
    NSMutableArray *scenes = [super tabBarScenes];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), kDashBoardStoryBoardKey];
    APCScene *scene = [[scenes filteredArrayUsingPredicate:predicate] firstObject];
    scene.storyboardName = @"APHDashboard";
    scene.bundle = [self storyboardBundle];

	predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(identifier)), kActivitiesStoryBoardKey];
	APCScene *activitiesScene = [[scenes filteredArrayUsingPredicate:predicate] firstObject];
	activitiesScene.storyboardName = @"APHActivities";
	activitiesScene.bundle = [self storyboardBundle];

    return scenes;
}

@end
