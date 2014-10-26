//
//  AlbumCollectionViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/16/13.
//
//
#import <QuartzCore/QuartzCore.h>

#import "AlbumCollectionViewController.h"
#import "ViewDisplayHelper.h"
#import "ActionResult.h"
#import "NotificationUtil.h"
#import "NPServiceNotificationUtil.h"
#import "EmailEntryViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "NPUploadHelper.h"
#import "DoAlertView.h"
#import "AccountService.h"


@interface AlbumCollectionViewController ()
@property (nonatomic, strong) UILabel *emptyListLabel;
@property BOOL allowUploading;
@end

@implementation AlbumCollectionViewController

@synthesize album = _album;


// Overwrite EntryViewController method
- (NPEntry*)getCurrentEntry {
    return _album;
}

- (void)setAlbum:(NPAlbum *)anAlbum {
    _album = anAlbum;
}

// Photo list is unique because each Media object also carries an index for lightbox nevigation.
// In this callback we convert entryList element from NPEntry to Media object.
- (void)updateServiceResult:(id)serviceResult {
    if ([serviceResult isKindOfClass:[NPEntry class]]) {
        _album = [NPAlbum albumFromEntry:serviceResult];
        
        if ([_album.attachments count] == 0) {
            [self.collectionView addSubview:self.emptyListLabel];

        } else {
            [self.emptyListLabel removeFromSuperview];
            [self.collectionView reloadData];
        }
        
        self.navigationItem.title = self.album.title;
    
    } else if ([serviceResult isKindOfClass:[ActionResult class]]) {
        ActionResult *action = (ActionResult*)serviceResult;
        
        if ([action isUpdateEntry]) {                                           // Update album - delete a photo
            
            // This code is commented out because the timing of the service result is not reliable for lightbox to
            // display the "next" photo after deleting one. Basically a index is returned to lightbox in deleteEntryAtIndex, and lightbox
            // use that index to seek the photo to display. Since _album.attachment might or might not get updated, there is no good way
            // to return the correct photo.

//            _album = [NPAlbum albumFromEntry:[action getEntryActionResult]];
//            if (_album.attachments.count == 0) {
//                [self.collectionView addSubview:self.emptyListLabel];
//                
//            } else {
//                [self.emptyListLabel removeFromSuperview];
//                [self.collectionView reloadData];
//            }
            
        } else if ([action isDeleteEntry]) {                                    // Delete album
            _album.status = ENTRY_STATUS_DELETED;
            [NotificationUtil sendEntryDeletedNotification:self.album];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    // remove the spinner from the scene
    [ViewDisplayHelper dismissWaiting:self.view];
}

- (void)serviceError:(id)serviceResult {
    
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
    if (forAction == ForMoving) {
        NPEntry *movedEntry = [self getCurrentEntry];
        movedEntry.folder.folderId = selectedFolder.folderId;
        [self.entryService moveEntry:movedEntry];
        [NotificationUtil sendEntryMovedNotification:movedEntry];
        [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
    }
}


#pragma mark - UICollectionView delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _album.attachments.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"PhotoCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *aImageView = (UIImageView *)[cell viewWithTag:100];
    
    aImageView.layer.cornerRadius = 4;
    aImageView.layer.borderColor = [[UIColor grayColor] colorWithAlphaComponent:0.25f].CGColor;
    aImageView.layer.borderWidth = 1.0;
    aImageView.contentMode = UIViewContentModeScaleAspectFill;
    aImageView.clipsToBounds = YES;
    
    aImageView.userInteractionEnabled = YES;
    
    NPUpload *photo = [_album.attachments objectAtIndex:indexPath.row];
    NSString *tnImageUrl = [NPWebApiService appendAuthParams:photo.tnUrl];

    [aImageView sd_setImageWithURL:[NSURL URLWithString:tnImageUrl]
                  placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                             photo.thumbnailImage = image;
                         }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NPUpload *selectedPhoto = [self.album.attachments objectAtIndex:indexPath.row];
    selectedPhoto.accessInfo = [self.album.accessInfo copy];
    [self performSegueWithIdentifier:@"OpenLightbox" sender:selectedPhoto];
}

- (IBAction)deleteEntry:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete the whole album?",)
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                                    otherButtonTitles:nil];
    
    [actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (index == sender.destructiveButtonIndex) {
        [self.entryService deleteEntry:self.album];
        
    } else if (index == sender.cancelButtonIndex) {
        [sender dismissWithClickedButtonIndex:index animated:YES];
    }
}

- (IBAction)openImagePicker:(id)sender {
    if (self.allowUploading) {
        ELCAlbumPickerController *albumPickerController = [[ELCAlbumPickerController alloc] init];
        NPImagePickerNavigationController *imagePickerController = [[NPImagePickerNavigationController alloc] initWithRootViewController:albumPickerController];
        
        albumPickerController.parent = imagePickerController;
        imagePickerController.imagePickerDelegate = self;
        
        [self.navigationController presentViewController:imagePickerController animated:YES completion:nil];;
        
    } else {
        [ViewDisplayHelper displayOutOfSpaceMessage];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenAlbumPhotoUploader"]) {
        PhotoUploadViewController *uploadViewController = (PhotoUploadViewController*)[segue destinationViewController];
        [uploadViewController setAssetArrayWithDestination:[[NSMutableArray alloc] initWithArray:sender] destination:self.album];
        
    } else if ([segue.identifier isEqualToString:@"OpenLightbox"]) {
        LightboxViewController *lightboxController = (LightboxViewController*)segue.destinationViewController;
        lightboxController.isAlbumPhoto = YES;
        NPUpload *selectedPhoto = (NPUpload*)sender;
        
        NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];
        scrollIndex.currentIndex = selectedPhoto.displayIndex;
        scrollIndex.totalCount = _album.attachments.count;
        lightboxController.scrollIndex = scrollIndex;
        
        lightboxController.navigationDelegate = self;
    }
}

#pragma mark ELCImagePicker Delegate Methods

- (void)didFinishPickingMediaWithInfo:(NSArray *)selectedAssets
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"OpenAlbumPhotoUploader" sender:selectedAssets];
}

- (void)didFinishTakingPhoto:(UIImage*)image metaData:(NSDictionary*)metaData {
    [[NPUploadHelper instance] uploadImage:image metaData:metaData destination:_album];
}

- (void)didCancelImagePicker
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - EntryViewPrevNextDelegate

- (id)getEntryAtIndex:(NSInteger)index {
    if (index < 0) {
        return nil;
    } else if (index >= [self.album.attachments count]) {
        // Return to the first photo in the album
        return [self.album.attachments objectAtIndex:0];
    }

    return [self.album.attachments objectAtIndex:index];
}

#pragma mark - EntryLightboxViewDelegate

// EntryLightboxViewDelegate to delete entry
// called from Lightbox
- (NPScrollIndex*)deleteEntryAtIndex:(NSInteger)indexToDelete {
    NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];
    
    if (_album.attachments.count > indexToDelete && [_album.attachments objectAtIndex:indexToDelete]) {
        NPUpload *deletedAtt = [_album.attachments objectAtIndex:indexToDelete];

        // remove it from the current array and reload collection view
        NSMutableArray *tmpAttachments = [NSMutableArray arrayWithArray:self.album.attachments];
        [tmpAttachments removeObjectAtIndex:indexToDelete];
        _album.attachments = [NSArray arrayWithArray:tmpAttachments];
        
        [self.collectionView reloadData];
        
        // re-assign the displayIndex for each attachment
        int i = 0;
        for (NPUpload *att in _album.attachments) {
            att.displayIndex = i;
            i++;
        }
        
        if (_album.attachments.count == 0) {
            [self.collectionView addSubview:self.emptyListLabel];
        }

        scrollIndex.totalCount = _album.attachments.count;

        if (indexToDelete > _album.attachments.count - 1) {         // The last photo is deleted
            scrollIndex.currentIndex = 0;
        } else {
            scrollIndex.currentIndex = indexToDelete;               // Move to next entry
        }

        // make service call to delete it
        [self.entryService deleteAttachment:deletedAtt];            // updateServiceResult handles refresh

        // TODO
        // If we delete the first photo in an album, the album cover photo should be refreshed, and
        // AlbumListController needs to be notified to refresh the list with the new cover photo.

    } else {
        scrollIndex.totalCount = _album.attachments.count;
        scrollIndex.currentIndex = 0;
    }
    
    return scrollIndex;
}


- (IBAction)openEmailEntry:(id)sender {
    UIStoryboard *shareStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_share" bundle:nil];
    EmailEntryViewController* emailEntryController = [shareStoryBoard instantiateViewControllerWithIdentifier:@"EmailEntryView"];
    NPEntry *theEntry = [[NPEntry alloc] init];
    theEntry.folder.moduleId = PHOTO_MODULE;
    theEntry.folder.folderId = _album.folder.folderId;
    theEntry.entryId = [_album.entryId copy];
    theEntry.templateId = _album.templateId;
    emailEntryController.theEntry = theEntry;
    emailEntryController.promptDelegate = self;
    [self.navigationController pushViewController:emailEntryController animated:YES];
}

- (void)updatePrompt:(NSString*)promptMessage {
    // Do nothing here.
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];            // In EntryListController, hideBackButton is set to YES
    self.navigationItem.hidesBackButton = NO;   // Need to show the back navigation button when displaying album photos
    self.navigationController.toolbarHidden = NO;
    
    CGRect rect = self.collectionView.frame;
    rect.origin.x = 12.0;
    rect.origin.y = 10.0;
    rect.size.height = 44.0;

    if (self.emptyListLabel == nil) {
        self.emptyListLabel = [[UILabel alloc] init];
        self.emptyListLabel.text = NSLocalizedString(@"No photo in this album.",);
        self.emptyListLabel.textColor = [UIColor lightGrayColor];
    }
    self.emptyListLabel.frame = rect;
    
    if (![NPService isServiceAvailable]) {
        [ViewDisplayHelper displayWarningMessage:NSLocalizedString(@"No Internet connection",)
                                         message:NSLocalizedString(@"Connect to the Internet to view photos",)];
    } else {
        // Check if there is any space left
        AccountService *acctService = [[AccountService alloc] init];
        [acctService checkSpaceUsage:_album.accessInfo.owner completion:^(BOOL spaceLeft) {
            if (!spaceLeft) {
                self.allowUploading = NO;
            } else {
                self.allowUploading = YES;
            }
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.entryService == nil) {
        self.entryService = [[EntryService alloc] init];
        self.entryService.accessInfo = [_album.accessInfo copy];
    }
    
    self.entryService.serviceDelegate = self;
    
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    
    [self.entryService getEntryDetail:_album];
    
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
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.album = nil;
}


#pragma mark - notification handlings

- (void)handlePhotoAddedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPAlbum class]]) {
        DLog(@"Handles new photo added notification. Refresh the album.");
        NPAlbum *updatedAlbum = (NPAlbum*)notification.object;
        
        _album = [updatedAlbum copy];
        
        // This needs to be done for a new album since the "empty" message is still there.
        if (_album.attachments.count > 0) {
            [self.emptyListLabel removeFromSuperview];
        }
        
        [self.collectionView reloadData];
        
        // Now send a notification to AlbumListController to refresh the thumbnail
        [NotificationUtil sendEntryUpdatedNotification:updatedAlbum];
        
    } else {
        DLog(@"Cannot handle notification. The notification object is not the Album type.");
    }
    
}


// Handle notification from BackgroundUploader
- (void)handleServiceDataRefresh:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        DLog(@"Handles data refresh notification from NPService BackgroundUploader.");
        
        NPAlbum *entry = (NPAlbum*)notification.object;
        if (entry.folder.moduleId == PHOTO_MODULE) {
            [self.entryService getEntryDetail:_album];
        }
    }
}

@end
