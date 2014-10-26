//
//  FolderUpdaterController.h
//  nexuspad
//
//  Created by Ren Liu on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderService.h"
#import "FolderViewController.h"
#import "FolderUpdaterControllerDelegate.h"
#import "AccountManager.h"
#import "MLPAutoCompleteTextField.h"

@interface FolderUpdaterController : UIViewController <NPDataServiceDelegate,
                                                        FolderViewControllerDelegate,
                                                        UIActionSheetDelegate,
                                                        UITableViewDataSource,
                                                        UITableViewDelegate,
                                                        UITextFieldDelegate>

@property BOOL startAtSharing;

@property (nonatomic, weak) id<FolderUpdaterControllerDelegate> delegate;

@property (nonatomic, strong) NPFolder *parentFolder;
@property (nonatomic, strong) NPFolder *currentFolder;

@end
