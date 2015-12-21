//
//  APHFinalAppDelegate.m
//  Parkinson
//
//  Created by Shannon Young on 12/18/15.
//  Copyright © 2015 Apple, Inc. All rights reserved.
//

#import "APHFinalAppDelegate.h"

@implementation APHFinalAppDelegate

- (void)setUpAppAppearance
{
    [super setUpAppAppearance];
    
    self.dataSubstrate.parameters.bypassServer = YES;
    self.dataSubstrate.parameters.hideExampleConsent = NO;
}

@end
