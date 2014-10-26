//
//  AlbumListController.m
//  nexuspad
//
//  Created by Ren Liu on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AlbumListController.h"
#import "AlbumEditorViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "ImageCell.h"
#import "PhotoListController.h"
#import "UITableViewCell+NPUtil.h"

@interface AlbumListController ()
@property (strong, nonatomic) IBOutlet UIToolbar *bottomBar;
@property (nonatomic, strong) AlbumListController *childFolderAlbumListController;
@end

@implementation AlbumListController
@synthesize photoAlbumSwitch;


// Overwrite the method in EntryListController so we can differentiate opening photos vs. album
// Set navigationItem.title must be included in the overwrite.
- (void)retrieveEntryList {

    [super retrieveEntryList];
    
    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:album];
    }
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            self.navigationItem.title = NSLocalizedString(@"My albums",);
        } else {
            self.navigationItem.title = [self.currentFolder displayName];
        }
    } else {
        self.navigationItem.title = [self.currentFolder displayName];
    }
    
    [self.entryListService getEntries:self.currentEntryList.templateId inFolder:self.currentFolder pageId:1 countPerPage:self.currentEntryList.countPerPage];
}

- (void)updateServiceResult:(id)serviceResult
{
    [super updateServiceResult:serviceResult];

    if ([serviceResult isKindOfClass:[EntryList class]]) {

        EntryList *returnedList = (EntryList*)serviceResult;

        if (![returnedList isSearchResult]) {                     // Regular listing result
            
            // CANNOT use isNotEmpty method here.
            if (returnedList.entries.count > 0) {
                [self.emptyListLabel removeFromSuperview];

                if (returnedList.pageId > 1) {
                    [self.currentEntryList.entries addObjectsFromArray:[self convertToAlbumArray:returnedList.entries]];
                    DLog(@"More query returned %li entries.", (unsigned long)[returnedList.entries count]);
                    
                } else {
                    self.currentEntryList = returnedList;
                    self.currentEntryList.entries = [self convertToAlbumArray:self.currentEntryList.entries];
                    DLog(@"Initial query returned %li entries with total count of: %li.",
                         (unsigned long)[self.currentEntryList.entries count], (long)self.currentEntryList.totalCount);
                }
                
                [self.entryListTable reloadData];
                
            } else {
                [self.entryListTable addSubview:self.emptyListLabel];

                self.currentEntryList = returnedList;
                [self.entryListTable reloadData];
            }
            
        } else {                                                // Search result
            
            if (self.searchResultList == nil) {
                self.searchResultList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:album];
            }
            
            if (returnedList.pageId > 1) {
                [self.searchResultList.entries addObjectsFromArray:[self convertToAlbumArray:returnedList.entries]];
                DLog(@"More search query %@", [serviceResult description]);
                
            } else {
                self.searchResultList = [serviceResult copy];
                self.searchResultList.entries = [self convertToAlbumArray:self.searchResultList.entries];
                DLog(@"Initial search query returned %@.", [self.searchResultList description]);
            }
            
            [self unDimSearchTable];
            [self.listSearchDisplayController.searchResultsTableView reloadData];
        }
    }
}

- (NSMutableArray*)convertToAlbumArray:(NSArray*)npEntryArray
{
    NSMutableArray *tmpMediaArr = [[NSMutableArray alloc] initWithCapacity:[npEntryArray count]];
    
    for (NPEntry *entry in npEntryArray) {
        NPPhoto *media = [NPPhoto photoFromEntry:entry];
        media.templateId = album;
        [tmpMediaArr addObject:media];
    }
    
    return [NSMutableArray arrayWithArray:tmpMediaArr];
}

// Display items after a folder selected
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    if (self.childFolderAlbumListController == nil) {
        self.childFolderAlbumListController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumList"];
    }

    self.childFolderAlbumListController.currentFolder = [selectedFolder copy];
    [self.navigationController pushViewController:self.childFolderAlbumListController animated:YES];
}

#pragma mark - switch to album list

- (IBAction)segmentedControlValueChanged:(id)sender {
    if (self.photoAlbumSwitch.selectedSegmentIndex == 0) {      // Switch to album list view
        PhotoListController *photoListController = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoList"];
        
        photoListController.currentFolder = [[NPFolder alloc] initWithModuleAndFolderId:PHOTO_MODULE
                                                                             folderId:0
                                                                           accessInfo:self.currentFolder.accessInfo];
        
        NSMutableArray *controllers = [[NSMutableArray alloc] init];
        
        for (UIViewController *controller in self.navigationController.viewControllers) {
            [controllers addObject:controller];
            if ([controller isKindOfClass:[DashboardController class]]) {
                break;
            }
        }
        
        [controllers addObject:photoListController];

        CATransition* transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionMoveIn; //kCATransitionFade; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
        transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
        [self.navigationController.view.layer addAnimation:transition forKey:nil];
        
        [self.navigationController setViewControllers:controllers animated:NO];
    }

}

- (BOOL)foldersShown {
    return NO;
}


#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    [self.entryListService searchEntries:self.searchBar.text templateId:album inFolder:self.currentFolder pageId:1 countPerPage:0];
}


#pragma mark - tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 59;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isSearchTableView:tableView]) {
        NSInteger count = [self.searchResultList.entries count];
        if ([self hasMoreSearchResultToLoad:tableView]) {
            return count + 1;
        }
        return count;
        
    } else {
        
        if (!self.entryListIsLoading && self.currentEntryList.entries.count == 0) {
            return 0;
        }
        
        NSInteger count = [self.currentEntryList.entries count];
        if ([self hasMoreToLoad:tableView]) {
            return count + 1;
        }
        
        return count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isSearchTableView:tableView]) {
        if ([NSString isBlank:self.searchResultList.keyword]) {
            return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DummyCell"];
        }
    }

    if ([self isLoadMoreRowInSearchTable:tableView indexPath:indexPath] ||
        [self isLoadMoreRow:tableView indexPath:indexPath])
    {
        return [UITableViewCell loadMoreCell];
    }
    
    NPPhoto *media = nil;
    
    if ([self isSearchTableView:tableView]) {
        media = [NPPhoto photoFromEntry:[self.searchResultList.entries objectAtIndex:indexPath.row]];
    } else {
        media = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }
    
    static NSString *CellIdentifier = @"AlbumCell";
    
    ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        CGSize size = CGSizeMake(75.0, 56.0);
        cell = [[ImageCell alloc] initWithStyleAndSize:UITableViewCellStyleDefault imageSize:size reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (![NSString isBlank:media.tnUrl]) {
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[media tnUrl]] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageProgressiveDownload];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"placeholder.png"];
    }
    
    cell.titleLabel.text = media.title;
    
    [cell layoutIfNeeded];

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

    NPPhoto *album = nil;
    
    if ([self isSearchTableView:tableView]) {
        album = [self.searchResultList.entries objectAtIndex:indexPath.row];
    } else {
        album = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }

    [self performSegueWithIdentifier:@"OpenAlbum" sender:album];
}

- (IBAction)addButtonTapped:(id)sender {
    [self createNewEntry];
}

- (void)createNewEntry
{
    [self performSegueWithIdentifier:@"NewAlbum" sender:self];
}

#pragma - segue to photo view to display album photos

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NPAlbum*)albumToOpen {
    if ([segue.identifier isEqualToString:@"OpenAlbum"]) {
        [segue.destinationViewController setAlbum:albumToOpen];
        
    } else if ([segue.identifier isEqualToString:@"NewAlbum"]) {
        
        AlbumEditorViewController* editorController = (AlbumEditorViewController*)[segue destinationViewController];
        NPAlbum *newAlbum = [[NPAlbum alloc] init];
        newAlbum.templateId = album;
        newAlbum.folder = [self.currentFolder copy];
        newAlbum.accessInfo = [self.currentFolder.accessInfo copy];
        editorController.album = newAlbum;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }
    
    // Make a copy of the toolbar items
    self.toolbarItemsLoadedInStoryboard = [[NSMutableDictionary alloc] initWithCapacity:5];
    for (UIBarButtonItem *item in self.bottomBar.items) {
        if (item.tag != 0) {
            [self.toolbarItemsLoadedInStoryboard setObject:item forKey:[NSString stringWithFormat:@"%li", (long)item.tag]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Photos has custom toolbar in order to fit the switch
    self.navigationController.toolbarHidden = YES;

    self.photoAlbumSwitch.selectedSegmentIndex = 1;
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            self.navigationItem.title = NSLocalizedString(@"My albums",);
        } else {
            self.navigationItem.title = [self.currentFolder displayName];
        }
        
        // Back to dashboard when viewing albums at ROOT
        self.navigationItem.leftBarButtonItem = self.dashboardButton;

    } else {
        self.navigationItem.title = [self.currentFolder displayName];
    }
    
    if (self.currentEntryList == nil) {
        [self retrieveEntryList];
    }
    
    if (![NPService isServiceAvailable]) {
        [ViewDisplayHelper displayWarningMessage:NSLocalizedString(@"No Internet connection",)
                                         message:NSLocalizedString(@"Connect to the Internet to view photos",)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self setPhotoAlbumSwitch:nil];
    self.childFolderAlbumListController = nil;
}


// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
        [items addObject:[UIBarButtonItem spacer]];
        
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }
        
    } else {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
        [items addObject:[UIBarButtonItem spacer]];
        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }
    
    [self.bottomBar setItems:items];
}


// ONLY handles entry add/update/delete action notifications
- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPAlbum class]]) {
        DLog(@"Receive notification to refresh album listing...");

        NPEntry *updatedEntry = (NPEntry*)notification.object;

        NPEntry *affectedEntryInList = nil;
        
        for (NPEntry *entry in self.currentEntryList.entries) {
            if ([entry.entryId isEqualToString:updatedEntry.entryId]) {
                affectedEntryInList = entry;
                break;
            }
        }
        
        if (affectedEntryInList == nil) {                                       // This is a new entry
            [self.currentEntryList.entries addObject:[updatedEntry copy]];
            [self refreshListTable];
            [self retrieveEntryList];

        } else {                                                                // Update an existing entry in the list: title and color label.
            [self.currentEntryList.entries removeObject:affectedEntryInList];
            [self.currentEntryList addToTopOfList:[updatedEntry copy]];
            [self refreshListTable];
        }
    }
}

@end
