//
//  ColorTile.m
//  nexuspad
//
//  Created by Ren Liu on 9/14/12.
//
//

#import "ColorTile.h"
#import "UIColor+NPColor.h"

@implementation ColorTile

@synthesize colorHexString;

- (id)initWithColor:(CGRect)frame hexColor:(NSString*)hexColor
{
    self = [super initWithFrame:frame];
    
    self.colorHexString = [hexColor copy];
    self.backgroundColor = [UIColor colorFromHexString:hexColor];
    
    return self;
}

@end
