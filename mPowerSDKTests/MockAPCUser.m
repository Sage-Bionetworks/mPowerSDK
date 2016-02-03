//
//  MockAPCUser.m
//  mPowerSDK
//
// Copyright (c) 2016, Sage Bionetworks. All rights reserved.
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
