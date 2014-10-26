//
//  UIBasicItemButton.m
//  nexusapp
//
//  Created by Ren Liu on 2/25/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "UIBasicItemButton.h"
#import "UIColor+NPColor.h"
#import "UIFont+NPFont.h"

@implementation UIBasicItemButton

@synthesize item;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        [self.layer setBorderColor:[[UIColor clearColor] CGColor]];
        [self setTitleColor:[UIColor darkBlue] forState:UIControlStateNormal];
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.font = [UIFont valueFont];
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [self setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        [self setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    }

    return self;
}

@end
