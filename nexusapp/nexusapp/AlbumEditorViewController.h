//
//  AlbumEditorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 9/26/12.
//
//

#import "EntryEditorTableViewController.h"
#import "NPAlbum.h"

@interface AlbumEditorViewController : EntryEditorTableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NPAlbum *album;

@end
