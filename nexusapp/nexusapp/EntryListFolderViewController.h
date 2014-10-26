//
//  EntryListFolderViewController.h
//  nexusapp
//
//  Created by Ren Liu on 1/17/13.
//
//

#import "BaseEntryListViewController.h"
#import "NPBookmark.h"

@interface EntryListFolderViewController : BaseEntryListViewController
                                            <UIActionSheetDelegate,
                                            UIScrollViewDelegate,
                                            SWTableViewCellDelegate>

@property (nonatomic, strong) UILabel *emptyListLabel;

- (BOOL)foldersShown;

- (BOOL)isLoadMoreRow:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath;
- (BOOL)hasMoreToLoad:(UITableView*)tableView;
- (void)loadMoreEntries;

- (void)configureFolderCell:(UITableViewCell*)cell forFolder:(NPFolder*)folder;

- (void)handleFolderUpdatedNotification:(NSNotification*)notification;
- (void)handleFolderDeletedNotification:(NSNotification*)notification;

@end
