//
//  EntryEditorViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import <UIKit/UIKit.h>
#import "EntryEditorUpdateDelegate.h"
#import "FolderViewController.h"
#import "EntryService.h"

@interface EntryEditorViewController : UIViewController
                                        <UIAlertViewDelegate,
                                        EntryEditorUpdateDelegate,        // Update NPEntry when values are set in different screens
                                        FolderViewControllerDelegate,
                                        NPDataServiceDelegate>

@property (nonatomic, strong) NPFolder *entryFolder;

@property (nonatomic, strong) EntryService *entryService;

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> afterSavingDelegate;

- (IBAction)openFolderView:(id)sender;

// Cancel the editor screen
- (IBAction)cancelEditor:(id)sender;

- (void)postEntry:(NPEntry*)entry;

@end
