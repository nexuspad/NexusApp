//
//  EntryEditorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BasicItemInputCell.h"
#import "EntryService.h"
#import "FolderViewController.h"
#import "EntryEditorUpdateDelegate.h"
#import "LayoutConstants.h"
#import "ViewDisplayHelper.h"
#import "EntryActionResult.h"
#import "NSString+NPStringUtil.h"
#import "TextViewWithPlaceHolder.h"
#import "NotificationUtil.h"

@interface EntryEditorTableViewController : UITableViewController
                                   <UIAlertViewDelegate,
                                    InputCellInputTextValueChangeDelegate,          // Change the parent cell dimension
                                    InputValueSelectedDelegate,                     // Assign values from input views
                                    EntryEditorUpdateDelegate,                      // Update NPEntry when values are set in different screens
                                    FolderViewControllerDelegate,
                                    NPDataServiceDelegate>

@property (nonatomic, strong) EntryService *entryService;

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> afterSavingDelegate;

// This must be overridden by the subclass.
- (NPEntry*)currentEditedEntry;

- (void)inputListChanged:(id)sender;

- (IBAction)openFolderView:(id)sender;

// Cancel the editor screen
- (IBAction)cancelEditor:(id)sender;

- (void)setSelectedValue:(id)sender;

- (void)postEntry:(NPEntry*)entry;

@end
