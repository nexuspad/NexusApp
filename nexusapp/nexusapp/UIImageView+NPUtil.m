//
//  UIImageView+NPUtil.m
//  nexusapp
//
//  Created by Ren Liu on 12/17/13.
//
//

#import "UIImageView+NPUtil.h"

@implementation UIImageView (NPUtil)

+ (UIImageView*)roundedCorner:(UIImageView*)imageView {
//    imageView.backgroundColor = [UIColor whiteColor];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 4;
    imageView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.25f].CGColor;
    imageView.layer.borderWidth = 1.0;

    return imageView;
}

@end
