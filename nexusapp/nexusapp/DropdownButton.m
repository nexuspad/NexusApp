//
//  DropdownButton.m
//  nexusapp
//
//  Created by Ren Liu on 12/2/13.
//
//

#import "DropdownButton.h"

static float SPACE = 6.0;

@interface DropdownButton ()
@property (nonatomic, strong) UILabel *customTitleLabel;
@end

@implementation DropdownButton

// Initialize a button with image on the right. The image should be small than 20.0 in width.
- (id)init:(id)target action:(SEL)action line1:(NSString*)line1 line2:(NSString*)line2 rightImage:(UIImage*)rightImage {
    if (line2.length > 0) {
        self.customTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160.0, 40.0)];
        self.customTitleLabel.numberOfLines = 2;
        self.customTitleLabel.text = [NSString stringWithFormat:@"%@\n%@", line1, line2];

    } else {
        self.customTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 160.0, 20.0)];
        self.customTitleLabel.numberOfLines = 1;
        self.customTitleLabel.text = [NSString stringWithFormat:@"%@", line1];
    }
    
    self.customTitleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    self.customTitleLabel.textColor = [UIColor whiteColor];
    self.customTitleLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.35];
    self.customTitleLabel.shadowOffset = CGSizeMake(0, -1.0);
    self.customTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.customTitleLabel.backgroundColor = [UIColor clearColor];
    
    [self.customTitleLabel sizeToFit];
    
    CGRect rect = self.customTitleLabel.frame;
    
    if (rightImage != nil) {
        rect.size.width += 20 + SPACE;
    }
    
    self = [super initWithFrame:rect];
    
    [self addSubview:self.customTitleLabel];
    
    self.showsTouchWhenHighlighted = NO;

    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    if (rightImage != nil) {
        [self setImage:rightImage forState:UIControlStateNormal];
    }

    return self;
}

- (void)layoutSubviews
{
    // Allow default layout, then adjust image and label positions
    [super layoutSubviews];
    
    if (self.imageView != nil) {
        UIImageView *imageView = [self imageView];
        
        CGRect imageFrame = imageView.frame;
        CGRect labelFrame = self.customTitleLabel.frame;
        
        imageFrame.origin.x = labelFrame.origin.x + CGRectGetWidth(labelFrame) + SPACE;
        imageView.frame = imageFrame;
    }
    
}

@end
