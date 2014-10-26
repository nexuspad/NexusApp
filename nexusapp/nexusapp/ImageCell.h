//
//  ImageCell.h
//  nexuspad
//
//  Created by Ren Liu on 8/24/12.
//
//

#import <UIKit/UIKit.h>

@interface ImageCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

- (id)initWithStyleAndSize:(UITableViewCellStyle)style imageSize:(CGSize)imageSize reuseIdentifier:(NSString *)reuseIdentifier;

@end
