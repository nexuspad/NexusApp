//
//  EntryViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntryService.h"
#import "LayoutConstants.h"
#import "ClickableItemListCell.h"
#import "EntryEditorUpdateDelegate.h"
#import "NotificationUtil.h"
#import "ViewDisplayHelper.h"
#import "NSString+NPStringUtil.h"
#import "EntryViewInfoDelegate.h"
#import "FolderViewController.h"


@interface EntryDetailTableViewController : UITableViewController <EntryEditorUpdateDelegate,
                                                        NPDataServiceDelegate,
                                                        UIActionSheetDelegate,
                                                        EntryViewInfoDelegate,
                                                        FolderViewControllerDelegate>

@property (nonatomic, strong) EntryService *entryService;
@property (nonatomic, strong) NSMutableDictionary *toolbarItemsLoadedInStoryboard;

- (void)callDeleteService;

- (void)updateServiceResult:(id)responseObj;

- (NPEntry*)getCurrentEntry;

- (void)setEntryToolbarItems;

@end
