// 
//  APHPhonationTaskViewController.m 
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

#import "APHPhonationTaskViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <APCAppCore/APCAppCore.h>
#import "APHAppDelegate.h"
#import "APHDataKeys.h"
#import "APHScoreCalculator.h"
#import "APHLocalization.h"
#import "APHActivityManager.h"

    //
    //        Step Identifiers
    //
static  NSString *const kInstructionStepIdentifier            = @"instruction";
static  NSString *const kInstruction1StepIdentifier           = @"instruction1";
static  NSString *const kCountdownStepIdentifier              = @"countdown";
static  NSString *const kAudioStepIdentifier                  = @"audio";
static  NSString *const kConclusionStepIdentifier             = @"conclusion";

static const NSInteger kPhonationActivitySchemaRevision       = 3;

@interface APHPhonationTaskViewController ( )  <ORKTaskViewControllerDelegate>

@property (nonatomic, getter=isTooLoud) BOOL tooLoud;

@end

@implementation APHPhonationTaskViewController

#pragma  mark  -  Initialisation

+ (id<ORKTask>)createOrkTask:(APCTask *) __unused scheduledTask
{
    //  Adjust apperance and text for the task
    [[UIView appearance] setTintColor:[UIColor appPrimaryColor]];
    
    return  [[APHActivityManager defaultManager] createTaskForSurveyId:APHVoiceActivitySurveyIdentifier];
}

#pragma mark - UI overrides

- (UIColor*)tintColorForStep:(ORKStep*)step {
    if ([step.identifier isEqualToString: kAudioStepIdentifier]) {
        return [UIColor appTertiaryBlueColor];
    }
    return [super tintColorForStep:step];
}

#pragma  mark  -  Task View Controller Delegate Methods

- (BOOL)taskViewController:(ORKTaskViewController *) __unused taskViewController shouldPresentStep:(ORKStep *)step
{
    if (self.isTooLoud) {
        
        NSString *message = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_TOO_LOUD_MESSAGE", nil, APHLocaleBundle(), @"The ambient noise level is too loud to record your voice. Please move somewhere quieter and try again.", @"Message for attemping to do a voice task when it's too loud.");
        
        NSError *error = [NSError errorWithDomain:@"APHErrorDomain"
                                             code:-1
                                         userInfo:@{@"reason" : message}];
        
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * __unused action) {
                                                                  [self taskViewController:self didFinishWithReason:ORKTaskViewControllerFinishReasonFailed error:error];
                                                              }];
        [alertView addAction:defaultAction];
        [self presentViewController:alertView animated:YES completion:nil];
        
        return NO;
    }
    return YES;
}

- (void)taskViewController:(ORKTaskViewController *) __unused taskViewController didChangeResult:(ORKTaskResult *)result
{
    if ([self.currentStepViewController.step.identifier isEqualToString:kCountdownStepIdentifier]) {
    
        // Get the result file
        ORKStepResult *stepResult = (ORKStepResult *)[result resultForIdentifier:kCountdownStepIdentifier];
        ORKFileResult *audioLevelResult = (ORKFileResult *)[stepResult.results firstObject];
        NSAssert(audioLevelResult.fileURL != nil, @"Missing expected audio recorder result for countdown.");
        
        // Check the volume
        if (audioLevelResult.fileURL != nil) {
            self.tooLoud = [self checkAudioLevelFromSoundFile:audioLevelResult.fileURL];
        }
    }
}

- (void)taskViewController: (ORKTaskViewController *) taskViewController didFinishWithReason: (ORKTaskViewControllerFinishReason)reason error: (NSError *) error
{
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];
    
    if (reason  == ORKTaskViewControllerFinishReasonFailed) {
        if (error != nil) {
            APCLogError2 (error);
        }
    }
    [super taskViewController: taskViewController didFinishWithReason: reason error: error];
}

#pragma  mark  -  Results For Dashboard

- (NSString *)createResultSummary
{
    ORKTaskResult  *taskResults = self.result;
    self.createResultSummaryBlock = ^(NSManagedObjectContext * context) {
        
        ORKFileResult  *fileResult = nil;
        BOOL  found = NO;
        for (ORKStepResult  *stepResult  in  taskResults.results) {
            if (stepResult.results.count > 0) {
                for (id  object  in  stepResult.results) {
                    if ([object isKindOfClass:[ORKFileResult class]] == YES) {
                        found = YES;
                        fileResult = object;
                        break;
                    }
                }
                if (found == YES) {
                    break;
                }
            }
        }
        
        double scoreSummary = [[APHScoreCalculator sharedCalculator] scoreFromPhonationTest: fileResult.fileURL];
        scoreSummary = isnan(scoreSummary) ? 0 : scoreSummary;
        
        NSDictionary  *summary = @{APHPhonationScoreSummaryOfRecordsKey : @(scoreSummary)};
        
        NSError  *error = nil;
        NSData  *data = [NSJSONSerialization dataWithJSONObject:summary options:0 error:&error];
        NSString  *contentString = nil;
        if (data == nil) {
            APCLogError2 (error);
        } else {
            contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        
        if (contentString.length > 0)
        {
            [APCResult updateResultSummary:contentString forTaskResult:taskResults inContext:context];
        }
    };
    return nil;
}

#pragma  mark  - Settings

- (APCSignUpPermissionsType)requiredPermission {
    return kAPCSignUpPermissionsTypeMicrophone;
}

- (void) updateSchemaRevision
{
    if (self.scheduledTask) {
        self.scheduledTask.taskSchemaRevision = [NSNumber numberWithInteger:kPhonationActivitySchemaRevision];
    }
}


#pragma  mark  - View Controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"APH_PHONATION_NAV_TITLE", nil, APHLocaleBundle(), @"Voice Activity", @"Nav bar title for Voice activity view");
   
   // Once you give Audio permission to the application. Your app will not show permission prompt again.
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            // Microphone enabled
        } else {
            // Microphone disabled
            //Inform the user that they will to enable the Microphone
            UIAlertController * alert = [UIAlertController simpleAlertWithTitle:NSLocalizedStringWithDefaultValue(@"APH_PHONATION_ENABLE_MIC_ALERT_MSG", nil, APHLocaleBundle(), @"You need to enable access to microphone.", @"Alert message when microphone access not enabled for this app when trying to perform Voice activity.") message:nil];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Check DB Level
// syoung 01/12/2016 May wish to move this into AppCore/ResearchKit framework at some point but leave it here
// while the algorithm is still being tweeked.

Float32 const kVolumeThreshold = 0.4;
UInt16  const kLinearPCMBitDepth = 16;
Float32 const kMaxAmplitude = 32767.0;
Float32 const kVolumeClamp = 60.0;

- (BOOL)checkAudioLevelFromSoundFile:(NSURL *)fileURL
{
    // Setup reader
    AVURLAsset * urlAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    if (urlAsset.tracks.count == 0) {
        NSLog(@"No tracks found for urlAsset: %@", fileURL);
        return NO;
    }

    NSError * error = nil;
    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:urlAsset error:&error];
    AVAssetTrack * track = [urlAsset.tracks objectAtIndex:0];
    NSDictionary * outputSettings = @{   AVFormatIDKey                  : @(kAudioFormatLinearPCM),
                                         AVLinearPCMBitDepthKey         : @(kLinearPCMBitDepth),
                                         AVLinearPCMIsBigEndianKey      : @(NO),
                                         AVLinearPCMIsFloatKey          : @(NO),
                                         AVLinearPCMIsNonInterleaved    : @(NO)};
    AVAssetReaderTrackOutput* output = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:outputSettings];
    [reader addOutput:output];

    // Setup initial values - Assume 2 channels
    const UInt32 channelCount = 2;
    const UInt32 bytesPerSample = 2 * channelCount;
    
    // setup criteria block - Use a high-pass filter and a rolling average of the amplitude
    // normalized to be < 1
    __block Float32 rollingAvg = 0;
    __block UInt64 totalCount = 0;
    void (^processVolume)(Float32) = ^(Float32 amplitude) {
        if (amplitude != 0) {
            Float32 dB = 20 * log10(ABS(amplitude)/kMaxAmplitude);
            float clampedValue = MAX(dB/kVolumeClamp, -1) + 1;
            totalCount++;
            rollingAvg = (rollingAvg * (totalCount - 1) + clampedValue) / totalCount;
        }
    };
    
    // While there are samples to read and the number of samples above the decibel threshold
    // is less than the total number of allowed samples over the limit, keep going
    [reader startReading];
    while (reader.status == AVAssetReaderStatusReading) {
        
        AVAssetReaderTrackOutput * trackOutput = (AVAssetReaderTrackOutput *)[reader.outputs objectAtIndex:0];
        CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];
        
        if (sampleBufferRef){
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            
            NSMutableData * data = [NSMutableData dataWithLength:length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);
            
            SInt16 * samples = (SInt16 *) data.mutableBytes;
            UInt64 sampleCount = length / bytesPerSample;
            for (UInt32 i = 0; i < sampleCount ; i++) {
                Float32 left = (Float32) *samples++;
                processVolume(left);
                if (channelCount == 2) {
                    Float32 right = (Float32) *samples++;
                    processVolume(right);
                }
            }
            
            CMSampleBufferInvalidate(sampleBufferRef);
            CFRelease(sampleBufferRef);
        }
    }
    
    return rollingAvg > kVolumeThreshold;
}

@end
