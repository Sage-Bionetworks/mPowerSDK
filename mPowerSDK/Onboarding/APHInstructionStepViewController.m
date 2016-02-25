//
//  APHInstructionStepViewController.m
//  mPowerSDK
//
//  Created by Shannon Young on 2/23/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHInstructionStepViewController.h"
#import <APCAppCore/APCAppCore.h>

@interface APHInstructionStepViewController () <APCNavigationFooterDelegate>

@property (nonatomic, readonly) ORKInstructionStep *instructionStep;

@property (weak, nonatomic) IBOutlet APCNavigationFooter *navigationFooter;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailTextLabel;

@end

@implementation APHInstructionStepViewController

- (ORKInstructionStep *)instructionStep {
    if ([self.step isKindOfClass:[ORKInstructionStep class]]) {
        return (ORKInstructionStep*)self.step;
    }
    return nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.imageView.image = self.instructionStep.image;
    self.textLabel.text = self.instructionStep.text;
    self.detailTextLabel.text = self.instructionStep.detailText;
}

@end
