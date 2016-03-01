//
//  APHDashboardGraphTableViewCell.h
//  mPowerSDK
//
//  Created by Jake Krog on 2016-02-29.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <APCAppCore/APCAppCore.h>

@class APHScatterGraphView;
@protocol APHDashboardGraphTableViewCellMedicationDelegate;

@interface APHDashboardGraphTableViewCell : APCDashboardGraphTableViewCell

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *tintViews;
@property (weak, nonatomic) IBOutlet UIButton *enterMedicationsButton;
@property (weak, nonatomic) IBOutlet UIButton *notTakingMedicationsButton;
@property (weak, nonatomic) IBOutlet UIButton *doNotShowMedicationSurveyButton;

@property (weak, nonatomic) id <APHDashboardGraphTableViewCellMedicationDelegate> medicationDelegate;

@property (nonatomic) BOOL showMedicationLegend;
@property (nonatomic) BOOL showMedicationSurveyPrompt;

+ (CGFloat)medicationLegendContainerHeight;
+ (CGFloat)medicationSurveyPromptContainerHeight;

- (IBAction)enterMedicationsTapped:(id)sender;
- (IBAction)notTakingMedicationsTapped:(id)sender;
- (IBAction)doNotShowMedicationSurveyTapped:(id)sender;

@end

@protocol APHDashboardGraphTableViewCellMedicationDelegate <NSObject>

@optional
- (void)dashboardGraphTableViewCellDidTapEnterMedications:(APHDashboardGraphTableViewCell *)cell;

- (void)dashboardGraphTableViewCellDidTapNotTakingMedications:(APHDashboardGraphTableViewCell *)cell;

- (void)dashboardGraphTableViewCellDidTapDoNotShowMedicationSurvey:(APHDashboardGraphTableViewCell *)cell;

@end
