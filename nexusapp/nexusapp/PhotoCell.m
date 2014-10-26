//
//  PhotoCell.m
//  nexuspad
//
//  Created by Ren Liu on 8/3/12.
//
//

#import "PhotoCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface PhotoCell()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *textLabel;
@end

@implementation PhotoCell

@synthesize imageView, textLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.imageView];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
        self.textLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.textLabel];
    }
    return self;
}

- (void)displayFromUrl:(NSString*)imageUrlStr textValue:(NSString*)textValue
{
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageProgressiveDownload];
    self.textLabel.text = textValue;
}

- (void)displayFromImage:(UIImage*)image textValue:(NSString*)textValue
{
    self.imageView.image = image;
    self.textLabel.text = textValue;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
	CGRect imageRect = CGRectInset(self.contentView.bounds, 5, 5);
	imageRect.size = CGSizeMake(50,50);
    self.imageView.frame = imageRect;
    
    CGRect labelRect = CGRectMake(65.0, 10.0, self.contentView.frame.size.width - 60, self.contentView.frame.size.height);
    self.textLabel.frame = labelRect;
    self.textLabel.numberOfLines = 0;
    [self.textLabel sizeToFit];
}
@end
