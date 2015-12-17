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
                    item.caption = (rowType == kAPHDashboardItemTypeIntervalTappingRight)  ?
                        NSLocalizedString(@"Tapping - Right", @"") :
                        NSLocalizedString(@"Tapping - Left", @"");
                    item.taskId = APHTappingActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                    
                }
                    break;
                case kAPHDashboardItemTypeGait:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Gait", @"");
                    item.taskId = APHWalkingActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypeSpatialMemory:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Memory", @"");
                    item.taskId = APHMemoryActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypePhonation:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Voice", @"");
                    item.taskId = APHVoiceActivitySurveyIdentifier;
                    item.tintColor = [UIColor colorForTaskId:item.taskId];
                    
                    [self.items addObject:item];
                }
                    break;
                case kAPHDashboardItemTypeSteps:{
                    
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Steps", @"");
                    item.tintColor = [UIColor appTertiaryGreenColor];
                    
                    [self.items addObject:item];
                }
                    break;
                    
                case kAPHDashboardItemTypeCorrelation:
                {
                    APCTableViewDashboardItem *item = [APCTableViewDashboardItem new];
                    item.caption = NSLocalizedString(@"Data Correlations", @"");
                    item.tintColor = [UIColor appTertiaryPurpleColor];
                    
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
