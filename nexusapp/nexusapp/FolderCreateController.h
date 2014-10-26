//
//  NewFolderController.h
//  nexuspad
//
//  Created by Ren Liu on 8/22/12.
//
//

#import <UIKit/UIKit.h>
#import "FolderService.h"
#import "FolderUpdaterControllerDelegate.h"
#import "AccountManager.h"

@interface FolderCreateController : UIViewController <NPDataServiceDelegate,
                                                        UITableViewDataSource,
                                                        UITableViewDelegate,
                                                        UITextFieldDelegate>

@property (nonatomic, weak) id<FolderUpdaterControllerDelegate> delegate;

@property (nonatomic, strong) NPFolder *theNewFolder;
@property (nonatomic, strong) NPFolder *parentFolder;

@end
