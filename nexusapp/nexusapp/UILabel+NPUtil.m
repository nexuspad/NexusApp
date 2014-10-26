//
//  UILabel+NPUtil.m
//  nexuspad
//
//  Created by Ren Liu on 10/7/12.
//
//

#import "UILabel+NPUtil.h"

@implementation UILabel (NPUtil)

+ (UILabel*)twoLineTitleLabel:(NSString*)line1 line2:(NSString*)line2
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160.0, 40.0)];
    titleLabel.numberOfLines = 2;
    titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    titleLabel.text = [NSString stringWithFormat:@"%@\n%@", line1, line2];
    
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.35];
    titleLabel.shadowOffset = CGSizeMake(0, -1.0);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    
    [titleLabel sizeToFit];
    
    return titleLabel;
}

@end
