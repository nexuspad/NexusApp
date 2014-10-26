//
//  FolderListCell.h
//  nexusapp
//
//  Created by Ren Liu on 10/15/13.
//
//

#import <UIKit/UIKit.h>
#import "NPFolder.h"
#import "SWTableViewCell.h"

@interface FolderTreeItemCell : SWTableViewCell

@property (nonatomic, strong) NPFolder *folder;

@property BOOL lastItemInTree;

- (void)setSubfolderButton:(id)target action:(SEL)action;

- (void)setCalendarViewButton:(id)target action:(SEL)action;

@end
