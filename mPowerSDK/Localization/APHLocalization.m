//
//  APHLocalization.m
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

#import "APHLocalization.h"

@interface APHLocalization ()
@property (strong) NSBundle *localeBundle;
+ (instancetype)defaultInstance;
@end

NSBundle *APHLocaleBundle() {
    return [[APHLocalization defaultInstance] localeBundle];
}

@implementation APHLocalization

+ (instancetype)defaultInstance {
    static id __defaultInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultInstance = [[self alloc] init];
    });
    return __defaultInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _localeBundle = [NSBundle bundleForClass:[APHLocalization class]];
    }
    return self;
}

+ (void)setLocalization:(NSString*)localization {
    
    // Find the path to the bundle based on the locale
    NSBundle *frameworkBundle = [NSBundle bundleForClass:[APHLocalization class]];
    NSString *bundlePath = [frameworkBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:localization];
    
    // Load the requested bundle (if it exists)
    NSBundle *localizedBundle = [[NSBundle alloc] initWithPath:[bundlePath stringByDeletingLastPathComponent]];
    if (localizedBundle != nil) {
        [[APHLocalization defaultInstance] setLocaleBundle:localizedBundle];
    }
}

+ (NSString*)localizedStringWithKey:(NSString*)key {
    if ([key isEqualToString:@"APH_ACTIVITY_CONCLUSION_TEXT"]) {
        return NSLocalizedStringWithDefaultValue(@"APH_ACTIVITY_CONCLUSION_TEXT", nil, APHLocaleBundle(), @"Thank You!", @"Main text shown to participant upon completion of an activity.");
    }
    else if ([key isEqualToString:@"APH_NEXT_BUTTON"]) {
        return NSLocalizedStringWithDefaultValue(@"APH_NEXT_BUTTON", nil, APHLocaleBundle(), @"Next", @"Text for a 'Next' button");
    }
    return NSLocalizedStringFromTableInBundle(key, nil, APHLocaleBundle(), nil);
}

@end
