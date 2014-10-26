//
//  ShadowTextCell.m
//  nexusapp
//
//  Created by Ren Liu on 2/1/13.
//
//

#import "ShadowTextCell.h"

@implementation ShadowTextCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    self.textLabel.shadowColor = [UIColor whiteColor];
    self.textLabel.shadowOffset = CGSizeMake(0, 2);
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self applyLabelDropShadow:!selected];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self applyLabelDropShadow:!highlighted];
}

- (void)applyLabelDropShadow:(BOOL)applyDropShadow
{
    self.textLabel.shadowColor = applyDropShadow ? [UIColor whiteColor] : nil;
}

@end
