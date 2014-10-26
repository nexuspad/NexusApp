//
//  BookmarkListController.m
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkListController.h"
#import "BookmarkViewController.h"
#import "BookmarkEditorViewController.h"
#import "UITableViewCell+NPUtil.h"
#import "NPEntry+Attribute.h"

@interface BookmarkListController ()
@property (nonatomic, strong) BookmarkListController *childFolderBookmarkListController;
@end

@implementation BookmarkListController

- (void)retrieveEntryList {
    [super retrieveEntryList];

    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:[NPModule defaultTemplate:self.currentFolder.moduleId]];
    }
    
    self.navigationItem.title = [self.currentFolder displayName];
    
    [self.entryListService getEntries:self.currentEntryList.templateId inFolder:self.currentFolder pageId:1 countPerPage:self.currentEntryList.countPerPage];
}


// Basic handling of Service Result. Only handles EntryList result.
- (void)updateServiceResult:(id)serviceResult {
    [super updateServiceResult:serviceResult];
    
    /*
     * 1. Load the regular returned entry list into table. Load more is handled in EntryListFolderViewController
     * 2. Handle "load more" for search result.
     */
    
    if ([serviceResult isKindOfClass:[EntryList class]]) {
        EntryList *returnedList = (EntryList*)serviceResult;
        
        if ([returnedList isFolderListResult]) {                                           // Regular listing result
            
            if ([returnedList isNotEmpty]) {
                [self.emptyListLabel removeFromSuperview];

                if (returnedList.pageId <= 1) {
                    self.currentEntryList = [returnedList copy];
                    DLog(@"Initial query result %@", [self.currentEntryList description]);
                    
                    [self.entryListTable reloadData];
                    
                    // Tug the search bar under only for non-root folder listing.
                    if (self.currentEntryList.folder.folderId != 0) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentEntryList.countPerPage*(returnedList.pageId-1) inSection:0];
                        
                        if (indexPath.row < [self.currentEntryList.entries count]) {
                            [self.entryListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                        }
                    }
                    
                } else {
                    [self.currentEntryList.entries addObjectsFromArray:returnedList.entries];
                    DLog(@"More query, current list: %@", [self.currentEntryList description]);
                    
                    [self.entryListTable reloadData];
                }

            } else {
                [self.entryListTable addSubview:self.emptyListLabel];

                self.currentEntryList = [returnedList copy];
                [self.entryListTable reloadData];
            }
            
        } else {                                                                        // Search result
            
            if (self.searchResultList == nil) {
                self.searchResultList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:bookmark];
            }
            
            if (returnedList.pageId > 1) {
                [self.searchResultList.entries addObjectsFromArray:returnedList.entries];
                DLog(@"More search query %@", [returnedList description]);
                
            } else {
                self.searchResultList = [returnedList copy];
                DLog(@"Initial search query %@", [self.searchResultList description]);
            }
            
            [self unDimSearchTable];
            [self.listSearchDisplayController.searchResultsTableView reloadData];
        }
    }
}

// This is called in EntryListFolderViewController (ADD_ACTION_SHEET)
- (void)createNewEntry {
    [self performSegueWithIdentifier:@"NewBookmark" sender:self];
}

#pragma mark - navigation handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NPBookmark*)bookmark {
    if ([segue.identifier isEqualToString:@"OpenBookmark"]) {
        BookmarkViewController *viewController = (BookmarkViewController*)segue.destinationViewController;
        bookmark.folder = [self.currentFolder copy];
        viewController.bookmark = bookmark;

    } else if ([segue.identifier isEqualToString:@"NewBookmark"]) {
        BookmarkEditorViewController* editorController = (BookmarkEditorViewController*)[segue destinationViewController];
        NPBookmark *newBookmark = [[NPBookmark alloc] init];
        newBookmark.folder = [self.currentFolder copy];
        newBookmark.accessInfo = [self.currentFolder.accessInfo copy];
        editorController.bookmark = newBookmark;
    }
}

// Display items after a folder selected
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    if (self.childFolderBookmarkListController == nil) {
        self.childFolderBookmarkListController = [self.storyboard instantiateViewControllerWithIdentifier:@"BookmarkList"];
    }
    
    self.childFolderBookmarkListController.currentFolder = [selectedFolder copy];
    [self.navigationController pushViewController:self.childFolderBookmarkListController animated:YES];
}


#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    [self.entryListService searchEntries:self.searchBar.text templateId:bookmark inFolder:self.currentFolder pageId:1 countPerPage:0];
}

#pragma mark - tableview delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isSearchTableView:tableView]) {
        return 1;
        
    } else {
        if (!self.entryListIsLoading && [self.currentEntryList isEmpty]) {
            return 1;
        }

        int sections = 0;
        if ([self.currentEntryList.folder.subFolders count] > 0) {
            sections++;
        }
        if ([self.currentEntryList.entries count] > 0) {
            sections++;
        }

        return sections;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isSearchTableView:tableView]) {
        NSInteger count = [self.searchResultList.entries count];
        if ([self hasMoreSearchResultToLoad:tableView]) {
            return count + 1;
        }
        return count;
        
    } else {
        
        if ([self.currentEntryList isEmpty]) {
            return 0;
        }
        
        // The number of folders
        if ([self foldersShown] && section == 0) {
            return [self.currentEntryList.folder.subFolders count];
        }
        
        // The number of entries
        NSInteger count = [self.currentEntryList.entries count];
        if ([self hasMoreToLoad:tableView]) {
            return count + 1;
        }
        
        return count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Search result cell
    if ([self isSearchTableView:tableView]) {
        if ([NSString isBlank:self.searchResultList.keyword]) {
            return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DummyCell"];
        }
    }
    
    NSString *CellIdentifier = @"EntryCell";
    
    if (![self isSearchTableView:tableView] && [self foldersShown] && indexPath.section == 0) {
        CellIdentifier = @"FolderCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        if ([CellIdentifier isEqualToString:@"FolderCell"]) {
            cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FolderCell"];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
    }
    
    // Folder or entry row
    NPEntry *entry = nil;
    
    if ([self isSearchTableView:tableView]) {
        entry = [self.searchResultList.entries objectAtIndex:indexPath.row];
        
        // Load more row
        if ([self isLoadMoreRowInSearchTable:tableView indexPath:indexPath]) {
            return [UITableViewCell loadMoreCell];
        }
        
        if ([entry isPinned]) {
            cell.imageView.image = [UIImage imageNamed:@"is-favorite.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"icon-bookmark.png"];
        }
        
        if (entry.title == nil) {
            entry.title = entry.webAddress;
        }            
        cell.textLabel.text = entry.title;
        cell.textLabel.backgroundColor = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor whiteColor];

    } else {
        
        if ([self foldersShown] && indexPath.section == 0) {
            NPFolder *folder = [self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row];
            [self configureFolderCell:cell forFolder:folder];

        } else {
            
            // Load more row
            if ([self isLoadMoreRow:tableView indexPath:indexPath]) {
                return [UITableViewCell loadMoreCell];
            }
            
            entry = [self.currentEntryList.entries objectAtIndex:indexPath.row];

            if ([entry isPinned]) {
                cell.imageView.image = [UIImage imageNamed:@"is-favorite.png"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"icon-bookmark.png"];
            }

            if (entry.title.length == 0) {
                entry.title = entry.webAddress;
            }
                
            cell.textLabel.text = entry.title;
            cell.detailTextLabel.text = entry.webAddress;

            cell.textLabel.backgroundColor = [UIColor whiteColor];
            cell.detailTextLabel.backgroundColor = [UIColor whiteColor];
        }
        
    }
    
    cell.textLabel.textColor = [UIColor blackColor];                                // This is to make sure overwriting "load more" blue
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.sharersMenu != nil && [self.sharersMenu isMenuOpen]) {
        return;
    }
    
    if ([self isLoadMoreRowInSearchTable:tableView indexPath:indexPath]) {
        [self loadMoreSearchResultEntries];
        return;
        
    } else if ([self isLoadMoreRow:tableView indexPath:indexPath]) {
        [self loadMoreEntries];
        return;
    }
    
    NPBookmark *bookmark = nil;

    if ([self isSearchTableView:tableView]) {
        bookmark = [self.searchResultList.entries objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"OpenBookmark" sender:bookmark];

    } else {
        if ([self foldersShown] && indexPath.section == 0) {
            NPFolder *selectedFolder = [self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row];
            [self showItemsAfterSelectingFolder:selectedFolder];
            
        } else {
            bookmark = [self.currentEntryList.entries objectAtIndex:indexPath.row];
            [self performSegueWithIdentifier:@"OpenBookmark" sender:bookmark];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.currentEntryList == nil) {
        [self retrieveEntryList];
    }    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.childFolderBookmarkListController = nil;
}


// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [items addObject:[UIBarButtonItem spacer]];
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }

    } else {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UPDATE_FOLDER]];
            [items addObject:[UIBarButtonItem spacer]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE_FOLDER]];
            [items addObject:[UIBarButtonItem spacer]];
        }
        
        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }
    self.toolbarItems = items;
}


// ONLY handles entry add/update/delete action notifications
- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        
        NPEntry *updatedEntry = (NPEntry*)notification.object;
        
        if (updatedEntry.folder.moduleId != BOOKMARK_MODULE) {
            DLog(@"No action to take. This is for a different list view controller. my module Id:%i, other module Id:%i, my folder id:%i, other folder id:%i", self.currentFolder.moduleId, updatedEntry.folder.moduleId, self.currentFolder.folderId, updatedEntry.folder.folderId);
            return;
        }
        
        DLog(@"BookmarkListController received notification for module %i received entry list updated: %@", self.currentFolder.moduleId, updatedEntry);
        
        NPEntry *affectedEntryInList = nil;
        
        for (NPEntry *entry in self.currentEntryList.entries) {
            if ([entry.entryId isEqualToString:updatedEntry.entryId]) {
                affectedEntryInList = entry;
                break;
            }
        }
        
        if (affectedEntryInList == nil) {                                       // This is a new entry
            [self.currentEntryList addToTopOfList:[updatedEntry copy]];
            
            if ([self.currentEntryList isNotEmpty]) {
                [self.emptyListLabel removeFromSuperview];
            }

            [self refreshListTable];

        } else {                                                                // Update an existing entry in the list: title and color label.
            [self.currentEntryList deleteFromList:affectedEntryInList];
            [self.currentEntryList addToTopOfList:[updatedEntry copy]];
            [self refreshListTable];
        }
    }
}

@end
