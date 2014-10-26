//
//  UIFont+NPFont.m
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import "UIFont+NPFont.h"

@implementation UIFont (NPFont)

+ (UIFont*)labelFont
{
    return [UIFont boldSystemFontOfSize:12.0];
}

+ (UIFont*)valueFont
{
    return [UIFont boldSystemFontOfSize:16.0];
}

@end
