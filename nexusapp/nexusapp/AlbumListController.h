//
//  AlbumListController.h
//  nexuspad
//
//  Created by Ren Liu on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryListFolderViewController.h"
#import "ELCAlbumPickerController.h"
#import "NPImagePickerNavigationController.h"
#import "NPPhoto.h"

@interface AlbumListController : EntryListFolderViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *photoAlbumSwitch;
- (IBAction)segmentedControlValueChanged:(id)sender;

@end
