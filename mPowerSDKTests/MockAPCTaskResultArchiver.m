//
//  MockAPCTaskResultArchiver.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/28/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPCTaskResultArchiver.h"

@implementation MockAPCTaskResultArchiver

- (instancetype)init {
    if ((self = [super init])) {
        _archivedResults = [NSMutableDictionary new];
    }
    return self;
}

- (void)appendArchive:(APCDataArchive*)archive withTaskResult:(ORKTaskResult *)result {
    self.archivedResults[result.identifier] = @{@"archive" : archive,
                                                @"result" : result};
}

@end
