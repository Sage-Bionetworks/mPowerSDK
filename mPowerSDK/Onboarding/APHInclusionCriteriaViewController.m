// 
//  APHInclusionCriteriaViewController.m 
//  mPower 
// 
// Copyright (c) 2015, Sage Bionetworks. All rights reserved. 
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
 


#import "APHInclusionCriteriaViewController.h"
#import "APHAppDelegate.h"
#import <APCAppCore/APCAppCore.h>

@interface APHInclusionCriteriaViewController () <UITableViewDelegate, UITableViewDataSource, APCSegmentedButtonDelegate, APCNavigationFooterDelegate>

@property (weak, nonatomic) IBOutlet APCNavigationFooter *navigationFooter;
@property (nonatomic, readonly) ORKFormStep *formStep;
@property (nonatomic, readonly) UIButton *continueButton;
@property (nonatomic) NSMutableDictionary <NSString*, NSNumber*> *segmentedButtonMap;

@end

@implementation APHInclusionCriteriaViewController

- (ORKFormStep*)formStep {
    if ([self.step isKindOfClass:[ORKFormStep class]]) {
        return (ORKFormStep*)self.step;
    }
    return nil;
}

- (UIButton *)continueButton {
    return self.navigationFooter.continueButton;
}

- (NSMutableDictionary<NSString *,NSNumber *> *)segmentedButtonMap {
    if (_segmentedButtonMap == nil) {
        _segmentedButtonMap = [NSMutableDictionary new];
    }
    return _segmentedButtonMap;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.continueButton.enabled = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (self.formStep.formItems.count > 0) {
        // Resize the table to fix the device
        const CGFloat minCellHeight = 120;
        const CGFloat maxCellHeight = 175;
        const CGFloat minNavigationFooterHeight = 84;
        
        CGFloat itemCount = self.formStep.formItems.count;
        CGFloat overallHeight = self.tableView.bounds.size.height;
        CGFloat desiredCellHeight = floor((overallHeight - minNavigationFooterHeight)/itemCount);
        CGFloat cellHeight = MIN(maxCellHeight, MAX(minCellHeight, desiredCellHeight));
        CGFloat footerHeight = MAX(minNavigationFooterHeight, floor(overallHeight - cellHeight * itemCount));
        if (footerHeight != self.tableView.tableFooterView.bounds.size.height) {
            UIView *footer = self.tableView.tableFooterView;
            CGRect bounds = footer.bounds;
            bounds.size.height = footerHeight;
            footer.bounds = bounds;
            self.tableView.tableFooterView = footer;
        }
        if (self.tableView.rowHeight != cellHeight) {
            self.tableView.rowHeight = cellHeight;
        }
    }
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    APHInclusionCriteriaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BooleanCell" forIndexPath:indexPath];
    
    // Setup appearance
    if (cell.segmentedButton == nil) {
        cell.questionLabel.textColor = [UIColor appSecondaryColor1];
        cell.questionLabel.font = [UIFont appQuestionLabelFont];
        cell.yesButton.titleLabel.font = [UIFont appQuestionOptionFont];
        cell.noButton.titleLabel.font = [UIFont appQuestionOptionFont];
        cell.segmentedButton = [[APCSegmentedButton alloc] initWithButtons:@[cell.noButton, cell.yesButton] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]];
        cell.segmentedButton.delegate = self;
    }
    
    // Set values
    ORKFormItem *item = self.formStep.formItems[indexPath.row];
    cell.questionLabel.text = item.text;
    cell.segmentedButton.questionIdentifier = item.identifier;
    NSNumber *currentSelection = self.segmentedButtonMap[item.identifier];
    if (currentSelection != nil) {
        cell.segmentedButton.selectedIndex = currentSelection.integerValue;
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.formStep.formItems.count;
}

#pragma mark - Misc Fix

-(void)viewDidLayoutSubviews
{
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}

-(void)tableView:(UITableView *) __unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

#pragma mark - Segmented Button Delegate

- (void) segmentedButton:(APCSegmentedButton*)segmentedButton didSelectIndex:(NSInteger)selectedIndex {
    self.segmentedButtonMap[segmentedButton.questionIdentifier] = @(selectedIndex);
    self.continueButton.enabled = [self continueButtonEnabled];
    [self.delegate stepViewControllerResultDidChange:self];
}

#pragma mark - Overridden methods

- (ORKStepResult *)result {
    ORKStepResult *parentResult = [super result];
    
    NSArray *items = [self.formStep formItems];
    
    // "Now" is the end time of the result, which is either actually now,
    // or the last time we were in the responder chain.
    NSDate *now = parentResult.endDate;
    
    NSMutableArray *qResults = [NSMutableArray new];
    for (ORKFormItem *item in items) {
        ORKBooleanQuestionResult *result = [[ORKBooleanQuestionResult alloc] initWithIdentifier:item.identifier];
        result.booleanAnswer = self.segmentedButtonMap[item.identifier];
        result.startDate = now;
        result.endDate = now;
        [qResults addObject:result];
    }
    
    parentResult.results = [qResults copy];
    
    return parentResult;
}

#pragma mark - navigation handling

- (void)setContinueButtonTitle:(NSString *)continueButtonTitle {
    [super setContinueButtonTitle:continueButtonTitle];
    self.continueButton.titleLabel.text = continueButtonTitle;
}

- (BOOL)continueButtonEnabled
{
    for (ORKFormItem* item in self.formStep.formItems) {
        if (self.segmentedButtonMap[item.identifier] == nil) {
            return NO;
        }
    }
    return YES;
}

@end


@implementation APHInclusionCriteriaTableViewCell
@end