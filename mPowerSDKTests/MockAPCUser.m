//
//  MockAPCUser.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/27/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "MockAPCUser.h"

@implementation MockAPCUser

- (instancetype)init {
    
    // Create the temp moc
    NSBundle *bundle = [NSBundle bundleForClass:[APCUser class]];
    NSString *modelPath = [bundle pathForResource:@"APCModel" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    
    self = [super initWithContext:moc];
    if (self) {
        // Keep a strong pointer to the moc on this object - DO NOT do this except for testing.
        _tempContext = moc;
    }
    
    return self;
}

#pragma mark - data groups

- (NSArray *)dataGroups {
    return self.mockDataGroups;
}

- (void)setDataGroups:(NSArray *)dataGroups {
    self.mockDataGroups = dataGroups;
}

- (void)updateDataGroups:(NSArray<NSString *> *)dataGroups onCompletion:(void (^)(NSError *))completionBlock {
    self.updateDataGroups_called = YES;
    dispatch_after(0.1, dispatch_get_main_queue(), ^{
        self.mockDataGroups = dataGroups;
        if (completionBlock) {
            completionBlock(self.updateDataGroupsError);
        }
        if (self.updateDataGroupsCompletionCalled) {
            self.updateDataGroupsCompletionCalled();
        }
    });
}

@end
