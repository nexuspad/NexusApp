//
//  ImageCell.m
//  nexuspad
//
//  Created by Ren Liu on 8/24/12.
//
//

#import <QuartzCore/QuartzCore.h>
#import "ImageCell.h"
#import "UIColor+NPColor.h"
#import "UIImageView+NPUtil.h"

@interface ImageCell ()
@property CGSize imageSize;
@end

@implementation ImageCell
@synthesize titleLabel, imageSize = _imageSize;

- (id)initWithStyleAndSize:(UITableViewCellStyle)style imageSize:(CGSize)imageSize reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _imageSize = imageSize;
    }
    
    [UIImageView roundedCorner:self.imageView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    [self addSubview:self.titleLabel];

    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    float yOffset = (self.frame.size.height - self.imageSize.height)/2;
    CGRect rect = CGRectMake(4, yOffset, self.imageSize.width, self.imageSize.height);

    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.frame = rect;
    
    CALayer *sublayer = [CALayer layer];
    sublayer.backgroundColor = [UIColor redColor].CGColor;
    sublayer.frame = CGRectMake(0, -1, self.imageView.bounds.size.width, 1);
    [self.imageView.layer addSublayer:sublayer];
    
    CGRect titleRect = CGRectMake(self.imageSize.width + 10.0, 0.0, self.frame.size.width - self.imageSize.width - 30, self.frame.size.height);
    self.titleLabel.frame = titleRect;
}

@end
