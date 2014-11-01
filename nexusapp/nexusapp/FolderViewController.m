//
//  FolderViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FolderViewController.h"
#import "FolderUpdaterController.h"
#import "FolderCreateController.h"
#import "FolderList.h"
#import "FolderActionResult.h"
#import "UIColor+NPColor.h"
#import "UIBarButtonItem+NPUtil.h"
#import "ViewDisplayHelper.h"
#import "FolderTreeItemCell.h"
#import "NotificationUtil.h"
#import "UIColor+NPColor.h"
#import "UIImageView+WebCache.h"
#import "UserPrefUtil.h"
#import "DoAlertView.h"


@interface FolderViewController ()
@property (nonatomic, strong) FolderService *folderService;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NPFolder *rootFolder;                         // ROOT for folder list
@property (nonatomic, strong) FolderList *folderList;                       // FolderList object returned from FolderService

@property (nonatomic, strong) NSMutableArray *folders;                      // Current folders on the screen
@property (nonatomic, strong) NPFolder *foldersParent;                      // Parent folder of current folders on the screen

@property (nonatomic, strong) NPFolder *selectedFolderInTree;               // The "starting" folder in some cases when folder view is opened

@property (strong, nonatomic) IBOutlet UIBarButtonItem *addNewFolderBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *goUpButton;

@property (strong, nonatomic) UIBarButtonItem *moveHereButton;
@property (strong, nonatomic) UIBarButtonItem *moveHereDisabledButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *closeButtonItem;

@property (nonatomic, strong) DoAlertView *doAlert;

@property BOOL isBeingEditted;

@property (nonatomic, strong) UIView *dragCloseHeaderView;
@property BOOL isBeingDragged;

@property UIInterfaceOrientation currentInterfaceOrientation;

@end

@implementation FolderViewController

@synthesize folderList = _folderList, rootFolder = _rootFolder, foldersParent = _foldersParent, folders = _folders, doAlert = _doAlert;
@synthesize folderViewDelegate = _folderViewDelegate;
@synthesize folderService = _folderService;
@synthesize purpose = _purpose;


//
// Show the folder tree with a starting folder. It can be ROOT, or any folder.
// - If this is the first time folder view is loaded, we need to populate _folderList
// - Make sure to assign the foldersParent
//
// This is usually called externally.
// Use refreshFolderView for FolderViewController internal calls.
//
- (void)showFolderTree:(NPFolder*)fromFolder {
    if (fromFolder.folderId == ROOT_FOLDER) {       // This is usually only called once
        // Make sure the EntryViewController has the same owner.
        // It could have been changed to show sharer's so we need to reload FolderList object.
        if (_rootFolder != nil && _rootFolder.accessInfo.owner.userId != fromFolder.accessInfo.owner.userId) {
            _folderList = nil;
        }
        _rootFolder = [fromFolder copy];

    } else {
        _selectedFolderInTree = [fromFolder copy];
        
        AccessEntitlement *rootAccess = [[AccessEntitlement alloc] initWithOwnerAndViewer:fromFolder.accessInfo.owner
                                                                                theViewer:fromFolder.accessInfo.viewer];
        if ([rootAccess iAmOwner]) {
            rootAccess.write = YES;
        } else {
            rootAccess.write = NO;
        }
        
        // Do not need to create _rootFolder object unless we have to.
        // _rootFolder.accessInfo.owner may have display name for sharer that we want to keep.
        //
        if (_rootFolder == nil) {
            _rootFolder = [NPFolder initRootFolder:fromFolder.moduleId accessInfo:rootAccess];
        }
    }
    
    if (_folderList == nil) {                       // First time the folder tree view controller is loaded
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];
        [self.folderService getAllFolders:_rootFolder.accessInfo];

    } else {                                        // Data is already loaded
        [self refreshFolderView:NO];
    }
}

// This method refresh the folder tree tableview and toolbar and navigation bar
- (void)refreshFolderView:(BOOL)animated {
    [self showSubFolders:[self foldersParent] animated:animated];

    [self updateNavItem];

    if (self.purpose == ForMoving) {
        [self addMoveHereButtonToToolBar];
    }
}

- (NPFolder*)foldersParent {
    if (_foldersParent != nil) {
        return _foldersParent;

    } if (_selectedFolderInTree != nil) {
        int parentId = 0;
        
        if ([_folderList.folderDict objectForKey:[NSNumber numberWithInt:_selectedFolderInTree.folderId]] != nil) {
            NPFolder *f = [self.folderList.folderDict objectForKey:[NSNumber numberWithInt:_selectedFolderInTree.folderId]];
            parentId = f.parentId;
        }
        
        if ([_folderList.folderDict objectForKey:[NSNumber numberWithInt:parentId]] != nil) {
            return [_folderList.folderDict objectForKey:[NSNumber numberWithInt:parentId]];
        }
    }

    return _rootFolder;
}

- (NPFolder*)findFolderParent:(NPFolder*)folder {
    if ([_folderList.folderDict objectForKey:[NSNumber numberWithInt:folder.parentId]] != nil) {
        return [_folderList.folderDict objectForKey:[NSNumber numberWithInt:folder.parentId]];
    }
    return _rootFolder;
}


#pragma mark - Web service delegate

- (void)updateServiceResult:(id)serviceResult {
    // remove the spinner from the scene
    [ViewDisplayHelper dismissWaiting:self.view];

    // Remove the prompt message
    self.navigationItem.prompt = nil;

    if ([serviceResult isKindOfClass:[FolderList class]]) {                // Folder list result
        self.folderList = (FolderList*)serviceResult;
        [self refreshFolderView:NO];
        
    } else if ([serviceResult isKindOfClass:[FolderActionResult class]]) {
        FolderActionResult *actionResponse = (FolderActionResult*)serviceResult;
        if ([actionResponse.name isEqualToString:ACTION_DELETE_FOLDER] || [actionResponse.name isEqualToString:@"unshare_folder"]) {
            DLog(@"Folder is successfully deleted or unshared.");
            [NotificationUtil sendFolderDeletedNotification:actionResponse.folder];
        }
    }
}


- (void)serviceError:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
}


#pragma mark - handles different types of folder operation notifications

/*
 * Handle adding
 */
- (void)handleFolderAddedNotification:(NSNotification*)notification {
    NPFolder *parentFolder = [self foldersParent];
    DLog(@"FolderViewController for folder %@ received folder added notification...", parentFolder.folderName);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *addedFolder = (NPFolder*)notification.object;
        
        if (addedFolder.moduleId == parentFolder.moduleId) {
            [self.folderList addUpdateMoveFolder:addedFolder];

            // The folder may be added to current list, or as a child to one of the folders in current list.
            [self refreshFolderView:NO];

            // Make sure it's listed here.
            if (addedFolder.parentId == parentFolder.folderId) {
                DLog(@"Added folder here: %@", [addedFolder description]);
            }
        }
    }
}

/*
 * Handle updating
 */
- (void)handleFolderUpdatedNotification:(NSNotification*)notification {
    NPFolder *parentFolder = [self foldersParent];
    DLog(@"FolderViewController for folder %@ received folder updated notification...", parentFolder.folderName);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *updatedFolder = (NPFolder*)notification.object;
        
        if (updatedFolder.moduleId == parentFolder.moduleId) {
            [self.folderList addUpdateMoveFolder:updatedFolder];
            
            if (updatedFolder.parentId == parentFolder.folderId) {
                DLog(@"Updated folder here: %@", [updatedFolder description]);
                [self refreshFolderView:NO];
            }
        }
    }
}

/*
 * Handle moving
 */
- (void)handleFolderMovedNotification:(NSNotification*)notification {
    NPFolder *parentFolder = [self foldersParent];
    DLog(@"FolderViewController for folder %@ received folder moved notification...", parentFolder.folderName);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *movedFolder = (NPFolder*)notification.object;
        [self.folderList addUpdateMoveFolder:movedFolder];
        _foldersParent = [self findFolderParent:movedFolder];
        [self refreshFolderView:NO];
    }
}

/*
 * This is to handle refreshing the "previous screen" when the folder of THIS screen is deleted.
 */
- (void)handleFolderDeletedNotification:(NSNotification*)notification {
    NPFolder *parentFolder = [self foldersParent];
    DLog(@"FolderViewController for folder %@ received folder deleted notification...", [parentFolder description]);
    
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        NPFolder *deletedFolder = (NPFolder*)notification.object;
        
        if (deletedFolder.moduleId == parentFolder.moduleId) {
            [self.folderList deleteFolder:deletedFolder];
            [self refreshFolderView:NO];
        }
    }
}


// This is called when tapping the "add" button on toolbar
- (IBAction)openCreateFolderView:(id)sender {
    NPFolder *parentFolder = [self foldersParent];
    if (parentFolder.moduleId == CALENDAR_MODULE) {
        [self performSegueWithIdentifier:@"NewCalendar" sender:parentFolder];
    } else {
        [self performSegueWithIdentifier:@"NewFolder" sender:parentFolder];
    }
}


- (IBAction)closeFolderViewer:(id)sender {
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
}


// Move button on toolbar tapped
- (void)moveToButtonTapped {
    NPFolder *parentFolder = [self foldersParent];
    [self.folderViewDelegate didSelectFolder:parentFolder forAction:ForMoving];
}


// Subfolder button at the accessory view to open the subfolder list
- (void)subFolderButtonTapped:(id)sender {
    UIButton *subFolderButn = (UIButton*)sender;
    NSInteger newParentFolderId = subFolderButn.tag;
    
    NPFolder *theFolder = [_folderList.folderDict objectForKey:[NSNumber numberWithInteger:newParentFolderId]];
    
    if (theFolder != nil) {
        // This folder becomes folders parent
        _foldersParent = theFolder;
        [self refreshFolderView:YES];
        
        if (theFolder.subFolders.count == 0) {
            [self didWantToCreateSubfolder:theFolder];
        }

    } else {
        [self refreshFolderView:YES];
    }
}


// This is called when "up" button is touched
- (void)goUpToParentFolderButtonTapped:(id)sender {
    // Now we need to find out the parent for the current folder list's parent
    // parent folder -> parent folder -> current folder list
    //    |_____ assign this folder to _parentFolder
    //
    _foldersParent = [self findFolderParent:_foldersParent];
    [self refreshFolderView:YES];
}


#pragma - segue to updater
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"NewFolder"] || [segue.identifier isEqualToString:@"NewCalendar"]) {
        NPFolder *parentFolder = (NPFolder*)sender;
        [segue.destinationViewController setParentFolder:parentFolder];
        NPFolder *blankFolder = [[NPFolder alloc] initWithModuleAndFolderId:_rootFolder.moduleId
                                                                   folderId:-1
                                                                 accessInfo:_rootFolder.accessInfo];
        
        blankFolder.parentId = parentFolder.folderId;
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setTheNewFolder:blankFolder];

    } else if ([segue.identifier isEqualToString:@"UpdateFolder"]) {
        [segue.destinationViewController setDelegate:self];
        [segue.destinationViewController setCurrentFolder:sender];
    }
}


#pragma mark - action sheet delegate

// Update the navigation items
- (void)updateNavItem {
    NPFolder *parentFolder = [self foldersParent];

    DLog(@"Update the back button tag to %i", parentFolder.parentId);
    
    // Set the "Back" button if it is not at the root folder
    if (parentFolder.folderId == ROOT_FOLDER) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = YES;
        
    } else {
        self.goUpButton = [UIBarButtonItem goToParentFolderButton:self
                                                           action:@selector(goUpToParentFolderButtonTapped:)
                                                     parentFolder:[parentFolder displayName]];
        _foldersParent = parentFolder;
        self.navigationItem.leftBarButtonItem = self.goUpButton;
    }

    if (_purpose == ForMoving && parentFolder.folderId == ROOT_FOLDER) {
        if (_rootFolder.moduleId == CALENDAR_MODULE) {
            self.navigationItem.title = NSLocalizedString(@"Move to calendar",);
        } else {
            self.navigationItem.title = NSLocalizedString(@"Move to folder",);
        }

    } else if (_purpose == ForEntrySaving) {
        if (_rootFolder.moduleId == CALENDAR_MODULE) {
            self.navigationItem.title = NSLocalizedString(@"Save to calendar",);
        } else {
            self.navigationItem.title = NSLocalizedString(@"Save to folder",);
        }
        
    } else {
        if (parentFolder.folderId == ROOT_FOLDER) {
            if (_rootFolder.moduleId == CONTACT_MODULE) {
                self.navigationItem.title = NSLocalizedString(@"Folders",);
                
            } else if (_rootFolder.moduleId == CALENDAR_MODULE) {
                self.navigationItem.title = NSLocalizedString(@"Calendars",);
                
            } else if (_rootFolder.moduleId == DOC_MODULE) {
                self.navigationItem.title = NSLocalizedString(@"Folders",);
                
            } else if (_rootFolder.moduleId == PHOTO_MODULE) {
                self.navigationItem.title = NSLocalizedString(@"Folders",);
                
            } else if (_rootFolder.moduleId == BOOKMARK_MODULE) {
                self.navigationItem.title = NSLocalizedString(@"Folders",);
            }
            
        } else {
            //self.navigationItem.title = [self.folderListParentFolder displayName];
            self.navigationItem.title = @"";
        }
    }

    [self.navigationController setToolbarHidden:NO];
}

- (void)showSubFolders:(NPFolder*)parentFolder animated:(BOOL)animated {
    [self.folders removeAllObjects];
    
    NSMutableArray *tmpList = [[NSMutableArray alloc] init];
    
    for (NSNumber *folderId in _folderList.folderDict) {
        NPFolder *f = [_folderList.folderDict objectForKey:folderId];
        if (f.parentId == parentFolder.folderId) {
            [tmpList addObject:f];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folderName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedResult = [tmpList sortedArrayUsingDescriptors:sortDescriptors];
    
    self.folders = [NSMutableArray arrayWithArray:sortedResult];
    
    if (parentFolder.folderId == ROOT_FOLDER) {
        [self.folders insertObject:_rootFolder atIndex:0];
    }
    
    if (animated == NO) {
        [self.tableView reloadData];
    } else {
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
    }
    
    if (self.rootFolder.moduleId == CALENDAR_MODULE) {
        NSArray *hiddenCalendars = [UserPrefUtil getHiddenCalendars];
        for (NPFolder *folder in self.folders) {
            if ([hiddenCalendars containsObject:[folder uniqueKey]]) {
                folder.isCalendarHidden = YES;
            }
        }
    }
}

- (void)reloadRowWithFolder:(NPFolder*)folder {
    NSInteger row = [self.folders indexOfObject:folder];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:YES];

    if (editing) {
        [self.tableView setEditing:YES];
        self.isBeingEditted = YES;

    } else {
        [self.tableView setEditing:NO];
        self.isBeingEditted = NO;

        // Set the "Back" button if it is not at the root folder
        if (self.foldersParent.folderId == ROOT_FOLDER) {
            self.navigationItem.leftBarButtonItem = nil;
            
        } else {
            self.goUpButton = [UIBarButtonItem goToParentFolderButton:self
                                                               action:@selector(goUpToParentFolderButtonTapped:)
                                                         parentFolder:[[self foldersParent] displayName]];
            self.navigationItem.leftBarButtonItem = self.goUpButton;
        }
    }
}

- (void)setToolbarItems {
    if (self.purpose != ForMoving) {
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] init];
        
        // Spacer
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [toolbarItems addObject:spacer];
        
        NPFolder *parentFolder = [self foldersParent];

        if ([parentFolder.accessInfo iAmOwner]) {
            [toolbarItems addObject:self.addNewFolderBarButtonItem];
        }

        self.toolbarItems = [NSArray arrayWithArray:toolbarItems];
    }
}

- (void)addMoveHereButtonToToolBar {
    if (self.purpose == ForMoving) {
        if (self.moveHereButton == nil) {
            CGRect rect = CGRectMake(0, 0, 105, 32);
            self.moveHereButton = [UIBarButtonItem khFlatButton:self
                                                         action:@selector(moveToButtonTapped)
                                                          title:NSLocalizedString(@"Move here",)
                                                           rect:rect
                                                backgroundColor:[UIColor defaultBlue]];
        }
        
        if (self.moveHereDisabledButton == nil) {
            CGRect rect = CGRectMake(0, 0, 105, 32);
            self.moveHereDisabledButton = [UIBarButtonItem khFlatButton:self
                                                                 action:@selector(moveToButtonTapped)
                                                                  title:NSLocalizedString(@"Move here",)
                                                                   rect:rect
                                                        backgroundColor:[UIColor lightGrayColor]];
            [self.moveHereDisabledButton setEnabled:NO];
        }
        
        UIBarButtonItem *spacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *spacer2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        NPFolder *parentFolder = [self foldersParent];

        if ([self.foldersCannotMoveInto containsObject:[NSNumber numberWithInt:parentFolder.folderId]]) {
            NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:spacer1, self.moveHereDisabledButton, spacer2, nil];
            self.toolbarItems = [NSArray arrayWithArray:toolbarItems];
   
        } else {
            NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:spacer1, self.moveHereButton, spacer2, nil];
            self.toolbarItems = [NSArray arrayWithArray:toolbarItems];
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
//    CGRect rect;
//
//    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
//        rect = [ViewDisplayHelper contentViewRect:64.0 heightAdjustment:0.0];
//    } else {
//        rect = [ViewDisplayHelper contentViewRect:52.0 heightAdjustment:0.0];
//    }
//
//    self.tableView = [[UITableView alloc] initWithFrame:rect];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -52.0, 320, 52.0)];
    headerLabel.backgroundColor = [UIColor whiteColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:12.0];
    headerLabel.text = NSLocalizedString(@"Pull down to close",);
    headerLabel.textColor = [UIColor lightGrayColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    [self.tableView addSubview:headerLabel];

    [self.view addSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderAddedNotification:) name:N_FOLDER_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderUpdatedNotification:) name:N_FOLDER_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderMovedNotification:) name:N_FOLDER_MOVED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFolderDeletedNotification:) name:N_FOLDER_DELETED object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_MOVED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_FOLDER_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.folderList = nil;
    self.folderService = nil;
    self.goUpButton = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
    [self setToolbarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    // Should be the best place for getting the accurate orientation.
    self.currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super setEditing:NO];
    [self.tableView setEditing:NO];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (FolderService*)folderService {
    if (_folderService == nil) {
        _folderService = [[FolderService alloc] init];
        _folderService.moduleId = _rootFolder.moduleId;
        _folderService.serviceDelegate = self;
    }
    return _folderService;
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.folders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NPFolder *folder = [self.folders objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"FolderListCell";
    
    FolderTreeItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[FolderTreeItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FolderListCell"];
        cell.delegate = self;
    }
    
    if (folder.folderId != ROOT_FOLDER) {
        NSMutableArray *rightUtilityButtons = [NSMutableArray new];
        
        if ([folder.accessInfo iAmOwner]) {
            [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                        title:@"More"];

            if (folder.moduleId == CALENDAR_MODULE) {
                if (folder.isCalendarHidden) {
                    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor blueColor]
                                                                title:@"Show"];
                    
                } else {
                    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor blueColor]
                                                                title:@"Hide"];
                    
                }
            }
            
            [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:@"Trash"];
        } else {
            [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                        title:@"Un-Share"];
        }
        
        cell.rightUtilityButtons = rightUtilityButtons;

    } else {
        cell.rightUtilityButtons = nil;
    }
    
    cell.folder = folder;
    
    if (self.folders.count - 1 == indexPath.row) {
        cell.lastItemInTree = YES;
    }
    
    cell.textLabel.text = [folder displayName];
    
    if (folder.moduleId == CALENDAR_MODULE && folder.isCalendarHidden) {
        cell.textLabel.textColor = [UIColor grayColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }

    cell.textLabel.backgroundColor = [UIColor whiteColor];
    
    if (indexPath.row == 0 && folder.folderId == ROOT_FOLDER) {
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    } else {
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    
    if (folder.moduleId != CALENDAR_MODULE) {
        [cell setSubfolderButton:self action:@selector(subFolderButtonTapped:)];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NPFolder *folder = [self.folders objectAtIndex:indexPath.row];
    
    if (self.tableView.editing && folder.folderId == ROOT_FOLDER) {                                   // No editing for root
        return;
    }
    
    if (self.tableView.editing == YES) {            // Just select, do not open child folders on editing mode
        if ([folder.accessInfo iAmOwner]) {
            [self performSegueWithIdentifier:@"UpdateFolder" sender:folder];
        }
        
    } else {
        if (self.purpose == ForMoving) {
            _foldersParent = folder;
            [self refreshFolderView:YES];
            
        } else if (self.purpose == ForEntrySaving) {
            [self.folderViewDelegate didSelectFolder:folder forAction:ForEntrySaving];
        
        } else {
            if (folder.folderId == ROOT_FOLDER) {
                /*
                 * For modules other than calendar, selecting the ROOT folder simply means popping the folder picker and
                 * revealing the root listing underneath.
                 *
                 * For calendar module, since there is only ONE view to show the events, the delegate also needs to be called
                 * to refresh the events.
                 *
                 */
                if (folder.moduleId == CALENDAR_MODULE) {
                    [self.folderViewDelegate didSelectFolder:folder forAction:ForListing];
                } else {
                    [self closeFolderViewer:nil];
                }

            } else {
                [self.folderViewDelegate didSelectFolder:folder forAction:ForListing];
            }
        }
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NPFolder *folder = [self.folders objectAtIndex:indexPath.row];
    if (folder.folderId == ROOT_FOLDER) {                                   // No editing for root
        return NO;
    }
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}


- (void)didWantToCreateSubfolder:(NPFolder *)parentFolder {
    [self performSegueWithIdentifier:@"NewFolder" sender:parentFolder];
}


#pragma Handles utility button

// Delegate to handle the utility button
- (void)swipeableTableViewCell:(SWTableViewCell*)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NPFolder *folder = [self.folders objectAtIndex:indexPath.row];
    
    switch (index) {
        case 0:             // More
            [self moreButtonTapped:cell];
            break;
            
        case 1:             // for calendar, it's hide/show. For others, it's Delete or un-share
            if (folder.moduleId == CALENDAR_MODULE) {
                UIButton *theButton = [cell.rightUtilityButtons objectAtIndex:1];

                if (folder.isCalendarHidden) {
                    // Change it to un-hidden
                    [UserPrefUtil toggleCalendarVisibility:folder hideIt:NO];
                    folder.isCalendarHidden = NO;
                    [theButton setTitle:NSLocalizedString(@"Hide",) forState:UIControlStateNormal];
                    cell.textLabel.textColor = [UIColor blackColor];
                    
                } else {
                    // Change it to hidden
                    [UserPrefUtil toggleCalendarVisibility:folder hideIt:YES];
                    folder.isCalendarHidden = YES;
                    [theButton setTitle:NSLocalizedString(@"Show",) forState:UIControlStateNormal];
                    cell.textLabel.textColor = [UIColor grayColor];
                }

                [self reloadRowWithFolder:folder];

            } else {
                [self deleteOrUnshareFolderAction:folder];
            }
            break;
            
        case 2:
            [self deleteOrUnshareFolderAction:folder];
            break;
            
        default:
            break;
    }
}


- (void)moreButtonTapped:(UITableViewCell*)cell {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    actionSheet.tag = indexPath.row;

    if (self.rootFolder.moduleId == CALENDAR_MODULE) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update calendar",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete calendar",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 2;
        actionSheet.destructiveButtonIndex = 1;
        
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Move folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add child folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete folder",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 4;
        actionSheet.destructiveButtonIndex = 3;
        
    }
    
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    NPFolder *folder = [self.folders objectAtIndex:sender.tag];
    
    if (index == sender.cancelButtonIndex) {
        [self reloadRowWithFolder:folder];
        return;
    }
    
    if (self.rootFolder.moduleId == CALENDAR_MODULE) {
        if (index == 0) {           // Update folder
            [self updateFolderAction:folder];
            
        } else if (index == 1) {    // Move folder
            [self deleteOrUnshareFolderAction:folder];
        }

    } else {
        if (index == 0) {           // Update folder
            [self updateFolderAction:folder];
            
        } else if (index == 1) {    // Move folder
            [self moveFolderAction:folder];
            
        } else if (index == 2) {    // Add child folder
            [self addChildFolderAction:folder];
            
        } else if (index == 3) {    // Delete folder
            [self deleteOrUnshareFolderAction:folder];
        }
        
    }
    
}

- (void)updateFolderAction:(NPFolder*)folder {
    [self performSegueWithIdentifier:@"UpdateFolder" sender:folder];
}

- (void)moveFolderAction:(NPFolder*)folder {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        folderViewController.purpose = ForMoving;
        folderViewController.foldersCannotMoveInto = [NSArray arrayWithObjects:[NSNumber numberWithInt:folder.folderId],
                                                      [NSNumber numberWithInt:folder.parentId], nil];
        
        [folderViewController showFolderTree:folder];
        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}

- (void)addChildFolderAction:(NPFolder*)parentFolder {
    [self performSegueWithIdentifier:@"NewFolder" sender:parentFolder];
}

- (void)deleteOrUnshareFolderAction:(NPFolder*)folder {
    if ([folder.accessInfo iAmOwner]) {
        NSString *message = NSLocalizedString(@"Are you sure you want to delete this folder and all its content?",);
        
        if (_rootFolder.moduleId == CALENDAR_MODULE) {
            message = NSLocalizedString(@"Are you sure you want to delete this calendar and all its content?",);
            message = [message stringByReplacingOccurrencesOfString:@"this calendar" withString:[folder displayName]];
        } else {
            message = [message stringByReplacingOccurrencesOfString:@"this folder" withString:[folder displayName]];
        }
        
        _doAlert = [[DoAlertView alloc] init];
        _doAlert.nAnimationType = DoTransitionStylePop;
        _doAlert.dRound = 5.0;
        
        _doAlert.bDestructive = YES;
        [_doAlert doYesNo:message
                      yes:^(DoAlertView *alertView) {
                          [ViewDisplayHelper displayWaiting:self.view messageText:nil];
                          [self.folderService deleteFolder:folder];
                          
                      } no:^(DoAlertView *alertView) {
                          [self reloadRowWithFolder:folder];
                      }];
        
        _doAlert = nil;
        
    } else {
        NSString *message = NSLocalizedString(@"Are you sure you want to stop accessing this shared folder?",);
        
        if (_rootFolder.moduleId == CALENDAR_MODULE) {
            message = NSLocalizedString(@"Are you sure you want to stop accessing this shared calendar?",);
            message = [message stringByReplacingOccurrencesOfString:@"this shared calendar" withString:[folder displayName]];
        } else {
            message = [message stringByReplacingOccurrencesOfString:@"this shared folder" withString:[folder displayName]];
        }
        
        _doAlert = [[DoAlertView alloc] init];
        _doAlert.nAnimationType = DoTransitionStylePop;
        _doAlert.dRound = 5.0;
        
        _doAlert.bDestructive = YES;
        [_doAlert doYesNo:message
                      yes:^(DoAlertView *alertView) {
                          [ViewDisplayHelper displayWaiting:self.view messageText:nil];
                          [self.folderService stopSharingFolder:folder toMe:[UserManager instance].currentUser];
                          
                      } no:^(DoAlertView *alertView) {
                          [self reloadRowWithFolder:folder];
                      }];
        
        _doAlert = nil;
    }
}

#pragma handles drag down and close

/*
 * Handles drag down and close
 */

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isBeingDragged = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isBeingDragged) {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            if (scrollView.contentOffset.y < -84) {
                [self closeFolderViewer:nil];
            }
        } else {
            if (scrollView.contentOffset.y < -64) {
                [self closeFolderViewer:nil];
            }
        }
        
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isBeingDragged = NO;
}


#pragma rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect rect;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        rect = [ViewDisplayHelper contentViewRect:64.0 heightAdjustment:0];
    } else {
        rect = [ViewDisplayHelper contentViewRect:52.0 heightAdjustment:0];
    }
    self.tableView.frame = rect;
    [self.tableView reloadData];
}

@end
