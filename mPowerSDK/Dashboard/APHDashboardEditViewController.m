// 
//  APHDashboardEditViewController.m 
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
 
#import "APHDashboardEditViewController.h"
#import "APHDataKeys.h"
#import "APHLocalization.h"

@implementation APHDashboardEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareData];
}

- (void)prepareData
{
    [self.items removeAllObjects];
    
    {
        for (NSNumber *typeNumber in self.rowItemsOrder) {
            
            APHDashboardItemType rowType = typeNumber.integerValue;
            
            switch (rowType) {
                case kAPHDashboardItemTypeIntervalTappingRight:
                case kAPHDashboardItemTypeIntervalTappingLeft:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    if (rowType == kAPHDashboardItemTypeIntervalTappingRight) {
                        item.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_RIGHT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Right", @"Dashboard caption for results of right hand tapping activity.");
                    }
                    else {
                        item.caption = NSLocalizedStringWithDefaultValue(@"APH_TAPPING_LEFT_CAPTION", nil, APHLocaleBundle(), @"Tapping - Left", @"Dashboard caption for results of left hand tapping activity.");
                    }
                    item.taskId = APHTappingActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                case kAPHDashboardItemTypeGait:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_WALKING_CAPTION", nil, APHLocaleBundle(), @"Gait", @"Dashboard caption for results of walking activity.");
                    item.taskId = APHWalkingActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypeSpatialMemory:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_MEMORY_CAPTION", nil, APHLocaleBundle(), @"Memory", @"Dashboard caption for results of memory activity.");
                    item.taskId = APHMemoryActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypePhonation:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_VOICE_CAPTION", nil, APHLocaleBundle(), @"Voice", @"Dashboard caption for results of voice activity.");
                    item.taskId = APHVoiceActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypeSteps:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_STEPS_CAPTION", nil, APHLocaleBundle(), @"Steps", @"Dashboard caption for results of steps score.");
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    [self.items addObject:item];
                }
                    break;
                    
                case kAPHDashboardItemTypeCorrelation:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DATA_CORRELATION_CAPTION", nil, APHLocaleBundle(), @"Data Correlations", @"Dashboard caption for data correlation.");
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeTremor:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_TREMOR_CAPTION", nil, APHLocaleBundle(), @"Tremor", @"Dashboard caption for results of tremor activity.");
                    item.taskId = APHTremorActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                    
                    
                case kAPHDashboardItemTypeDailyMood:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_MOOD_CAPTION", nil, APHLocaleBundle(), @"Mood", @"Dashboard caption for daily mood report");
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyEnergy:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_ENERGY_CAPTION", nil, APHLocaleBundle(), @"Energy Level", @"Dashboard caption for daily energy report");
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyExercise:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_EXERCISE_CAPTION", nil, APHLocaleBundle(), @"Exercise Level", @"Dashboard caption for daily exercise report");
                    item.tintColor = [UIColor appTertiaryYellowColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailySleep:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_SLEEP_CAPTION", nil, APHLocaleBundle(), @"Sleep Quality", @"Dashboard caption for daily sleep quality report");
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyCognitive:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_THINKING_CAPTION", nil, APHLocaleBundle(), @"Thinking", @"Dashboard caption for daily mental clarity report");
                    item.tintColor = [UIColor appTertiaryRedColor];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                    
                case kAPHDashboardItemTypeDailyCustom:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedStringWithDefaultValue(@"APH_DAILY_CUSTOM_CAPTION", nil, APHLocaleBundle(), @"Custom Question", @"Dashboard caption for daily user-defined custom question report");
                    item.tintColor = [UIColor appTertiaryBlueColor];
                    
                    [self.items addObject:item];
                }
                    break;

                default:
                    break;
            }
        }
    }
}

@end
