//
//  APHMedicationTrackerViewController.m
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

#import "APHMedicationTrackerViewController.h"
#import "APHMedicationTrackerTask.h"
#import "APHActivityManager.h"

@interface APHMedicationTrackerViewController ()

@property (nonatomic, readonly) APHMedicationTrackerTask *medicationTrackerTask;
@property (nonatomic, readonly) APCUser *user;
@property (nonatomic, readonly) APHActivityManager *activityManager;

@end

@implementation APHMedicationTrackerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (id<ORKTask>)createOrkTask:(APCTask *) __unused scheduledTask {
    return  [APHMedicationTrackerTask new];
}

- (APHMedicationTrackerTask*)medicationTrackerTask {
    if ([self.task isKindOfClass:[APHMedicationTrackerTask class]]) {
        return (APHMedicationTrackerTask*)self.task;
    }
    return nil;
}

- (APCUser*)user {
    return [[[APCAppDelegate sharedAppDelegate] dataSubstrate] currentUser];
}

- (APHActivityManager*)activityManager {
    return [APHActivityManager defaultManager];
}

- (void)taskViewController:(ORKTaskViewController * __unused)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(nullable NSError *)error
{
    if (reason == ORKTaskViewControllerFinishReasonCompleted) {
        APHMedicationTrackerTask *medTask = [self medicationTrackerTask];
        
        // Save the changes to the data groups back to the user
        if (medTask.dataGroupsManager.hasChanges) {
            [self.user updateDataGroups:medTask.dataGroupsManager.dataGroups onCompletion:nil];
        }
        
        // Save the result of the medication tracker to the activity manager
        [self.activityManager saveTrackedMedications:
         [medTask selectedMedicationFromResult:self.result trackingOnly:YES pillOnly:YES]];
    }
    [super taskViewController:taskViewController didFinishWithReason:reason error:error];
}



@end
