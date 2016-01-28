//
//  MockAPCTaskResultArchiver.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/28/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface MockAPCTaskResultArchiver : APCTaskResultArchiver

@property (nonatomic) NSMutableDictionary *archivedResults;

@end
