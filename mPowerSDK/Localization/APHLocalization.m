//
//  APHLocalization.m
//  mPowerSDK
//
//  Created by Shannon Young on 12/28/15.
//  Copyright © 2015 Sage Bionetworks. All rights reserved.
//

#import "APHLocalization.h"
#import "APHAppDelegate.h"

NSBundle *APHBundle() {
    static NSBundle *__bundle;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __bundle = [NSBundle bundleForClass:[APHAppDelegate class]];
    });
    
    return __bundle;
}
