//
//  PhotoModuleViewController.m
//  nexuspad
//
//  Created by Ren Liu on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "PhotoListController.h"
#import "PhotoSearchCollectionViewController.h"
#import "LightboxViewController.h"
#import "PhotoUploadViewController.h"
#import "NotificationUtil.h"
#import "AlbumListController.h"
#import "NPEntry.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+NPUtil.h"
#import "NPUploadHelper.h"
#import "NPServiceNotificationUtil.h"


@interface PhotoListController()
@property BOOL isViewingSearchResult;
@property (nonatomic, strong) UILabel *emptyListLabel;
@property (nonatomic, strong) UISearchBar *photoSearchBar;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomBar;

@property (nonatomic, strong) PhotoListController *childFolderPhotoListController;

@property BOOL allowUploading;
@end


@implementation PhotoListController

@synthesize isViewingSearchResult;
@synthesize photoAlbumSwitch;
@synthesize emptyListLabel;


// Overwrite the method in EntryListController so we can differentiate opening photos vs. album
// Set navigationItem.title must be included in the overwrite.
- (void)retrieveEntryList {
    [super retrieveEntryList];

    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:photo];
    }
    
    self.navigationItem.title = [self.currentFolder displayName];

    [self.entryListService getEntries:self.currentEntryList.templateId
                             inFolder:self.currentFolder
                               pageId:1
                         countPerPage:self.currentEntryList.countPerPage];
}

// Photo list is unique because each Media object also carries an index for lightbox navigation.
// In this callback we convert entryList element from NPEntry to Media object.
- (void)updateServiceResult:(id)serviceResult
{
    [super updateServiceResult:serviceResult];

    if ([serviceResult isKindOfClass:[EntryList class]]) {
        EntryList *returnedList = (EntryList*)serviceResult;

        if (![returnedList isSearchResult]) {                                   // Regular photo listing
            
            // CANNOT use isNotEmpty method because folder is not displayed.
            if (returnedList.entries.count > 0) {
                if (returnedList.pageId > 1) {
                    [self.currentEntryList.entries addObjectsFromArray:[self convertToPhotoArray:returnedList.entries
                                                                                   startingIndex:[self.currentEntryList.entries count]]];
                    DLog(@"Page %li returned %li entries.", (long)returnedList.pageId, (unsigned long)[returnedList.entries count]);
                    
                } else {
                    self.currentEntryList = returnedList;
                    DLog(@"Initial query returned %li entries with total count of: %li.", (unsigned long)[self.currentEntryList.entries count], (long)self.currentEntryList.totalCount);
                }
                
                [self.emptyListLabel removeFromSuperview];
                [self.entryCollectionView reloadData];

            } else {
                self.currentEntryList = returnedList;                           // Still need to set currentEntryList to show no result message.
                [self.entryCollectionView reloadData];
                [self.entryCollectionView addSubview:self.emptyListLabel];
            }

            self.isViewingSearchResult = NO;
            
        } else {                                                                // Photo search result
            self.isViewingSearchResult = YES;

            self.searchResultList = [returnedList copy];
            self.searchResultList.entries = [self convertToPhotoArray:returnedList.entries startingIndex:0];
            
            [self.entryCollectionView reloadData];
        }
    }
}

- (NSMutableArray*)convertToPhotoArray:(NSArray*)npEntryArray startingIndex:(NSInteger)startingIndex
{
    NSMutableArray *tmpMediaArr = [[NSMutableArray alloc] initWithCapacity:[npEntryArray count]];
    
    for (NPEntry *entry in npEntryArray) {
        NPPhoto *media = [NPPhoto photoFromEntry:entry];
        media.templateId = photo;
        media.displayIndex = startingIndex;
        [tmpMediaArr addObject:media];
        startingIndex++;
    }
    
    return [NSMutableArray arrayWithArray:tmpMediaArr];
}


#pragma mark - UICollectionView delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isViewingSearchResult) {
        return self.searchResultList.entries.count;
    } else {
        return self.currentEntryList.entries.count;
    }
}


- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

    if ([kind isEqual:UICollectionElementKindSectionHeader]) {
        
        static NSString *headerIdentifier = @"HeaderView";
        UICollectionReusableView *header = [self.entryCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                        withReuseIdentifier:headerIdentifier
                                                                                               forIndexPath:indexPath];

        if (header == nil) {
            header = [[UICollectionReusableView alloc] init];
        }

        CGRect rect = header.frame;
        rect.origin.x = 0;
        rect.origin.y = 0;
        self.photoSearchBar.frame = rect;
        
        [header addSubview:self.photoSearchBar];
        
        return header;
    }
    
    if ([kind isEqual:UICollectionElementKindSectionFooter]) {
    }
    
    return nil;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"PhotoCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *aImageView = (UIImageView *)[cell viewWithTag:100];
    
    [UIImageView roundedCorner:aImageView];
    aImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    aImageView.userInteractionEnabled = YES;
    
    NPPhoto *photo = nil;
    
    if (self.isViewingSearchResult) {
        photo = [self.searchResultList.entries objectAtIndex:indexPath.row];
    } else {
        photo = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }

    if (photo.tnUrl.length > 0) {
        NSString *tnImageUrl = [NPWebApiService appendAuthParams:photo.tnUrl];
        
        [aImageView sd_setImageWithURL:[NSURL URLWithString:tnImageUrl]
                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                            options:SDWebImageRetryFailed
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                              if (error) {
                                  photo.uploadImage.thumbnailImage = image;
                              }
                          }];        
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.sharersMenu != nil && [self.sharersMenu isMenuOpen]) {
        return;
    }

    if (![NPService isServiceAvailable]) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You are offline",)
                                                          message:NSLocalizedString(@"You need to be connected to the Internet to view the photo.",)
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK",)
                                                otherButtonTitles:nil];
        [message show];
        return;
    }

    NPPhoto *selectedPhoto = nil;
    
    if (self.isViewingSearchResult) {
        selectedPhoto = [self.searchResultList.entries objectAtIndex:indexPath.row];
    } else {
        selectedPhoto = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }
    
    selectedPhoto.displayIndex = indexPath.row;

    [self performSegueWithIdentifier:@"OpenLightbox" sender:selectedPhoto];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
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
    NSInteger threadholdOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    
    if (currentOffset >= threadholdOffset - 80) {
        [self loadMoreEntries];
        NSLog(@"Load next page");
    } else {
        [super scrollViewWillBeginDragging:scrollView];
    }
}


// Display items after a folder selected
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    if (self.childFolderPhotoListController == nil) {
        self.childFolderPhotoListController = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoList"];
    }

    [self.childFolderPhotoListController setCurrentFolder:[selectedFolder copy]];
    [self.navigationController pushViewController:self.childFolderPhotoListController animated:YES];
}


#pragma mark - searchbar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.photoSearchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.photoSearchBar setText:@""];
    [self.photoSearchBar setShowsCancelButton:NO animated:YES];
    [self.photoSearchBar resignFirstResponder];
    
    self.isViewingSearchResult = NO;
    [self.entryCollectionView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@"Searching..."];
    [self.entryListService searchEntries:self.photoSearchBar.text templateId:photo inFolder:self.currentFolder pageId:1 countPerPage:0];
    [self.photoSearchBar setShowsCancelButton:YES animated:NO];
    [self.photoSearchBar resignFirstResponder];
    
    self.isViewingSearchResult = YES;
}


#pragma mark UICollectionView Delegate Methods


- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate 
                                    predicateWithFormat:@"title contains[cd] %@",
                                    searchText];
    
    self.searchResultList.entries = [NSMutableArray arrayWithArray:[self.currentEntryList.entries filteredArrayUsingPredicate:resultPredicate]];
}


#pragma mark - EntryViewPrevNextDelegate

// Return the NPUpload object
- (id)getEntryAtIndex:(NSInteger)index {
    if (index < 0) {
        return nil;
    }

    NSArray *theList = nil;
    
    if (self.isViewingSearchResult) {
        theList = self.searchResultList.entries;
        
    } else {
        theList = self.currentEntryList.entries;
    }
    
    if (index == ([theList count] - 4)) {           // When ALMOST at the last item in the list, load more into list
        if (self.isViewingSearchResult) {
            if ([self.searchResultList hasMore]) {
                [self loadMoreSearchResultEntries];
            }
            
        } else {
            if ([self.currentEntryList hasMore]) {
                [self loadMoreEntries];
            }
        }

    } else if (index > ([theList count] - 1)) {     // Out of bound, return to the very first photo in folder
        // Go back to the very first one
        NPPhoto *photo = [theList objectAtIndex:0];
        photo.uploadImage.displayIndex = 0;
        photo.uploadImage.tnUrl = photo.tnUrl;
        return photo;
    }
    
    if ([theList objectAtIndex:index] != nil) {
        NPPhoto *photo = [theList objectAtIndex:index];
        photo.uploadImage.displayIndex = index;
        photo.uploadImage.tnUrl = photo.tnUrl;
        return photo;
    }
    
    // Shouldn't end up here.
    return nil;
}


#pragma mark - delete photo at index

// delete entey delegate called from Lightbox view controller.
- (NPScrollIndex*)deleteEntryAtIndex:(NSInteger)indexToDelete {
    EntryList *theList = nil;
    
    if (self.isViewingSearchResult) {
        theList = self.searchResultList;
    } else {
        theList = self.currentEntryList;
    }
    
    NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];

    if (theList.entries.count > indexToDelete && [theList.entries objectAtIndex:indexToDelete] != nil) {
        // Make service call to delete the object
        NPPhoto *photoToDelete = [theList.entries objectAtIndex:indexToDelete];
        photoToDelete.status = ENTRY_STATUS_DELETED;
        EntryService *entryService = [[EntryService alloc] init];
        [entryService deleteEntry:photoToDelete];
        
        [theList deleteFromList:photoToDelete];

        [self.entryCollectionView reloadData];
        
        // re-assign the displayIndex for each attachment
        int i = 0;
        for (NPPhoto *photo in theList.entries) {
            photo.uploadImage.displayIndex = i;
        }
        
        scrollIndex.totalCount = theList.entries.count;
        if (indexToDelete > theList.entries.count - 1) {      // Deleted the last one
            scrollIndex.currentIndex = 0;
        } else {
            scrollIndex.currentIndex = indexToDelete;                       // already moved to next index
        }
        
    } else {
        scrollIndex.totalCount = theList.entries.count;
        scrollIndex.currentIndex = 0;
    }

    return scrollIndex;
}

- (void)loadMoreEntries
{
    if (self.isViewingSearchResult) {
        if (self.searchResultList.countPerPage == 0) return;
        
        if ([self.searchResultList hasMore]) {
            NSInteger nextPage = [self.searchResultList currentPageId] + 1;
            [ViewDisplayHelper displayWaiting:self.view messageText:nil];
            [self.entryListService searchEntries:self.photoSearchBar.text templateId:photo inFolder:self.currentFolder pageId:nextPage countPerPage:self.searchResultList.countPerPage];
        }

    } else {
        if (self.currentEntryList.countPerPage == 0) return;
        
        // Load more entries using the next page id
        if ([self.currentEntryList hasMore]) {
            NSInteger nextPage = [self.currentEntryList currentPageId] + 1;
            [ViewDisplayHelper displayWaiting:self.view messageText:nil];
            [self.entryListService getEntries:self.currentEntryList.templateId inFolder:self.currentFolder pageId:nextPage countPerPage:self.currentEntryList.countPerPage];
        }
    }
}

#pragma mark - switch to album list

//- (IBAction)segmentedControlValueChanged:(id)sender {
//    if (self.photoAlbumSwitch.selectedSegmentIndex == 1) {      // Switch to album list view
//        AlbumListController *albumListController = [self.storyboard instantiateViewControllerWithIdentifier:@"AlbumList"];
//
//        albumListController.currentFolder = [[NPFolder alloc] initWithModuleAndFolderId:PHOTO_MODULE
//                                                                                 folderId:0
//                                                                               accessInfo:self.currentFolder.accessInfo];
//
//        NSMutableArray *controllers = [[NSMutableArray alloc] init];
//        
//        for (UIViewController *controller in self.navigationController.viewControllers) {
//            [controllers addObject:controller];
//            if ([controller isKindOfClass:[DashboardController class]]) {
//                break;
//            }
//        }
//        
//        [controllers addObject:albumListController];
//        [self.navigationController setViewControllers:controllers animated:YES];
//    }
//}

- (void)createNewEntry {    
    ELCAlbumPickerController *albumPickerController = [[ELCAlbumPickerController alloc] init];
	NPImagePickerNavigationController *imagePickerController = [[NPImagePickerNavigationController alloc] initWithRootViewController:albumPickerController];
    
    albumPickerController.parent = imagePickerController;
    imagePickerController.imagePickerDelegate = self;
    
    [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];
}


- (IBAction)addPhotoAction:(id)sender {
    if (self.allowUploading) {
        [self createNewEntry];
    } else {
        [ViewDisplayHelper displayOutOfSpaceMessage];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowAlbumList"]) {
        AlbumListController *albumListController = (AlbumListController*)segue.destinationViewController;
        albumListController.currentFolder = [self.currentFolder copy];
        albumListController.folderNavigationItems = [self.folderNavigationItems mutableCopy];
        
    } else if ([segue.identifier isEqualToString:@"OpenUploader"]) {
        PhotoUploadViewController *uploadViewController = (PhotoUploadViewController*)[segue destinationViewController];
        [uploadViewController setAssetArrayWithDestination:[[NSMutableArray alloc] initWithArray:sender] destination:self.currentFolder];

    } else if ([segue.identifier isEqualToString:@"OpenLightbox"]) {
        LightboxViewController *lightboxController = (LightboxViewController*)segue.destinationViewController;
        NPPhoto *selectedPhoto = (NPPhoto*)sender;

        NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];
        scrollIndex.currentIndex = selectedPhoto.displayIndex;
        scrollIndex.totalCount = self.currentEntryList.entries.count;
        lightboxController.scrollIndex = scrollIndex;
        
        lightboxController.navigationDelegate = self;
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];            // In EntryListController, hideBackButton is set to YES

    // Photos has custom toolbar in order to fit the switch
    self.navigationController.toolbarHidden = YES;

    self.photoAlbumSwitch.selectedSegmentIndex = 0;
    
    CGRect rect = self.entryCollectionView.frame;
    rect.origin.x = 12.0;
    rect.origin.y = 44.0;
    rect.size.height = 44.0;

    if (self.emptyListLabel == nil) {
        self.emptyListLabel = [[UILabel alloc] init];
        if (self.currentFolder.folderId == ROOT_FOLDER) {
            self.emptyListLabel.text = NSLocalizedString(@"No photo has been uploaded.",);
        } else {
            self.emptyListLabel.text = NSLocalizedString(@"No photos in this folder.",);
        }

        self.emptyListLabel.textColor = [UIColor lightGrayColor];
    }
    self.emptyListLabel.frame = rect;
    
    if (self.currentEntryList == nil) {
        [self retrieveEntryList];
    }
    
    if (![NPService isServiceAvailable]) {
        [ViewDisplayHelper displayWarningMessage:NSLocalizedString(@"No Internet connection",)
                                         message:NSLocalizedString(@"Connect to the Internet to view photos",)];
        
    } else {
        // Check if there is any space left
        AccountService *acctService = [[AccountService alloc] init];
        [acctService checkSpaceUsage:self.currentFolder.accessInfo.owner completion:^(BOOL spaceLeft) {
            if (!spaceLeft) {
                self.allowUploading = NO;
            } else {
                self.allowUploading = YES;
            }
        }];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }
    
    self.entryCollectionView.delegate = self;
    self.entryCollectionView.dataSource = self;
    
    self.photoSearchBar = [[UISearchBar alloc] init];
    self.photoSearchBar.placeholder = NSLocalizedString(@"Search",);
    [self.photoSearchBar setTranslucent:YES];
    self.photoSearchBar.delegate = self;

    [self initPullRefresh:self.entryCollectionView];
    
    // Make a copy of the toolbar items
    self.toolbarItemsLoadedInStoryboard = [[NSMutableDictionary alloc] initWithCapacity:5];
    for (UIBarButtonItem *item in self.bottomBar.items) {
        if (item.tag != 0) {
            [self.toolbarItemsLoadedInStoryboard setObject:item forKey:[NSString stringWithFormat:@"%li", (long)item.tag]];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePhotoAddedNotification:) name:N_ENTRY_ADDED object:nil];
    
    // Notification from NPService BackgroundUploader
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceDataRefresh:) name:N_DATA_REFRESHED object:nil];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_DATA_REFRESHED object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    
    self.childFolderPhotoListController = nil;
}

// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *spacer = [UIBarButtonItem spacer];
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:spacer];
//        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
//        [items addObject:spacer];
        
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }
        
    } else {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:spacer];
//        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
//        [items addObject:spacer];

        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }

    [self.bottomBar setItems:items];
    [self.bottomBar layoutIfNeeded];        // Has to do this here since the buttons will be out of place after dismissing the image picker.
}

- (void)cleanupData {
    [super cleanupData];
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
}

- (BOOL)didRotate:(NSNotification *)notification {
    if ([super didRotate:notification]) {
        [self.entryCollectionView reloadData];
        return YES;
    }
    return NO;
}


#pragma mark ELCImagePicker Delegate Methods

// Handles picking photos
- (void)didFinishPickingMediaWithInfo:(NSArray *)selectedAssets {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"OpenUploader" sender:selectedAssets];
}

- (void)didCancelImagePicker {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// Handles taking photo from camera
- (void)didFinishTakingPhoto:(UIImage*)image metaData:(NSDictionary*)metaData; {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [self showActivityBar];

    dispatch_queue_t bgUploadQ = dispatch_queue_create("com.nexusapp.BackgroundUploader", NULL);
    dispatch_async(bgUploadQ, ^{
        [[NPUploadHelper instance] uploadImage:image metaData:(NSDictionary*)metaData destination:self.currentFolder];
    });
}

- (void)handlePhotoAddedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPPhoto class]]) {
        DLog(@"Handles new photo added notification.");
        NPPhoto *newPhoto = (NPPhoto*)notification.object;
        [self.currentEntryList addToTopOfList:newPhoto];
        [self.entryCollectionView reloadData];
        [self hideActivityBar];

    } else {
        DLog(@"Cannot handle notification. The notification object is not the Photo type.");
    }
}


// Handle notification from BackgroundUploader
- (void)handleServiceDataRefresh:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        DLog(@"Handles data refresh notification from NPService BackgroundUploader.");

        NPFolder *folder = (NPFolder*)notification.object;
        if (folder.moduleId == PHOTO_MODULE) {
            [self retrieveEntryList];
        }
        
        [self hideActivityBar];
    }
}

@end
