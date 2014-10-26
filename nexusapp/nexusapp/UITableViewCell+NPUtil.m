//
//  UITableViewCell+EmptyListMessageCell.m
//  nexusapp
//
//  Created by Ren Liu on 9/17/13.
//
//

#import "UITableViewCell+NPUtil.h"

static NSString *LOAD_MORE_CELL_ID = @"LoadMoreCell";

@implementation UITableViewCell (NPUtil)

+ (UITableViewCell*)emptyListMessageCell:(NSString*)message {
    UITableViewCell *emptyMessageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                               reuseIdentifier:@"EmptyMessageCell"];
    
    emptyMessageCell.textLabel.text = message;
    emptyMessageCell.selectionStyle = UITableViewCellSelectionStyleNone;
    emptyMessageCell.textLabel.textColor = [UIColor darkGrayColor];
    emptyMessageCell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    emptyMessageCell.userInteractionEnabled = NO;

    return emptyMessageCell;
}


+ (UITableViewCell*)loadMoreCell {
    UITableViewCell *loadMoreCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LOAD_MORE_CELL_ID];
    loadMoreCell.textLabel.textAlignment = NSTextAlignmentCenter;
    loadMoreCell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    loadMoreCell.textLabel.text = NSLocalizedString(@"Scroll for more",);
    loadMoreCell.textLabel.textColor = [UIColor darkGrayColor];
    
    loadMoreCell.imageView.image = [UIImage imageNamed:@"caret-south16.png"];
    
    return loadMoreCell;
}

@end
