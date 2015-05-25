//
//  EntryListFolderViewController.m
//  nexusapp
//
//  Created by Ren Liu on 1/17/13.
//
//

#import "EntryListFolderViewController.h"
#import "ContactListController.h"
#import "BookmarkListController.h"
#import "PhotoListController.h"
#import "AlbumListController.h"
#import "DocListController.h"
#import "NPModule.h"
#import "EntryActionResult.h"
#import "FolderUpdaterController.h"
#import "FolderCreateController.h"
#import "FolderActionResult.h"

#define ADD_ACTION_SHEET                        1
#define UPDATE_ACTION_SHEET                     2
#define SHARING_ACTION_SHEET                    3

@interface EntryListFolderViewController ()
@property (nonatomic, strong) NPFolder *selectedFolderToUpdate;
@property (nonatomic, strong) NPFolder *selectedFolderToDelete;
@property (nonatomic, strong) NPFolder *selectedFolderToUnshare;
@end


@implementation EntryListFolderViewController

@synthesize doAlert = _doAlert;


// Will be called from subclasses
// Handles common activities such as deleting a folder
- (void)updateServiceResult:(id)serviceResult {
    [super updateServiceResult:serviceResult];
    
    if ([serviceResult isKindOfClass:[FolderActionResult class]]) {
        FolderActionResult *actionResponse = (FolderActionResult*)serviceResult;
        
        // Handles deletion of the current folder, or a folder in sub folder list
        if ([actionResponse.name isEqualToString:ACTION_DELETE_FOLDER] || [actionResponse.name isEqualToString:ACTION_UNSHARE_FOLDER]) {
            if (actionResponse.success) {
                if (actionResponse.folder.folderId == self.currentFolder.folderId) {
                    [NotificationUtil sendFolderDeletedNotification:actionResponse.folder];
                    // The on screen folder is deleted, move the screen back to the parent folder
                    [self.navigationController popViewControllerAnimated:YES];

                } else {
                    [self.currentEntryList.folder deleteSubFolder:actionResponse.folder];
                    [self refreshListTable];
                }
            }
        } else if ([actionResponse.name isEqualToString:ACTION_MOVE_FOLDER]) {
            NPFolder *returnedFolder = [actionResponse.folder copy];
            [NotificationUtil sendFolderMovedNotification:returnedFolder];
        }
        
    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        if (actionResponse.success) {
            //
            // Use the notification route so the same logic only appears in handleEntryDeletedNotification
            //
            //
            if ([actionResponse.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                [NotificationUtil sendEntryDeletedNotification:[actionResponse.entries objectAtIndex:0]];
            } else if ([actionResponse.name isEqualToString:ACTION_DELETE_ENTRY]) {
                [NotificationUtil sendEntryDeletedNotification:actionResponse.entry];
            }
        }
    }
}


// Handles moving folder delegation call
- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    if (forAction == ForMoving) {
        DLog(@"In didSelectFolder for moving selected folder id %i", selectedFolder.folderId);
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];
        FolderService *folderService = [[FolderService alloc] init];
        folderService.moduleId = self.selectedFolderToUpdate.moduleId;
        folderService.serviceDelegate = self;
        [folderService moveFolder:self.selectedFolderToUpdate parentFolder:selectedFolder];
    }
    
    [super didSelectFolder:selectedFolder forAction:forAction];
}


// Reload the table and scroll to an item. It can either be a Folder or a NPEntry.
- (void)refreshListTableAndScrollToItem:(id)item {
    if ([item isKindOfClass:[NPFolder class]]) {
        NPFolder *theFolder = (NPFolder*)item;
        int row = 0;
        for (NPFolder *f in self.currentEntryList.folder.subFolders) {
            if (theFolder.folderId == f.folderId) {
                break;
            }
            row++;
        }
        
        [self.entryListTable reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.entryListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
    } else if ([item isKindOfClass:[NPEntry class]]) {
        NPEntry *theEntry = (NPEntry*)item;
        int row = 0;
        for (NPEntry *e in self.currentEntryList.entries) {
            if ([theEntry.entryId isEqualToString:e.entryId]) {
                break;
            }
            row++;
        }
        
        [self.entryListTable reloadData];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];
        [self.entryListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}


#pragma mark - handles different types of folder operation notifications

/*
 * Handle adding
 */
- (void)handleFolderAddedNotification:(NSNotification*)notification {
    DLog(@"EntryListFolderViewController for folder %@ received folder added notification...", [self.currentFolder description]);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *addedFolder = (NPFolder*)notification.object;
        // Make sure it's listed here.
        if (addedFolder.moduleId == self.currentFolder.moduleId && addedFolder.parentId == self.currentFolder.folderId) {
            DLog(@"Added folder here: %@", [addedFolder description]);
            [self.currentEntryList.folder addSubFolder:addedFolder];
            [self refreshListTableAndScrollToItem:addedFolder];
        }
    }
}

/*
 * Handle updating
 */
- (void)handleFolderUpdatedNotification:(NSNotification*)notification {
    DLog(@"EntryListFolderViewController for folder %@ received folder updated notification...", [self.currentFolder description]);

    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *updatedFolder = (NPFolder*)notification.object;

        if (updatedFolder.moduleId == self.currentFolder.moduleId) {
            if (updatedFolder.folderId == self.currentFolder.folderId) {
                // Name updated
                DLog(@"Current folder updated: %@", [updatedFolder description]);
                self.currentFolder.folderName = [updatedFolder.folderName copy];
                self.navigationItem.title = [self.currentFolder displayName];
                
            } else {
                for (NPFolder *f in self.currentEntryList.folder.subFolders) {
                    if (f.folderId == updatedFolder.folderId) {
                        f.folderName = [updatedFolder.folderName copy];
                        [self refreshListTableAndScrollToItem:updatedFolder];
                        break;
                    }
                }
            }
        }
    }
}

/*
 * Handle moving
 */
- (void)handleFolderMovedNotification:(NSNotification*)notification {
    DLog(@"EntryListFolderViewController for folder %@ received folder moved notification...", [self.currentFolder description]);

    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *updatedFolder = (NPFolder*)notification.object;
        
        if (updatedFolder.moduleId == self.currentFolder.moduleId) {
            if (updatedFolder.parentId == self.currentFolder.folderId) {
                // Make sure folder is listed here
                DLog(@"Folder moved in here: %@", [updatedFolder description]);
                [self.currentEntryList.folder addSubFolder:updatedFolder];
                [self refreshListTableAndScrollToItem:updatedFolder];
                
            } else {
                // Make sure folder is NOT listed here
                for (NPFolder *f in self.currentEntryList.folder.subFolders) {
                    if (f.folderId == updatedFolder.folderId) {
                        DLog(@"Folder removed from here: %@", [updatedFolder description]);
                        [self.currentEntryList.folder deleteSubFolder:updatedFolder];
                        [self refreshListTable];
                        break;
                    }
                }
            }
        }
    }
}

/*
 * This is to handle refreshing the "previous screen" when the folder of THIS screen is deleted.
 */
- (void)handleFolderDeletedNotification:(NSNotification*)notification {
    DLog(@"EntryListFolderViewController for folder %@ received folder deleted notification...", [self.currentFolder description]);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        
        NPFolder *deletedFolder = (NPFolder*)notification.object;
        
        if (deletedFolder.moduleId == self.currentFolder.moduleId) {
            // Find out if the deleted folder is one of the current screen's sub-folders, and remove it from the sub folder list.
            for (NPFolder *f in self.currentEntryList.folder.subFolders) {
                if ([f isEqual:deletedFolder]) {
                    DLog(@"Folder deleted here: %@", [deletedFolder description]);
                    [self.currentEntryList.folder deleteSubFolder:deletedFolder];
                    [self refreshListTable];
                    break;
                }
            }
        }
    }
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Implemented in subclasses
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (![self isSearchTableView:tableView] && [self foldersShown]) {
        if (section == 0) {
            return NSLocalizedString(@"FOLDERS",);

        } else if (section == 1) {
            if (self.currentFolder.moduleId == BOOKMARK_MODULE) {
                return NSLocalizedString(@"BOOKMARKS",);
            } else if (self.currentFolder.moduleId == DOC_MODULE) {
                return NSLocalizedString(@"DOCS",);
            }
            return @"";
        }
    }
    return nil;
}

// Remove the bottom line
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isSearchTableView:tableView]) {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            return UITableViewCellEditingStyleDelete;
        } else {
            return UITableViewCellEditingStyleNone;
        }

    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[SWTableViewCell class]]) {
            //return UITableViewCellEditingStyleDelete;
            return UITableViewCellEditingStyleNone;             // Set to none because we are using SWTableViewCell
            
        } else {
            if ([self.currentFolder.accessInfo iCanWrite]) {
                return UITableViewCellEditingStyleDelete;
            } else {
                return UITableViewCellEditingStyleNone;
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self isSearchTableView:tableView]) {
        // Delete the entry at row
        NPEntry *entryToDelete = [self.currentEntryList.entries objectAtIndex:indexPath.row];
        
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];

        [self.entryService deleteEntry:entryToDelete];
        [self.searchResultList deleteFromList:entryToDelete];
        [self.listSearchDisplayController.searchResultsTableView reloadData];

    } else {
        if ([self foldersShown] && indexPath.section == 0) {
            if ([self.currentFolder.accessInfo iAmOwner]) {
                self.selectedFolderToDelete = [[self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row] copy];
                [self deleteFolderConfirm];
                
            } else {
                self.selectedFolderToUnshare = [[self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row] copy];
                [self unshareFolderButtonTapped:nil];
            }
            
        } else {
            // Delete the entry at row
            NPEntry *entryToDelete = [self.currentEntryList.entries objectAtIndex:indexPath.row];
            [self.entryService deleteEntry:entryToDelete];
            [self.currentEntryList deleteFromList:entryToDelete];

            NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
            [tableView beginUpdates];
            [tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
            [tableView endUpdates];
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self initPullRefresh:self.entryListTable];
    
    CGRect rect = self.entryListTable.frame;
    rect.origin.x = 12.0;
    rect.origin.y = 44.0;
    rect.size.height = 44.0;
    
    if (self.emptyListLabel == nil) {
        self.emptyListLabel = [[UILabel alloc] init];
        if (self.currentFolder.folderId == ROOT_FOLDER) {
            if (self.currentFolder.moduleId == DOC_MODULE) {
                self.emptyListLabel.text = NSLocalizedString(@"No doc has been added.",);
            } else if (self.currentFolder.moduleId == PHOTO_MODULE) {
                self.emptyListLabel.text = NSLocalizedString(@"No album has been added.",);
            } else if (self.currentFolder.moduleId == BOOKMARK_MODULE) {
                self.emptyListLabel.text = NSLocalizedString(@"No bookmark has been added.",);
            }

        } else {
            self.emptyListLabel.text = NSLocalizedString(@"The folder is empty.",);
        }
        
        self.emptyListLabel.textColor = [UIColor lightGrayColor];
    }
    self.emptyListLabel.frame = rect;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderAddedNotification:) name:N_FOLDER_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderUpdatedNotification:) name:N_FOLDER_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderMovedNotification:) name:N_FOLDER_MOVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderDeletedNotification:) name:N_FOLDER_DELETED object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_MOVED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_DELETED object:nil];
}

- (BOOL)foldersShown
{
    if ([self.currentEntryList.folder.subFolders count] > 0) return YES;
    return NO;
}

- (BOOL)isLoadMoreRow:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath
{
    if ([self foldersShown] && indexPath.section == 0) {
        return NO;
    }
    
    if (indexPath.row == [self.currentEntryList.entries count]) {
        return YES;
    }

    return NO;
}

- (BOOL)hasMoreToLoad:(UITableView*)tableView
{
    if ([self isSearchTableView:tableView]) {
        return [self.searchResultList hasMore];
    }
    
    return [self.currentEntryList hasMore];
}

- (void)loadMoreEntries
{
    if (self.currentEntryList.countPerPage == 0) return;
    
    // Load more entries using the next page id
    if ([self.currentEntryList hasMore]) {
        NSInteger nextPage = [self.currentEntryList currentPageId] + 1;
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];
        [self.entryListService getEntries:self.currentEntryList.templateId inFolder:self.currentFolder pageId:nextPage countPerPage:self.currentEntryList.countPerPage];
    }
}

- (IBAction)addButtonTapped:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    actionSheet.tag = 1;

    NSString *buttonName = nil;

    if (self.currentFolder.moduleId == 3) {
        buttonName = NSLocalizedString(@"Add new bookmark",);
        
    } else if (self.currentFolder.moduleId == 4) {
        buttonName = NSLocalizedString(@"Add new note",);
        
    } else if (self.currentFolder.moduleId == 6) {
        if (self.currentEntryList.templateId == photo) {
            buttonName = NSLocalizedString(@"Add new photo",);
        } else if (self.currentEntryList.templateId == album) {
            buttonName = NSLocalizedString(@"Add new album",);
        }
    }
    
    [actionSheet addButtonWithTitle:buttonName];

    if ([self.currentFolder.accessInfo iAmOwner]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add new folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 2;

    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 1;
    }

    
    [actionSheet showInView:self.view];
}

- (IBAction)updateButtonTapped:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    if ([self.currentFolder.accessInfo iAmOwner]) {
        actionSheet.tag = UPDATE_ACTION_SHEET;
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Move folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Share folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 4;
        actionSheet.destructiveButtonIndex = 3;
        
    } else {                                                    // This block of code is unused.
        actionSheet.tag = SHARING_ACTION_SHEET;
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Stop sharing to me",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 1;
        actionSheet.destructiveButtonIndex = 0;
    }
    
    [actionSheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (sender.tag == ADD_ACTION_SHEET) {                               // folder view add actions action sheet
        if (index == 0) {
            [self createNewEntry];
        } else if (index == 1 && index != sender.cancelButtonIndex) {   // Adding to shared folder might have cancel as index 1, we need to check
            [self openFolderCreateView];
        }
        
    } else if (sender.tag == UPDATE_ACTION_SHEET) {                     // folder view update actions action sheet
        
        // This must be put in the first
        if (index == sender.cancelButtonIndex) {
            if (self.selectedFolderToUpdate != nil) {
                [self resetCell:self.selectedFolderToUpdate];
            }
            self.selectedFolderToUpdate = nil;
            self.selectedFolderToDelete = nil;
            return;
        }
        
        if (index == 0) {
            if (self.selectedFolderToUpdate == nil) {
                self.selectedFolderToUpdate = self.currentFolder;
            }
            [self openFolderUpdateView:self.selectedFolderToUpdate];

        } else if (index == 1) {
            if (self.selectedFolderToUpdate == nil) {
                self.selectedFolderToUpdate = self.currentFolder;
            }

            UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
            FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
            
            if (folderViewController) {
                folderViewController.purpose = ForMoving;
                folderViewController.foldersCannotMoveInto = [NSArray arrayWithObjects:[NSNumber numberWithInt:self.selectedFolderToUpdate.folderId],
                                                              [NSNumber numberWithInt:self.selectedFolderToUpdate.parentId], nil];
                
                [folderViewController showFolderTree:self.selectedFolderToUpdate];
                
                folderViewController.folderViewDelegate = self;
                [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
            }

        } else if (index == 2) {
            if (self.selectedFolderToUpdate == nil) {
                self.selectedFolderToUpdate = self.currentFolder;
            }
            [self openFolderUpdateViewForSharing:self.selectedFolderToUpdate];

        } else if (index == 3) {                                // This is N/A when the action sheet is brought up by more button
            self.selectedFolderToDelete = self.currentFolder;
            [self deleteFolderConfirm];
            
        }

    } else if (sender.tag == SHARING_ACTION_SHEET) {
        if (index == 0) {
            self.selectedFolderToUnshare = self.currentFolder;
            [self unshareFolderButtonTapped:nil];
            
        } else if (index == sender.cancelButtonIndex) {
            self.selectedFolderToUnshare = nil;
        }
    }
}


// Handle scroll delegate - Notice we need to check for both directions: pull refresh and scroll load more.
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //---------------------------
    //         |              |
    //  contentOffset.y       |
    //         |              |
    //-------------------    contentSize.height
    //         |              |
    //  frame.size.height     |
    //         |              |
    //---------------------------

    int currentOffset = scrollView.contentOffset.y;
    
    if (currentOffset <= [self pullRefreshOffsetThreshold]) {
        // Handles pull refresh
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];

    } else {
        if (currentOffset > 0) {
            NSInteger threadholdOffset = scrollView.contentSize.height - scrollView.frame.size.height;

            if (currentOffset >= threadholdOffset - 44) {
                if (self.listSearchDisplayController != nil && [self.listSearchDisplayController isActive]) {
                    [self loadMoreSearchResultEntries];
                    NSLog(@"Load next page for search result.");
                    
                } else {
                    if (self.currentEntryList != nil && [self.currentEntryList hasMore]) {
                        [self loadMoreEntries];
                        NSLog(@"Load next page");
                    }
                }
            }
        }
    }
}


// Open the folder picker
- (void)openFolderCreateView
{
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderCreateController* folderCreateViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderCreateView"];
    
    folderCreateViewController.parentFolder = self.currentFolder;
    NPFolder *blankFolder = [[NPFolder alloc] initWithModuleAndFolderId:self.currentFolder.moduleId folderId:-1 accessInfo:self.currentFolder.accessInfo];
    blankFolder.parentId = self.currentFolder.folderId;
    [folderCreateViewController setTheNewFolder:blankFolder];
    
    self.navigationController.toolbarHidden = YES;
    [self.navigationController pushViewController:folderCreateViewController animated:YES];
}

- (void)openFolderUpdateView:(NPFolder*)folder
{
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderUpdaterController* folderUpdateViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderUpdateView"];
    folderUpdateViewController.currentFolder = [folder copy];
    folderUpdateViewController.startAtSharing = NO;
    [self.navigationController pushViewController:folderUpdateViewController animated:YES];
}

- (void)openFolderUpdateViewForSharing:(NPFolder*)folder
{
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderUpdaterController* folderUpdateViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderUpdateView"];
    folderUpdateViewController.currentFolder = [folder copy];
    folderUpdateViewController.startAtSharing = YES;
    [self.navigationController pushViewController:folderUpdateViewController animated:YES];
}

- (void)deleteFolderConfirm {
    NSString *message = NSLocalizedString(@"Are you sure you want to delete this folder and all its content?",);
    
    message = [message stringByReplacingOccurrencesOfString:@"this folder" withString:[self.selectedFolderToDelete displayName]];

    _doAlert = [[DoAlertView alloc] init];
    _doAlert.nAnimationType = DoTransitionStylePop;
    _doAlert.dRound = 5.0;
    
    _doAlert.bDestructive = YES;
    [_doAlert doYesNo:message
                  yes:^(DoAlertView *alertView) {
                      FolderService *folderService = [[FolderService alloc] init];
                      folderService.moduleId = self.selectedFolderToDelete.moduleId;
                      folderService.serviceDelegate = self;
                      
                      [ViewDisplayHelper displayWaiting:self.view messageText:nil];
                      
                      [folderService deleteFolder:self.selectedFolderToDelete];

                  } no:^(DoAlertView *alertView) {
                      [self resetCell:self.selectedFolderToDelete];
                      self.selectedFolderToDelete = nil;
                  }];
    
    _doAlert = nil;
}


- (void)resetCell:(NPFolder*)folder {
    // Find out the cell location of the selected folder and remove the delete button.
    if (folder != nil) {
        int row = 0;
        for (NPFolder *f in self.currentEntryList.folder.subFolders) {
            if (f.folderId == folder.folderId) {
                break;
            }
            row++;
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.entryListTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }
}


- (IBAction)unshareFolderButtonTapped:(id)sender {
    NSString *message = NSLocalizedString(@"Are you sure you want to stop accessing this shared folder?",);
    
    if (self.selectedFolderToUnshare == nil) {
        self.selectedFolderToUnshare = self.currentFolder;
    }

    message = [message stringByReplacingOccurrencesOfString:@"this shared folder" withString:[self.selectedFolderToUnshare displayName]];
    
    _doAlert = [[DoAlertView alloc] init];
    _doAlert.nAnimationType = DoTransitionStylePop;
    _doAlert.dRound = 5.0;
    
    _doAlert.bDestructive = YES;
    [_doAlert doYesNo:message
                  yes:^(DoAlertView *alertView) {
                      FolderService *folderService = [[FolderService alloc] init];
                      folderService.moduleId = self.selectedFolderToUnshare.moduleId;
                      folderService.serviceDelegate = self;
                      
                      [ViewDisplayHelper displayWaiting:self.view messageText:nil];
                      
                      [folderService stopSharingFolder:self.selectedFolderToUnshare toMe:[UserManager instance].currentUser];
                      
                  } no:^(DoAlertView *alertView) {
                      if (self.currentFolder.folderId != self.selectedFolderToUnshare.folderId) {
                          // Find out the cell location of the selected folder and remove the delete button.
                          int row = 0;
                          for (NPFolder *f in self.currentEntryList.folder.subFolders) {
                              if (f.folderId == self.selectedFolderToUnshare.folderId) {
                                  break;
                              }
                              row++;
                          }
                          
                          // There will not be a row found if unsharing the current folder.
                          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                          [self.entryListTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];                          
                      }
                      
                      self.selectedFolderToUnshare = nil;

                  }];
    
    _doAlert = nil;
}


#pragma handles swipe folder cell actions

- (void)configureFolderCell:(UITableViewCell*)cell forFolder:(NPFolder*)folder {
    if (![cell isKindOfClass:[SWTableViewCell class]]) {
        return;
    }
    
    if (folder.folderId == ROOT_FOLDER) {
        return;
    }

    SWTableViewCell *folderCell = (SWTableViewCell*)cell;
    
    folderCell.delegate = self;
    
    folderCell.textLabel.text = folder.folderName;
    folderCell.imageView.image = [UIImage imageNamed:@"icon-folder.png"];
    
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    if ([folder.accessInfo iAmOwner]) {
        [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                    title:@"More"];
        [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                    title:@"Trash"];
    } else {
        [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                    title:@"Un-Share"];
    }
    
    folderCell.leftUtilityButtons = nil;
    folderCell.rightUtilityButtons = rightUtilityButtons;
}

- (void)configureEntryCell:(UITableViewCell*)cell {
    if (![cell isKindOfClass:[SWTableViewCell class]]) {
        return;
    }
    
    SWTableViewCell *entryCell = (SWTableViewCell*)cell;
    
    entryCell.delegate = self;
        
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:@"Trash"];
    
    entryCell.leftUtilityButtons = nil;
    entryCell.rightUtilityButtons = rightUtilityButtons;
}


// Delegate to handle the utility button
- (void)swipeableTableViewCell:(SWTableViewCell*)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSString *cellId = cell.reuseIdentifier;

    NSIndexPath *indexPath = [self.entryListTable indexPathForCell:cell];
    
    if ([cellId isEqualToString:@"FolderCell"]) {
        NPFolder *folder = [self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row];
        
        switch (index) {
            case 0:             // More
                self.selectedFolderToUpdate = folder;
                [self moreButtonTapped:cell];
                break;
                
            case 1:
                if ([folder.accessInfo iAmOwner]) {
                    self.selectedFolderToDelete = folder;
                    [self deleteFolderConfirm];
                } else {
                    self.selectedFolderToUnshare = folder;
                    [self unshareFolderButtonTapped:nil];
                }
                break;
                
            default:
                break;
        }
   
    } else if ([cellId isEqualToString:@"EntryCell"]) {
        NPEntry *entryToDelete = [self.currentEntryList.entries objectAtIndex:indexPath.row];
        
        switch (index) {
            case 0:
                [self.entryService deleteEntry:entryToDelete];
                break;
            default:
                break;
        }

    }
}


- (void)moreButtonTapped:(SWTableViewCell*)cell {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    if ([self.currentFolder.accessInfo iAmOwner]) {
        actionSheet.tag = UPDATE_ACTION_SHEET;
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Move folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Share folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 3;
    }
    
    [actionSheet showInView:self.view];
}
@end
