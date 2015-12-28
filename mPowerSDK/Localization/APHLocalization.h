//
//  APHLocalization.h
//  mPowerSDK
//
//  Created by Shannon Young on 12/28/15.
//  Copyright © 2015 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef APH_EXTERN
#if defined(__cplusplus)
#define APH_EXTERN extern "C" __attribute__((visibility("default")))
#else
#define APH_EXTERN extern __attribute__((visibility("default")))
#endif
#endif

APH_EXTERN NSBundle *APHBundle();
