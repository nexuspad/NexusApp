//
//  UIColor+NPColor.m
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import "UIColor+NPColor.h"

@implementation UIColor (NPColor)

+ (UIColor*)darkBlue {
    return [UIColor colorWithRed:81.0/256 green:102.0/265 blue:145.0/256 alpha:1.0];
}

+ (UIColor*)defaultBlue {
    return [UIColor colorWithRed:51.0/256 green:102.0/265 blue:255.0/256 alpha:1.0];
}

+ (UIColor*)lightBlue {
    return [UIColor colorWithRed:153.0/256 green:208.0/265 blue:255.0/256 alpha:1.0];
}

+ (UIColor*)darkGreen {
    return [self colorFromHexString:@"006400"];
}

+ (UIColor*)npLightGrey {
    return [self colorFromHexString:@"cdcdcd"];
}

+ (UIColor*)imageBackground:(NSString*)imageName onView:(UIView *)onView {
    UIGraphicsBeginImageContext(onView.frame.size);
    [[UIImage imageNamed:imageName] drawInRect:onView.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [UIColor colorWithPatternImage:image];
}

+ (UIColor*)colorFromHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor*)textColorFromBackground:(UIColor*)backgroundColor {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int value = red*255*0.299 + green*255*0.587 + blue*255*0.114;
    
    if (value > 186) {
        return [UIColor blackColor];
    } else {
        return [UIColor whiteColor];
    }
}

@end
