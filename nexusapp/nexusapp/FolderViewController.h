//
//  FolderViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FolderService.h"
#import "NPUser.h"
#import "SWTableViewCell.h"

typedef enum {ForListing, ForMoving, ForEntrySaving} FolderViewingPurpose;

@protocol FolderViewControllerDelegate <NSObject>
- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction;
@end

@interface FolderViewController : UIViewController <NPDataServiceDelegate,
                                                    UIActionSheetDelegate,
                                                    UITableViewDataSource,
                                                    UITableViewDelegate,
                                                    SWTableViewCellDelegate>

// We need this because for listing it's push into the navigation follow
// For moving, it is a pop view controller
@property (nonatomic) FolderViewingPurpose purpose;

// When open the folder view controller for moving, we use this to assist UI.
@property (strong, nonatomic) NSArray *foldersCannotMoveInto;

@property (nonatomic, weak) id<FolderViewControllerDelegate> folderViewDelegate;

- (void)showFolderTree:(NPFolder*)fromFolder;

@end
