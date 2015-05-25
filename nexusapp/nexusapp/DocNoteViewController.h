//
//  DocNoteViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "EntryDetailViewController.h"
#import <WordPress-iOS-Editor/WPEditorViewController.h>

#import "NPDoc.h"

@interface DocNoteViewController : WPEditorViewController <WPEditorViewControllerDelegate,
                                                        UICollectionViewDelegate,
                                                        UICollectionViewDataSource,
                                                        UIGestureRecognizerDelegate,
                                                        NPDataServiceDelegate,
                                                        UIActionSheetDelegate,
                                                        FolderViewControllerDelegate>

@property (nonatomic, strong) NPFolder *entryFolder;
@property (nonatomic, strong) NPDoc *doc;

@end
