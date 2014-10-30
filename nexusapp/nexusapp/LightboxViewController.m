//
//  LightboxViewController.m
//  nexuspad
//
//  Created by Ren Liu on 6/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LightboxViewController.h"
#import "NPModule.h"
#import "NotificationUtil.h"
#import "ViewDisplayHelper.h"
#import "EmailEntryViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "LightboxPhotoView.h"
#import "EntryActionResult.h"

@interface LightboxViewController ()
@property (nonatomic, strong) NSMutableDictionary *photoViews;
@end

@implementation LightboxViewController

@synthesize navigationDelegate, scrollIndex = _scrollIndex, photoScrollView = _photoScrollView, photoViews = _photoViews, isAlbumPhoto;

// This is only used for opening the folder selector
// The object returned must be NPPhoto since it makes no sense to move NPUpload object
- (NPPhoto*)getCurrentEntry {
    return [self.navigationDelegate getEntryAtIndex:[self getActivePhotoIndex]];
}

// This calls the delegate to get the entry to be displayed in the Lightbox
// The delegate can either be PhotoListController or AlbumCollectionViewController so the returned object
// can be either NPPhoto or NPUpload, so we need to check the class type to return the proper one.
- (NPUpload*)getUploadObjectForEntryAtIndex:(NSInteger)index {
    id entryAtIndex = [self.navigationDelegate getEntryAtIndex:index];

    if ([entryAtIndex isKindOfClass:[NPPhoto class]]) {
        NPPhoto *photo = (NPPhoto*)entryAtIndex;
        return photo.uploadImage;
    } else if ([entryAtIndex isKindOfClass:[NPUpload class]]) {
        return entryAtIndex;
    }
    return nil;
}

- (IBAction)deleteEntry:(id)sender
{    
    NSString *message = [NSLocalizedString(@"Are you sure you want to delete this",)
                         stringByAppendingFormat:@" %@?", [NPModule getModuleEntryName:PHOTO_MODULE templateId:601]];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                                    otherButtonTitles:nil];
    
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index {
    if (index == sender.destructiveButtonIndex) {
        // Create some animation
        UIView *view = [_photoScrollView activePage];
        [UIView transitionWithView:view duration:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            view.alpha = 0;
            
        } completion:^(BOOL finished) {
            NSInteger indexToDelete = [self currentActivePhotoIndex];
            _scrollIndex = [self.navigationDelegate deleteEntryAtIndex:indexToDelete];
            
            if ([_photoViews objectForKey:@(indexToDelete)] != nil) {
                LightboxPhotoView *deletedView = (LightboxPhotoView*)[_photoViews objectForKey:@(indexToDelete)];
                [deletedView cleanup];
                [_photoViews removeObjectForKey:@(indexToDelete)];
            }
            
            // The last photo has been deleted
            if (_scrollIndex.totalCount == 0) {
                [self.navigationController popViewControllerAnimated:YES];
                
            } else {
                [self initPhotoScrollView];
            }
        }];
        
    } else if (index == sender.cancelButtonIndex) {
        [sender dismissWithClickedButtonIndex:index animated:YES];
    }
}

- (void)updateServiceResult:(id)serviceResult {
    
}

- (void)serviceError:(id)serviceResult {
    
}

- (void)handleEntryAvailableNotification:(NSNotification*)notification {
    _scrollIndex = (NPScrollIndex*)notification.object;
    DLog(@"Received attachment available notification: index: %li, total: %li", (long)_scrollIndex.currentIndex, (long)_scrollIndex.totalCount);
}

- (NSInteger)currentActivePhotoIndex {
    UIView *view = [_photoScrollView activePage];
    return view.tag;
}

// aPhoto should be a local object copy already
- (LightboxPhotoView*)getOrRefreshPhotoView:(NSInteger)displayIndex photo:(NPUpload*)aPhoto {
    if (_photoViews == nil) {
        _photoViews = [[NSMutableDictionary alloc] init];
    } else {
        [self cleanupViews];
    }

    if ([_photoViews objectForKey:@(displayIndex)] != nil) {
        DLog(@"Photo view for index %li is available", (long)displayIndex);
        return [_photoViews objectForKey:@(displayIndex)];
    } else {
        CGRect rect = self.view.frame;
        rect.origin.y = 0;
        LightboxPhotoView *photoView = [[LightboxPhotoView alloc] initWithFrameAndUrl:rect imageUpload:aPhoto];
        photoView.tag = displayIndex;
        
        [_photoViews setObject:photoView forKey:@(displayIndex)];
        return photoView;
    }
}


- (void)cleanupViews {
    // clear left
    NSInteger leftOne = _scrollIndex.currentIndex - 2;
    if (leftOne > 0) {
        for (NSInteger n=leftOne; n>0; n--) {
            if ([_photoViews objectForKey:@(n)] != nil) {
                LightboxPhotoView *leftView = (LightboxPhotoView*)[_photoViews objectForKey:@(n)];
                [leftView cleanup];
                [_photoViews removeObjectForKey:@(n)];
            }
        }
    }

    // clear right
    NSInteger rightOne = _scrollIndex.currentIndex + 2;
    for (NSInteger n=rightOne; n<_scrollIndex.totalCount; n++) {
        if ([_photoViews objectForKey:@(n)] != nil) {
            LightboxPhotoView *rightView = (LightboxPhotoView*)[_photoViews objectForKey:@(n)];
            [rightView cleanup];
            [_photoViews removeObjectForKey:@(n)];
        }
    }
}

// The currentIndex is the index we move into
// The leftIndex will be added to the left to maintain 3 page rotation.
- (id)getLeftPageView:(NSInteger)currentIndex {
    DLog(@"Display photo at index %li", (long)currentIndex);
    
    _scrollIndex.currentIndex = currentIndex;
    
    // Get the image for current index and refresh the image view
    NPUpload *aPhoto = [self getUploadObjectForEntryAtIndex:currentIndex];
    [self getOrRefreshPhotoView:currentIndex photo:[aPhoto copy]];
    
    NSInteger previousIndex = currentIndex - 1;
    
    if (previousIndex < 0) {
        return nil;
        
    } else {
        NPUpload *leftPhoto = [self getUploadObjectForEntryAtIndex:previousIndex];
        return [self getOrRefreshPhotoView:previousIndex photo:[leftPhoto copy]];
    }
}

// The currentIndex is the index we move into
// The nextIndex will be added to the right to maintain 3 page rotation.
- (id)getRightPageView:(NSInteger)currentIndex {
    DLog(@"Display photo at index %li", (long)currentIndex);
    
    _scrollIndex.currentIndex = currentIndex;
    
    // Get the image for current index and refresh the image view
    NPUpload *aPhoto = [self getUploadObjectForEntryAtIndex:currentIndex];
    [self getOrRefreshPhotoView:currentIndex photo:[aPhoto copy]];
    
    NSInteger nextIndex = currentIndex + 1;
    NPUpload *rightPhoto = [self getUploadObjectForEntryAtIndex:nextIndex];
    
    if (rightPhoto == nil) {    // No more on the right, this only happens when there are two photos in total.
        return nil;
        
    } else {
        // Notice that we use rightPhoto.displayIndex here, instead of "nextIndex" because nextIndex could be
        // out of bound. In that case, we need to use the proper index (like 0).
        return [self getOrRefreshPhotoView:rightPhoto.displayIndex photo:[rightPhoto copy]];
    }
}

- (void)initPhotoScrollView {
    DLog(@"Display photo at index: %li", (long)_scrollIndex.currentIndex);

    NSMutableArray *initialPages = [[NSMutableArray alloc] initWithCapacity:3];

    // TODO - use constraints instead of frame
    CGRect rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
    
    if (_scrollIndex.totalCount == 1) {
        NPUpload *upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:0];
        LightboxPhotoView *unoPhoto = [self getOrRefreshPhotoView:0 photo:[upload copy]];
        _photoScrollView = [[NPScrollView alloc] initWithOnePage:rect pageView:unoPhoto backgroundColor:[UIColor blackColor]];

    } else if (_scrollIndex.totalCount == 2) {
        if (_scrollIndex.currentIndex == 0) {
            NPUpload *upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:0];
            [initialPages addObject:[self getOrRefreshPhotoView:0 photo:[upload copy]]];
            
            upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:1];
            [initialPages addObject:[self getOrRefreshPhotoView:1 photo:[upload copy]]];
            
            _photoScrollView = [[NPScrollView alloc] initWithTwoPages:rect pageViews:initialPages startingIndex:0 backgroundColor:[UIColor blackColor]];
            
        } else {
            NPUpload *upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:0];
            [initialPages addObject:[self getOrRefreshPhotoView:0 photo:[upload copy]]];
            
            upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:1];
            [initialPages addObject:[self getOrRefreshPhotoView:1 photo:[upload copy]]];
            
            _photoScrollView = [[NPScrollView alloc] initWithTwoPages:rect pageViews:initialPages startingIndex:1 backgroundColor:[UIColor blackColor]];
        }
        
        _photoScrollView.dataDelegate = self;
        
    } else {
        if (_scrollIndex.currentIndex == 0) {
            NPUpload *upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:0];
            [initialPages addObject:[self getOrRefreshPhotoView:0 photo:[upload copy]]];
            
            upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:1];
            [initialPages addObject:[self getOrRefreshPhotoView:1 photo:[upload copy]]];

        } else {
            NPUpload *upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:_scrollIndex.currentIndex-1];
            [initialPages addObject:[self getOrRefreshPhotoView:(_scrollIndex.currentIndex-1) photo:[upload copy]]];
            
            upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:_scrollIndex.currentIndex];
            [initialPages addObject:[self getOrRefreshPhotoView:_scrollIndex.currentIndex photo:[upload copy]]];
            
            upload = (NPUpload*)[self getUploadObjectForEntryAtIndex:_scrollIndex.currentIndex+1];
            [initialPages addObject:[self getOrRefreshPhotoView:(_scrollIndex.currentIndex+1) photo:[upload copy]]];
        }
        
        _photoScrollView = [[NPScrollView alloc] initWithPageViews:rect pageViews:initialPages startingIndex:_scrollIndex.currentIndex backgroundColor:[UIColor blackColor]];
        _photoScrollView.dataDelegate = self;
    }

    [self.view addSubview:_photoScrollView];
}


- (IBAction)openEmailEntry:(id)sender
{
    UIStoryboard *shareStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_share" bundle:nil];
    EmailEntryViewController* emailEntryController = [shareStoryBoard instantiateViewControllerWithIdentifier:@"EmailEntryView"];
    NPPhoto *emailPhoto = [[NPPhoto alloc] init];
    emailPhoto.folder.moduleId = PHOTO_MODULE;
    
    NPUpload *photo = [self getUploadObjectForEntryAtIndex:[self getActivePhotoIndex]];
    
    emailPhoto.folder.folderId = photo.parentEntryFolder;
    emailPhoto.entryId = [NSString stringWithString:photo.parentEntryId];
    
    emailEntryController.theEntry = [emailPhoto copy];
    emailEntryController.promptDelegate = self;
    [self.navigationController pushViewController:emailEntryController animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.toolbarHidden = NO;
    
    if (self.isAlbumPhoto) {
        if (self.toolbarItems.count == 5) {
            NSMutableArray *barItems = [self.toolbarItems mutableCopy];
            [barItems removeObjectAtIndex:0];
            [barItems removeObjectAtIndex:0];
            self.toolbarItems = barItems;
        }
    }
    
    [self initPhotoScrollView];
    
    // Single tap hides the bars
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singleTap];

    // Handles single tap only, double tap zooms in the image, so when there is double tap, we don't want to hide the bars.
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
}

/*
 * Hide the bars on single tap
 */
- (void)handleSingleTap:(UITapGestureRecognizer *)gesture
{
    [UIView beginAnimations: nil context:NULL];
    [UIView setAnimationDuration:0.4];
    [UIView setAnimationDelegate: self];
    
    CGRect rect = self.navigationController.navigationBar.frame;
    
    if (rect.origin.y < 0) {
        rect.origin.y += 88;
        self.navigationController.navigationBar.frame = rect;
        
        rect = self.navigationController.toolbar.frame;
        rect.origin.y -= 88;
        self.navigationController.toolbar.frame = rect;
        
    } else {
        rect.origin.y -= 88;
        self.navigationController.navigationBar.frame = rect;
        
        rect = self.navigationController.toolbar.frame;
        rect.origin.y += 88;
        self.navigationController.toolbar.frame = rect;
        
    }
    
    [UIView commitAnimations];
}


- (void)handleDoubleTap:(UITapGestureRecognizer *)gesture
{
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryAvailableNotification:) name:N_ENTRY_AVAILABLE object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (NSInteger)getActivePhotoIndex {
    if (_photoScrollView == nil) {
        return 0;
    }
    
    UIView *view = [_photoScrollView activePage];
    return view.tag;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [_photoScrollView removeFromSuperview];

    // Force recreate the lightbox views to fit the new orientation
    _photoViews = nil;
    
    [self initPhotoScrollView];
}


#pragma mark - open folders

- (IBAction)openFolderSelector:(id)sender {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        
        NPEntry *entry = [self getCurrentEntry];
        
        folderViewController.purpose = ForMoving;
        folderViewController.foldersCannotMoveInto = [NSArray arrayWithObject:[NSNumber numberWithInt:entry.folder.folderId]];

        NPFolder *entryFolder = [[NPFolder alloc] initWithModuleAndFolderId:entry.folder.moduleId folderId:entry.folder.folderId accessInfo:entry.accessInfo];
        
        [folderViewController showFolderTree:entryFolder];
        folderViewController.folderViewDelegate = self;

        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    NPEntry *movedEntry = [self getCurrentEntry];
    movedEntry.folder.folderId = selectedFolder.folderId;
    
    EntryService *entryService = [[EntryService alloc] init];

    [entryService moveEntry:movedEntry];
    [NotificationUtil sendEntryMovedNotification:movedEntry];
    
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
}

@end
