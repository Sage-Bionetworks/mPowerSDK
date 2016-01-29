//
//  NSArray+APHExtensions.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "NSArray+APHExtensions.h"

@implementation NSArray (APHExtensions)

- (id _Nullable)objectWithIdentifier:(NSString*)identifier {
    for (id obj in self) {
        if ([obj respondsToSelector:@selector(identifier)] && [[obj identifier] isEqual:identifier]) {
            return obj;
        }
    }
    return nil;
}

- (NSArray *)filteredArrayWithIdentifiers:(NSArray <NSString *> *)identifiers {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", NSStringFromSelector(@selector(identifier)), identifiers];
    return [self filteredArrayUsingPredicate:predicate];
}

- (NSArray <NSString *> *)identifiers {
    return [self valueForKey:NSStringFromSelector(@selector(identifier))];
}

@end
