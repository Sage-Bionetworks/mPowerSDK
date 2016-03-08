//
//  APHTableViewDashboardGraphItem.m
//  mPowerSDK
//
//  Created by Jake Krog on 2016-03-01.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import "APHTableViewDashboardGraphItem.h"


@implementation APHTableViewDashboardGraphItem

+(NSAttributedString *)legendForSeries1:(NSString *)series1
                                series2:(NSString *)series2
						colorForSeries1:(UIColor *)color1
						colorForSeries2:(UIColor *)color2
{
    NSAssert(series1 != nil, @"Pass a valid series 1 name");
    
    UIFont *font = [UIFont appLightFontWithSize:14.0f];
    UIColor *red = [UIColor appTertiaryRedColor];
    UIColor *yellow = [UIColor appTertiaryYellowColor];
    UIColor *darkGray = [UIColor darkGrayColor];
    
    NSAttributedString *indexOf = [[NSAttributedString alloc]initWithString:NSLocalizedStringWithDefaultValue(@"Index of", @"APCAppCore", APCBundle(), @"Index of", nil) attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : darkGray }];
    NSAttributedString *s1 = [[NSMutableAttributedString alloc]initWithString:series1 attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : color1 ?: red }];
    NSAttributedString *space = [[NSAttributedString alloc]initWithString:@" "];
    NSAttributedString *versus = [[NSAttributedString alloc]initWithString:NSLocalizedStringWithDefaultValue(@"vs", @"APCAppCore", APCBundle(), @"vs", nil) attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : darkGray }];
    
    NSMutableAttributedString *legend = [[NSMutableAttributedString alloc]initWithAttributedString:indexOf];
    [legend appendAttributedString:space];
    [legend appendAttributedString:s1];
    [legend appendAttributedString:space];
    [legend appendAttributedString:versus];
    [legend appendAttributedString:space];
    
    if (series2) {
        NSAttributedString *s2 = [[NSMutableAttributedString alloc]initWithString:series2 attributes:@{NSFontAttributeName : font, NSForegroundColorAttributeName : color2 ?: yellow}];
        
        [legend appendAttributedString:s2];
    }
    
    return legend;
    
}

@end
