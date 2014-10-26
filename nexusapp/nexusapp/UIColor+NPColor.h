//
//  UIColor+NPColor.h
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import <UIKit/UIKit.h>

@interface UIColor (NPColor)

+ (UIColor*)darkBlue;
+ (UIColor*)lightBlue;
+ (UIColor*)defaultBlue;
+ (UIColor*)darkGreen;

+ (UIColor*)npLightGrey;

+ (UIColor*)imageBackground:(NSString*)imageName onView:(UIView*)onView;

+ (UIColor*)colorFromHexString:(NSString *)hexString;
+ (UIColor*)textColorFromBackground:(UIColor*)backgroundColor;

@end
