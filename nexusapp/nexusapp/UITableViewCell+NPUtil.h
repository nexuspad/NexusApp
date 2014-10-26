//
//  UITableViewCell+EmptyListMessageCell.h
//  nexusapp
//
//  Created by Ren Liu on 9/17/13.
//
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (NPUtil)

+ (UITableViewCell*)emptyListMessageCell:(NSString*)message;
+ (UITableViewCell*)loadMoreCell;

@end
