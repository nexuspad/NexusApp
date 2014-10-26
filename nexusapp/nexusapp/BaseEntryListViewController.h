//
//  ListViewController.h
//  nexuspad
//
//  Created by Ren Liu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPModule.h"
#import "EntryService.h"
#import "EntryListService.h"
#import "UserManager.h"
#import "EntryDetailTableViewController.h"
#import "FolderViewController.h"
#import "ViewDisplayHelper.h"
#import "DashboardController.h"
#import "EntryEditorUpdateDelegate.h"
#import "UIBarButtonItem+NPUtil.h"
#import "ActionResult.h"
#import "SlideMenu.h"
#import "SharerRightMenu.h"
#import "DoAlertView.h"

extern NSString* const TOOLBAR_ITEM_UPDATE_FOLDER;
extern NSString* const TOOLBAR_ITEM_UNSHARE_FOLDER;
extern NSString* const TOOLBAR_ITEM_ADD;
extern NSString* const TOOLBAR_ITEM_ADD_PICTURE_NOTE;
extern NSString* const TOOLBAR_ITEM_UNSHARE;
extern NSString* const TOOLBAR_ITEM_FOLDER_PICKER;
extern NSString* const TOOLBAR_ITEM_VIEW_SWITCHER;


@interface BaseEntryListViewController : UIViewController
                                <UITableViewDelegate,
                                UITableViewDataSource,
                                UISearchBarDelegate,
                                UISearchDisplayDelegate,
                                FolderViewControllerDelegate,
                                EntryEditorUpdateDelegate,              // This is for adding new entry finish call back.
                                NPDataServiceDelegate,
                                SlideMenuDelegate>

@property (nonatomic, strong) UIBarButtonItem *dashboardButton;
@property (nonatomic, strong) UIBarButtonItem *listMenuButton;
@property (nonatomic, strong) NSMutableDictionary *toolbarItemsLoadedInStoryboard;

@property (weak, nonatomic) IBOutlet UITableView *entryListTable;
@property (weak, nonatomic) IBOutlet UICollectionView *entryCollectionView;


// Make them strong so they can be programatically initialized in PhotoListController
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UISearchDisplayController *listSearchDisplayController;

@property (nonatomic, strong) SharerRightMenu *sharersMenu;

@property BOOL entryListIsLoading;

@property (nonatomic, strong) NPFolder *currentFolder;
@property (nonatomic, strong) NSMutableArray *folderNavigationItems;
@property (nonatomic, strong) EntryList *currentEntryList;
@property (nonatomic, strong) EntryList *searchResultList;

@property (nonatomic, strong) EntryService *entryService;
@property (nonatomic, strong) EntryListService *entryListService;

// Sharing
@property (nonatomic, strong) NSArray *sharers;

// Modal alert view
@property (strong, nonatomic) DoAlertView *doAlert;


// Set the toolbar items for the entry list screen - must be overriden by the subclasses
- (void)setListToolbarItems;


// Segue to new entry view - must be overriden by subclasses
- (void)createNewEntry;


// Load more
- (BOOL)hasMoreSearchResultToLoad:(UITableView*)tableView;
- (void)loadMoreSearchResultEntries;
- (BOOL)isLoadMoreRowInSearchTable:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath;


// Search
- (BOOL)isSearchTableView:(UITableView*)tableView;
- (void)dimSearchTable;
- (void)unDimSearchTable;


// View items
- (void)retrieveEntryList;
- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction;
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder;

- (void)retrieveSharersList;


// Just to reload the table
- (void)refreshListTable;


// Handles notifications - must be overriden by subclasses
- (void)handleEntryListUpdatedNotification:(NSNotification*)notification;
- (void)handleEntryDeletedNotification:(NSNotification*)notification;


// Folder picker
- (IBAction)openFolderPicker:(id)sender;


// Pull refresh
- (void)initPullRefresh:(UIScrollView*)scrollableView;
- (float)pullRefreshOffsetThreshold;

// Activity bar
- (void)showActivityBar;
- (void)hideActivityBar;

// Handle rotation notification
- (BOOL)didRotate:(NSNotification *)notification;

// Clean up for memory warning
- (void)cleanupData;

@end
