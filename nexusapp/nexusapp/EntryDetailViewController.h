//
//  BaseEntryViewController.h
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
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


@interface EntryDetailViewController : UIViewController <EntryEditorUpdateDelegate,
                                                        EntryViewInfoDelegate,
                                                        FolderViewControllerDelegate,
                                                        NPDataServiceDelegate,
                                                        UIActionSheetDelegate,
                                                        UITableViewDelegate,
                                                        UITableViewDataSource>

@property (nonatomic, strong) EntryService *entryService;
@property (nonatomic, strong) NSMutableDictionary *toolbarItemsLoadedInStoryboard;

- (void)callDeleteService;

- (void)updateServiceResult:(id)responseObj;

- (NPEntry*)getCurrentEntry;

- (void)setEntryToolbarItems;

@end
