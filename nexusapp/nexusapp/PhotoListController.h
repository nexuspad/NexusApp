//
//  PhotoViewController.h
//  nexuspad
//
//  Created by Ren Liu on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntryListFolderViewController.h"
#import "ELCAlbumPickerController.h"
#import "NPImagePickerNavigationController.h"
#import "EntryLightboxViewDelegate.h"
#import "NPPhoto.h"

@interface PhotoListController : BaseEntryListViewController
                                <UICollectionViewDelegate,
                                 UICollectionViewDataSource,
                                 UISearchBarDelegate,
                                 NPImagePickerControllerDelegate,
                                 EntryLightboxViewDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *photoAlbumSwitch;

- (IBAction)addPhotoAction:(id)sender;
- (IBAction)segmentedControlValueChanged:(id)sender;

@end
