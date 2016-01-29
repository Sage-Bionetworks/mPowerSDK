//
//  NSNull+APHExtensions.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNull (APHExtensions)

@property (readonly) short shortValue;
@property (readonly) unsigned short unsignedShortValue;
@property (readonly) int intValue;
@property (readonly) unsigned int unsignedIntValue;
@property (readonly) long longValue;
@property (readonly) unsigned long unsignedLongValue;
@property (readonly) long long longLongValue;
@property (readonly) unsigned long long unsignedLongLongValue;
@property (readonly) float floatValue;
@property (readonly) double doubleValue;
@property (readonly) BOOL boolValue;
@property (readonly) NSInteger integerValue;
@property (readonly) NSUInteger unsignedIntegerValue;
@property (readonly) NSString *stringValue;

@end
