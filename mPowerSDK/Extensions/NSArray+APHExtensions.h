//
//  NSArray+APHExtensions.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/29/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (APHExtensions)

- (id _Nullable)objectWithIdentifier:(NSString *)identifier;
- (NSArray *)filteredArrayWithIdentifiers:(NSArray <NSString *> *)identifiers;
- (NSArray <NSString *> *)identifiers;

@end

NS_ASSUME_NONNULL_END
