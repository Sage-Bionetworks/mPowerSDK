//
//  APHLocalization.m
//  mPowerSDK
//
//  Created by Shannon Young on 12/28/15.
//  Copyright © 2015 Sage Bionetworks. All rights reserved.
//

#import "APHLocalization.h"

static NSBundle *__bundle;

NSBundle *APHLocaleBundle() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__bundle == nil) {
            __bundle = [NSBundle bundleForClass:[APHLocalization class]];
        }
    });
    return __bundle;
}

@implementation APHLocalization

+ (void)setLocalization:(NSString*)localization {
    
    // Find the path to the bundle based on the locale
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[APHLocalization class]];
    NSString *bundlePath = [frameworkBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:localization];
    
    // Load the requested bundle (if it exists)
    NSBundle *localizedBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    if (localizedBundle != nil) {
        __bundle = localizedBundle;
    }
}

@end
