//
//  AlbumCollectionViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/16/13.
//
//

#import <UIKit/UIKit.h>
#import "NPAlbum.h"
#import "EntryService.h"
#import "ELCAlbumPickerController.h"
#import "NPImagePickerNavigationController.h"
#import "EntryLightboxViewDelegate.h"
#import "EntryEditorUpdateDelegate.h"
#import "LightboxViewController.h"
#import "PhotoUploadViewController.h"
#import "NPAlbum.h"
#import "EntryViewInfoDelegate.h"
#import "FolderViewController.h"


@interface AlbumCollectionViewController : UICollectionViewController
                                            <UIActionSheetDelegate,
                                            NPDataServiceDelegate,
                                            NPImagePickerControllerDelegate,
                                            EntryLightboxViewDelegate,
                                            EntryEditorUpdateDelegate,
                                            EntryViewInfoDelegate,
                                            FolderViewControllerDelegate>


@property (nonatomic, strong) NPAlbum *album;

@property (nonatomic, strong) EntryService *entryService;

@end
