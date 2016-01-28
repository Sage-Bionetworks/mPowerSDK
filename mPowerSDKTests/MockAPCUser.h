//
//  MockAPCUser.h
//  mPowerSDK
//
//  Created by Shannon Young on 1/27/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@interface MockAPCUser : APCUser

@property (nonatomic, strong) NSManagedObjectContext *tempContext;

@property (nonatomic) NSArray <NSString *> *mockDataGroups;
@property (nonatomic) NSError *updateDataGroupsError;
@property (nonatomic) BOOL updateDataGroups_called;
@property (nonatomic, copy) void (^updateDataGroupsCompletionCalled)(void);

@end
