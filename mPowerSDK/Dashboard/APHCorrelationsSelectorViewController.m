//
//  APHCorrelationsSelectorViewController.m
//  mPowerSDK
//
// Copyright (c) 2015, Apple Inc. All rights reserved.
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

#import "APHCorrelationsSelectorViewController.h"
#import "APHLocalization.h"
#import "APHScoring.h"

#import <APCAppCore/UIColor+APCAppearance.h>

NSInteger const kAPHCorrelationsSelectorViewHeaderHeight = 44.0;
NSInteger const kAPHCorrelationsSelectorViewCellHeight = 80.0;
NSInteger const kAPHCorrelationsSelectorViewButtonWidth = 100.0;

@interface APHCorrelationsSelectorViewController ()
@property (strong, nonatomic) APHScoring *scoring;
@property (strong, nonatomic) NSArray *scoringObjects;

@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic) CGRect downFrame;
@property (nonatomic) CGRect upFrame;

@end

@implementation APHCorrelationsSelectorViewController 

- (id)initWithScoringObjects:(NSArray *)scoringObjects
{
    self = [super init];
    if (self) {
        self.scoringObjects = scoringObjects;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    
    [self initTableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)__unused animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    [self moveUpTableViewWithCompletion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Helper Functions

- (void)dismissView
{
    [self moveDownTableViewWithCompletion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)initTableView
{
    self.downFrame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - 20);
    self.upFrame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 20);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.downFrame style:UITableViewStylePlain];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.sectionHeaderHeight = kAPHCorrelationsSelectorViewHeaderHeight;
    self.tableView.rowHeight = kAPHCorrelationsSelectorViewCellHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)moveUpTableViewWithCompletion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.tableView.frame = self.upFrame;
     }
     completion:^(BOOL finished) {
         if (completion) {
             completion(finished);
         }
     }];
}

- (void)moveDownTableViewWithCompletion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView
     animateWithDuration:0.5
     animations:^{
         self.tableView.frame = self.downFrame;
     }
     completion:^(BOOL finished) {
         if (completion) {
             completion(finished);
         }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section
{
    return self.scoringObjects.count;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)__unused tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *cancelString = NSLocalizedStringWithDefaultValue(@"Cancel", @"APCAppCore", APHLocaleBundle(), @"Cancel", nil);
    
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    cancel.frame = CGRectMake(self.tableView.frame.size.width - kAPHCorrelationsSelectorViewButtonWidth,
                              0,
                              kAPHCorrelationsSelectorViewButtonWidth,
                              kAPHCorrelationsSelectorViewHeaderHeight);
    [cancel setTitle:cancelString forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor appTertiaryRedColor] forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    cancel.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
    
    UITableViewHeaderFooterView *headerView = [[UITableViewHeaderFooterView alloc] init];
    headerView.textLabel.text = NSLocalizedStringWithDefaultValue(@"Select Category", @"APCAppCore", APHLocaleBundle(), @"Select Category", nil);
    [headerView addSubview:cancel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    APCScoring *scoringObject = [self.scoringObjects objectAtIndex:indexPath.row];
    cell.textLabel.text = scoringObject.caption;
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    if (scoringObject == self.selectedObject) {
        cell.textLabel.textColor = self.view.tintColor;
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        cell.textLabel.textColor = [UIColor appSecondaryColor1];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //initialize a new scoring object - cannot corrupt the original data by indexing
    APHScoring *referenceScoring = [self.scoringObjects objectAtIndex:indexPath.row];
    [self updateSection:indexPath.section WithSelectedScoringObject:referenceScoring];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    [self dismissView];
}

- (void)updateSection:(NSInteger)section WithSelectedScoringObject:(APHScoring *)selectedObject
{
    self.selectedObject = selectedObject;
    
    [self.delegate didChangeCorrelatedScoringDataSourceForCorrelationIndex:self.selectedCorrelationIndex withScoring:self.selectedObject];
}

@end
