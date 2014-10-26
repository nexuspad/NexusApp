//
//  BaseEntryListViewController.m
//  nexuspad
//
//  Created by Ren Liu on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BaseEntryListViewController.h"
#import "FolderViewController.h"
#import "EntryEditorTableViewController.h"
#import "NotificationUtil.h"
#import "StartViewController.h"
#import "UIViewController+NPUtil.h"
#import "UIColor+NPColor.h"
#import "UIViewController+KNSemiModal.h"
#import "SharerRightMenu.h"
#import "UserService.h"
#import "FPActivityView.h"

#define REFRESH_HEADER_HEIGHT 52.0f

static NSString *PULL_DOWN_TO_REFRESH;
static NSString *RELEASE_TO_REFRESH;
static NSString *LOADING;

NSString* const TOOLBAR_ITEM_UPDATE_FOLDER    = @"10";
NSString* const TOOLBAR_ITEM_UNSHARE_FOLDER   = @"11";
NSString* const TOOLBAR_ITEM_ADD              = @"21";
NSString* const TOOLBAR_ITEM_ADD_PICTURE_NOTE = @"22";
NSString* const TOOLBAR_ITEM_UNSHARE          = @"50";
NSString* const TOOLBAR_ITEM_FOLDER_PICKER    = @"30";
NSString* const TOOLBAR_ITEM_VIEW_SWITCHER    = @"40";

/*
 * 1. General service result check
 * 2. Search handling
 * 3. Folder picker handler
 * 4. Pull/refresh handler
 */

@interface BaseEntryListViewController ()
@property (nonatomic, strong) FolderViewController *folderViewController;

// Pull refresh
@property (nonatomic, strong) UIView *refreshHeaderView;
@property (nonatomic, strong) UILabel *refreshLabel;
@property (nonatomic, strong) UIImageView *refreshArrow;
@property (nonatomic, strong) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic, strong) UIScrollView *draggableView;
@property BOOL isDragging;
@property BOOL isLoading;

// Activity bar
@property (nonatomic, strong) FPActivityView *activityBar;

@property UIInterfaceOrientation currentInterfaceOrientation;

@end


@implementation BaseEntryListViewController

@synthesize dashboardButton, activityBar = _activityBar, doAlert = _doAlert;
@synthesize searchBar = _searchBar, listSearchDisplayController;
@synthesize entryListService, entryListTable, entryListIsLoading;
@synthesize currentFolder = _currentFolder, folderNavigationItems;
@synthesize currentEntryList, searchResultList;


// When the folder is changed, set the dataNeedsToBeRefreshed to YES
- (void)setCurrentFolder:(NPFolder *)newFolder {
    if (_currentFolder != nil && _currentFolder.folderId == newFolder.folderId &&
        _currentFolder.accessInfo.owner.userId == newFolder.accessInfo.owner.userId)
    {
        // No change needed
    }
    else
    {
        self.currentEntryList = nil;
    }

    _currentFolder = newFolder;
}


// Set the flag
- (void)retrieveEntryList {
    self.entryListIsLoading = YES;
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
}

- (void)retrieveSharersList {
    UserService *userService = [[UserService alloc] init];
    [userService getSharers:self.currentFolder.moduleId completion:^(NSArray *sharers) {
        if (sharers.count > 0) {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"getDisplayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
            self.sharers = [sharers sortedArrayUsingDescriptors:sortDescriptors];

            if (self.listMenuButton == nil) {
                self.listMenuButton = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"listmenu.png"]
                                                                 target:self
                                                                 action:@selector(openRightMenu:)];
            }
            self.navigationItem.rightBarButtonItem = self.listMenuButton;

        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }];
}

// Will be called from subclasses
- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    self.entryListIsLoading = NO;
}

- (void)serviceError:(ServiceResult*)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    self.entryListIsLoading = NO;
    DLog(@"Service returned error: %@", serviceResult.message);
}

- (void)serviceDeniedAccess:(id)serviceResult {
    [[AccountManager instance] logout];
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_main" bundle:nil];
    StartViewController* startController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"StartView"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:startController];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}


#pragma mark - default list refreshing

- (void)refreshListTable {
    [self.entryListTable reloadData];
}

- (void)setListToolbarItems {
}


#pragma mark - Target actions

// Subclass must overwrite this.
- (void)createNewEntry {
    NSLog(@"Error - createNewEntry MUST be overridden in subclass!");
}


#pragma mark - Open the folder picker

- (IBAction)openFolderPicker:(id)sender {
    // Pop to the last FolderViewController if it happens to be in the stack.
    for (UIViewController *controller in [self.navigationController.viewControllers reverseObjectEnumerator]) {
        if ([controller isKindOfClass:[FolderViewController class]]) {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }

    if (self.folderViewController == nil) {
        UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
        self.folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
        self.folderViewController.folderViewDelegate = self;
    }

    [self.folderViewController showFolderTree:self.currentFolder];

    // Push the folder view controller with animation
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionMoveIn; //kCATransitionFade; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromTop; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    
    [self.navigationController pushViewController:self.folderViewController animated:NO];
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    if (forAction == ForListing) {
        DLog(@"In didSelectFolder for listing selected folder id %i", selectedFolder.folderId);
        [self showItemsAfterSelectingFolder:selectedFolder];
    }
}

// This method handles showing the item after selecting a folder, either from the item list, or from the folder picker.
// It must be overriden respectively in EntryListFolderViewController and EntryTimeLineViewController.
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    NSLog(@"showItemsAfterSelectingFolder MUST be overridden for selecting folder/calendar to work!");
}


#pragma mark - right slide menu handling

// Whether the right menu icon is displayed is in BaseEntryListViewController
// Open the right menu
// This overwrites base class.
- (void)openRightMenu:(id)sender {
    if (self.sharersMenu == nil) {
        CGRect frame = CGRectMake(MENU_OFFSET, 20.0, [ViewDisplayHelper screenWidth] - MENU_OFFSET, [ViewDisplayHelper screenHeight]);
        self.sharersMenu = [[SharerRightMenu alloc] initWithFrame:frame];
        self.sharersMenu.menuDelegate = self;
    }
    
    self.sharersMenu.moduleId = self.currentFolder.moduleId;
    NSMutableArray *menuItems = [NSMutableArray arrayWithArray:self.sharers];
    [menuItems insertObject:[AccessEntitlement accountOwner] atIndex:0];
    self.sharersMenu.menuItems = menuItems;
    
    [self.sharersMenu selectedMenu:MenuRight withCompletion:^{
        // Make the menu item selection. Needs to be done in completion code.
        [self.sharersMenu selectMenuItem:self.currentFolder.accessInfo.owner];
    }];
}


// Delegate call when a sharer on the right menu is selected.
// CalendarViewController has separate implementation.
- (void)didSelectedSharer:(NPUser *)sharer {
    AccessEntitlement *accessInfo = [[AccessEntitlement alloc] initWithOwnerAndViewer:sharer theViewer:[AccessEntitlement accountOwner]];
    accessInfo.read = YES;
    NPFolder *sharerRootFolder = [[NPFolder alloc] initWithModuleAndFolderId:self.currentFolder.moduleId folderId:ROOT_FOLDER accessInfo:accessInfo];
    
    self.currentFolder = sharerRootFolder;
    
    [self.sharersMenu closeMenuWithCompletion:^{
        [self retrieveEntryList];
        [self setListToolbarItems];
    }];
}


- (IBAction)stopAllSharingFromSharer:(id)sender {
    _doAlert = [[DoAlertView alloc] init];
    _doAlert.nAnimationType = DoTransitionStylePop;
    _doAlert.dRound = 5.0;
    
    _doAlert.bDestructive = YES;
    [_doAlert doYesNo:[NSString stringWithFormat:@"Unshare everything from %@?", [self.currentFolder displayName]]
                 yes:^(DoAlertView *alertView) {
                     FolderService *folderService = [[FolderService alloc] init];
                     folderService.moduleId = self.currentFolder.moduleId;
                     folderService.serviceDelegate = self;
                     
                     [folderService stopSharing:self.currentFolder.moduleId fromUser:self.currentFolder.accessInfo.owner];
                     
                     // remove the share from sharers list
                     NSMutableArray *updatedSharers = [[NSMutableArray alloc] initWithCapacity:self.sharers.count-1];
                     for (NPUser *sharer in self.sharers) {
                         if (sharer.userId != self.currentFolder.accessInfo.owner.userId) {
                             [updatedSharers addObject:sharer];
                         }
                     }
                     self.sharers = [NSArray arrayWithArray:updatedSharers];
                     NSMutableArray *menuItems = [NSMutableArray arrayWithArray:self.sharers];
                     [menuItems insertObject:[AccessEntitlement accountOwner] atIndex:0];
                     
                     self.sharersMenu.menuItems = menuItems;
                     [self.sharersMenu refreshMenuItems];
                     
                     // Do go back to account owner
                     [self didSelectedSharer:[AccessEntitlement accountOwner]];
  
                 } no:^(DoAlertView *alertView) {
                     
                 }];

    _doAlert = nil;
}


/**
 * ------------------------------------------------------------------------------------
 * View and navigations
 *
 */

#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.currentEntryList.entries count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.currentEntryList isEmpty]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the entry at row
        NPEntry *entryToDelete = [self.currentEntryList.entries objectAtIndex:indexPath.row];
        [self.entryService deleteEntry:entryToDelete];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Make a copy of the toolbar items
    self.toolbarItemsLoadedInStoryboard = [[NSMutableDictionary alloc] initWithCapacity:5];
    for (UIBarButtonItem *item in self.toolbarItems) {
        if (item.tag != 0) {
            [self.toolbarItemsLoadedInStoryboard setObject:item forKey:[NSString stringWithFormat:@"%li", (long)item.tag]];
        }
    }
    
    if (self.currentFolder.moduleId != CALENDAR_MODULE) {
        self.entryListService = [[EntryListService alloc] init];
        self.entryListService.serviceDelegate = self;
        
        self.entryService = [[EntryService alloc] init];
        self.entryService.serviceDelegate = self;
        self.entryService.accessInfo = [_currentFolder.accessInfo copy];
        
        self.entryListTable.delegate = self;
        self.entryListTable.dataSource = self;
        
        if (self.listSearchDisplayController == nil) {
            self.listSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        }
        
        self.listSearchDisplayController.delegate = self;
        self.listSearchDisplayController.searchResultsDelegate = self;
        self.listSearchDisplayController.searchResultsDataSource = self;
        
        // Add the observer to handle entry update and deletion.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryListUpdatedNotification:) name:N_ENTRY_UPDATED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryDeletedNotification:) name:N_ENTRY_DELETED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryMovedNotification:) name:N_ENTRY_MOVED object:nil];        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_MOVED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.toolbarHidden = NO;

    self.navigationItem.title = [self.currentFolder displayName];    
    
    if (self.dashboardButton == nil) {
        self.dashboardButton = [UIBarButtonItem dashboardButtonPlain:self action:@selector(backToDashboard)];
    }
    
    if (self.currentFolder.moduleId == CALENDAR_MODULE) {
        [self.navigationItem setHidesBackButton:YES animated:NO];
        self.navigationItem.leftBarButtonItem = self.dashboardButton;
        
    } else {
        if (self.currentFolder.folderId == ROOT_FOLDER) {
            [self.navigationItem setHidesBackButton:YES animated:NO];
            self.navigationItem.leftBarButtonItem = self.dashboardButton;
        } else {
            [self.navigationItem setHidesBackButton:NO];
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
    
    [self setListToolbarItems];
}


- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.dashboardButton = nil;
    [self.searchBar removeFromSuperview];
    self.searchBar = nil;

    // Attempted to fix the memory leak issue. No luck.
    self.listSearchDisplayController.searchResultsTableView.tableHeaderView = nil;
    self.listSearchDisplayController = nil;

    self.entryListTable.tableHeaderView = nil;
    self.entryListTable = nil;
    self.entryCollectionView = nil;
    self.entryListService = nil;
    self.entryService = nil;

    [self cleanupData];
    
    [super viewDidUnload];
}


- (void)cleanupData {
    self.currentEntryList = nil;
    self.searchResultList = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Should be the best place for getting the accurate orientation.
    self.currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.sharersMenu clearMenu];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/**
 * ------------------------------------------------------------------------------------
 * Search related
 *
 */

- (BOOL)isSearchTableView:(UITableView*)tableView
{
    return [tableView isEqual:self.listSearchDisplayController.searchResultsTableView];
}

#pragma mark - UISearchBar delegate, UISearchDisplayController delegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar*)searchBar
{
    if ([self searchLocal]) {
        return;

    } else {
        [self dimSearchTable];
        [self.listSearchDisplayController.searchResultsTableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    DLog(@"!!!!!!!!!!!!!!!! No implementation. Must be implemented in subclass!");
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if ([self searchLocal]) {
        [self filterContentForSearchText:searchString 
                                   scope:[[self.searchBar scopeButtonTitles]
                                          objectAtIndex:[self.searchBar
                                                         selectedScopeButtonIndex]]];
        
        return YES;        
        
    } else {
        return NO;
    }
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    if ([self searchLocal]) {
        [self filterContentForSearchText:[self.searchBar text]
                                   scope:[[self.searchBar scopeButtonTitles]
                                          objectAtIndex:searchOption]];
        
        return YES;        
        
    } else {
        return NO;
    }

}

- (void)dimSearchTable
{
    [self.listSearchDisplayController.searchResultsTableView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.55]];
    [self.listSearchDisplayController.searchResultsTableView setRowHeight:800.0];
    [self.listSearchDisplayController.searchResultsTableView setScrollEnabled:NO];
}

- (void)unDimSearchTable
{
    [self.listSearchDisplayController.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.listSearchDisplayController.searchResultsTableView setRowHeight:44.0];
    [self.listSearchDisplayController.searchResultsTableView setScrollEnabled:YES];
}


// Just filter the existing rows
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"title contains[cd] %@",
                                    searchText];
    
    if (self.searchResultList == nil) {
        self.searchResultList = [[EntryList alloc] init];
    }
    self.searchResultList.entries = [NSMutableArray arrayWithArray:[self.currentEntryList.entries filteredArrayUsingPredicate:resultPredicate]];
}

// Search local utilize the filterContentForSearchText
- (BOOL)searchLocal {
    if ([_currentFolder moduleId] == CONTACT_MODULE) {
        return YES;
    }
    
    if (![self.currentEntryList hasMore]) {        // There are more entries on the server.
        if ([_currentFolder folderId] == ROOT_FOLDER) {
            return NO;
        }
        return YES;

    } else {
        DLog(@"Total count %li, local count %li, need to perform webservice search...",
             (long)self.currentEntryList.totalCount, (unsigned long)[self.currentEntryList.entries count]);
        return NO;
    }
}

- (void)loadMoreSearchResultEntries
{
    if (self.searchResultList.countPerPage == 0) return;
    
    // Load more entries using the next page id
    if ([self.searchResultList hasMore]) {
        NSInteger nextPage = [self.searchResultList currentPageId] + 1;
        [self.entryListService searchEntries:self.searchResultList.keyword
                                  templateId:self.searchResultList.templateId
                                    inFolder:self.currentFolder
                                      pageId:nextPage
                                countPerPage:0];
    }
}

- (BOOL)isLoadMoreRowInSearchTable:(UITableView*)tableView indexPath:(NSIndexPath *)indexPath
{
    if ([self isSearchTableView:tableView]) {
        if (indexPath.row == [self.searchResultList.entries count]) return YES;
    }
    return NO;
}

- (BOOL)hasMoreSearchResultToLoad:(UITableView*)tableView
{
    if ([self isSearchTableView:tableView]) {
        return [self.searchResultList hasMore];
    }
    return false;
}


#pragma mark - notification handling

- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    // No implementation
}

- (void)handleEntryDeletedNotification:(NSNotification*)notification {
    DLog(@"BaseEntryListViewController received notification for module %i deleted entry...", self.currentFolder.moduleId);
    
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        
        NPEntry *deletedEntry = (NPEntry*)notification.object;
        
        DLog(@"Deleted entry: %@", deletedEntry);
        
        if (deletedEntry.folder.moduleId != self.currentFolder.moduleId) {                 // Make sure I'm the right notification receiver.
            return;
        }
        
        if ([self.currentEntryList deleteFromList:deletedEntry] == YES) {
            [self refreshListTable];
        }
    }
}

- (void)handleEntryMovedNotification:(NSNotification*)notification {
    // No need to handle moving for Contact list.
    if (self.currentFolder.moduleId == CONTACT_MODULE) {
        return;
    }
    
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        
        NPEntry *movedEntry = (NPEntry*)notification.object;
        
        if (movedEntry.folder.moduleId == self.currentFolder.moduleId) {
            DLog(@"BaseEntryListViewController received notification for module %i moved entry %@ ", movedEntry.folder.moduleId, movedEntry.entryId);

            if (self.currentFolder.moduleId == PHOTO_MODULE || self.currentFolder.moduleId == CALENDAR_MODULE) {
                [self.currentEntryList updateEntryInList:movedEntry];
            } else {
                if (self.currentEntryList.folder.folderId == movedEntry.folder.folderId) {
                    [self.currentEntryList addToTopOfList:movedEntry];
                } else {
                    [self.currentEntryList deleteFromList:movedEntry];
                }
            }
            
            [self refreshListTable];
        }
    }
}


// ------------------------------------------------------------------------------------------------
// Pull refresh functions.
// ------------------------------------------------------------------------------------------------

- (void)initPullRefresh:(UIScrollView*)scrollableView {
    self.draggableView = scrollableView;
    
    PULL_DOWN_TO_REFRESH = NSLocalizedString(@"Pull down to refresh...",);
    RELEASE_TO_REFRESH = NSLocalizedString(@"Release to refresh...",);
    LOADING = NSLocalizedString(@"Refreshing...",);
    
    self.refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 320, REFRESH_HEADER_HEIGHT)];
    self.refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    self.refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, REFRESH_HEADER_HEIGHT)];
    self.refreshLabel.backgroundColor = [UIColor clearColor];
    self.refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    self.refreshLabel.text = PULL_DOWN_TO_REFRESH;
    self.refreshLabel.textColor = [UIColor textColorFromBackground:scrollableView.backgroundColor];
    self.refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    if ([self.refreshLabel.textColor isEqual:[UIColor blackColor]]) {
        self.refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blackArrow.png"]];
    } else {
        self.refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteArrow.png"]];
    }
    
    self.refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    
    self.refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    self.refreshSpinner.hidesWhenStopped = YES;
    
    [self.refreshHeaderView addSubview:self.refreshLabel];
    [self.refreshHeaderView addSubview:self.refreshArrow];
    [self.refreshHeaderView addSubview:self.refreshSpinner];
    
    [self.draggableView addSubview:self.refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.isLoading) return;
    self.isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isLoading) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0 && self.draggableView != nil) {
            self.draggableView.contentInset = UIEdgeInsetsZero;
        } else if (scrollView.contentOffset.y >= [self pullRefreshOffsetThreshold]) {
            self.draggableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
        }
        
    } else if (self.isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [UIView animateWithDuration:0.25 animations:^{
            if (scrollView.contentOffset.y < [self pullRefreshOffsetThreshold]) {               // User is scrolling above the header
                self.refreshLabel.text = RELEASE_TO_REFRESH;
                self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
                
            } else {
                // User is scrolling somewhere within the header
                self.refreshLabel.text = PULL_DOWN_TO_REFRESH;
                self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }
        }];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.isLoading) return;
    self.isDragging = NO;
    
    if (scrollView.contentOffset.y <= [self pullRefreshOffsetThreshold]) {
        // Released above the header
        [self startLoading];
    }
}

- (float)pullRefreshOffsetThreshold {
    float refreshOffsetThreadhold = REFRESH_HEADER_HEIGHT;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        refreshOffsetThreadhold += 64;
    }
    return -refreshOffsetThreadhold;
}

- (void)startLoading {
    self.isLoading = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.refreshLabel.text = LOADING;
                         self.refreshArrow.hidden = YES;
                         [self.refreshSpinner startAnimating];
                     }];
    
    [self retrieveEntryList];

    self.isLoading = NO;
    
    // Hide the header
    [UIView animateWithDuration:0.3
                     animations:^{
                         //self.draggableView.contentInset = UIEdgeInsetsMake(64.0, 0, 0, 0);
                         self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
                     }
                     completion:^(BOOL finished) {
                         // Reset the header
                         self.refreshLabel.text = PULL_DOWN_TO_REFRESH;
                         self.refreshArrow.hidden = NO;
                         [self.refreshSpinner stopAnimating];
                     }];
}


#pragma mark - activity bar
- (void)showActivityBar {
    if (self.activityBar ==nil) {
        UIImage* activityImage = [[UIImage imageNamed:@"activity-bar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1)];
        self.activityBar = [[FPActivityView alloc] initWithFrame:CGRectMake(0, 64.0, self.view.frame.size.width, 3) andActivityBar:activityImage];
        [self.view addSubview:self.activityBar];
    }
    [self.activityBar start];
}

- (void)hideActivityBar {
    [self.activityBar stop];
}


/*
 * Handles the rotation event: UIDeviceOrientationDidChangeNotification
 * since device rotation includes two more values: FaceUp and FaceDown, it needs to be
 * matched up with interface rotation.
 *
 */
- (BOOL)didRotate:(NSNotification *)notification {
    if ([ViewDisplayHelper interfaceOrientationDiffersFromDeviceOrientation:self.currentInterfaceOrientation] ||
        self.currentInterfaceOrientation != self.interfaceOrientation)
    {
        self.currentInterfaceOrientation = self.interfaceOrientation;

        if (self.sharersMenu != nil) {
            if ([self.sharersMenu isMenuOpen]) {
                [self.sharersMenu closeMenuWithCompletion:^{ }];
            }
            
            [self.sharersMenu clearMenu];
            self.sharersMenu = nil;
        }
        
        return YES;

    } else {
        return NO;
    }

}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

@end
