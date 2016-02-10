//
//  APHNavigationFooter.h
//  mPowerSDK
//
//  Created by Shannon Young on 2/23/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol APHNavigationFooterDelegate <NSObject>

- (void)goForward;

@end

@interface APHNavigationFooter : UIView

@property (weak, nonatomic) IBOutlet id <APHNavigationFooterDelegate> delegate;
@property (nonatomic) UIButton *continueButton;

@end
