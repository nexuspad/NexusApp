//
//  EntryViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryDetailTableViewController.h"
#import "NPModule.h"
#import "EmailEntryViewController.h"
#import "UIBarButtonItem+NPUtil.h"

@interface EntryDetailTableViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editEntryButton;
@end

@implementation EntryDetailTableViewController

@synthesize entryService;

// This needs to be implemented in subclasses
- (NPEntry*)getCurrentEntry {
    return nil;
}

// Make service call to the backend, needs to be implemented in subclasses
- (void)retrieveEntryDetail {
}

- (IBAction)openEmailEntry:(id)sender {
    NPEntry *currentEntry = [self getCurrentEntry];
    
    if (currentEntry != nil) {
        UIStoryboard *shareStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_share" bundle:nil];
        EmailEntryViewController* emailEntryController = [shareStoryBoard instantiateViewControllerWithIdentifier:@"EmailEntryView"];
        emailEntryController.theEntry = [currentEntry copy];
        
        emailEntryController.promptDelegate = self;
        [self.navigationController pushViewController:emailEntryController animated:YES];
    }
}

- (void)updatePrompt:(NSString *)promptMessage
{
    self.navigationItem.prompt = promptMessage;
}

- (IBAction)deleteEntry:(id)sender {
    NPEntry *currentEntry = [self getCurrentEntry];
    
    if (currentEntry != nil) {
        NSString *message = [NSLocalizedString(@"Are you sure you want to delete this",)
                             stringByAppendingFormat:@" %@?", [NPModule getModuleEntryName:currentEntry.folder.moduleId templateId:currentEntry.templateId]];
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                                        otherButtonTitles:nil];
        
        [actionSheet showFromToolbar:self.navigationController.toolbar];        
    }
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (index == sender.destructiveButtonIndex) {
        [self callDeleteService];
        [sender dismissWithClickedButtonIndex:index animated:YES];
        [self.navigationController popViewControllerAnimated:YES];

    } else if (index == sender.cancelButtonIndex) {
        [sender dismissWithClickedButtonIndex:index animated:YES];
    }
}

- (void)callDeleteService {
    NPEntry *currentEntry = [self getCurrentEntry];
    
    if (currentEntry != nil) {
        [self.entryService deleteEntry:currentEntry];
        [NotificationUtil sendEntryDeletedNotification:currentEntry];        
    }
}

- (void)updateServiceResult:(id)responseObj
{
    [ViewDisplayHelper dismissWaiting:self.view];
}

- (void)serviceError:(ServiceResult*)serviceResult
{
    NSLog(@"NPService returned error: %@", [serviceResult description]);
    [ViewDisplayHelper dismissWaiting:self.view];
}


#pragma mark - open folders

- (IBAction)openFolderSelector:(id)sender {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        
        NPEntry *entry = [self getCurrentEntry];
        
        folderViewController.purpose = ForMoving;
        folderViewController.foldersCannotMoveInto = [NSArray arrayWithObject:[NSNumber numberWithInt:entry.folder.folderId]];
        
        NPFolder *entryFolder = [[NPFolder alloc] initWithModuleAndFolderId:entry.folder.moduleId folderId:entry.folder.folderId accessInfo:entry.accessInfo];
        
        [folderViewController showFolderTree:entryFolder];
        folderViewController.folderViewDelegate = self;

        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    NPEntry *movedEntry = [self getCurrentEntry];
    movedEntry.folder.folderId = selectedFolder.folderId;
    [self.entryService moveEntry:movedEntry];
    [NotificationUtil sendEntryMovedNotification:movedEntry];

    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
}


#pragma mark - table view delegates

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 5.0;
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    }
    return 5.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [ViewDisplayHelper emptyViewFiller];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [ViewDisplayHelper emptyViewFiller];
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.entryService = nil;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    
    NPEntry *currentEntry = [self getCurrentEntry];

    if (self.entryService == nil) {
        self.entryService = [[EntryService alloc] init];
        self.entryService.accessInfo = [currentEntry.accessInfo copy];
    }
    
    self.entryService.serviceDelegate = self;

    // Make a copy of the toolbar items
    self.toolbarItemsLoadedInStoryboard = [[NSMutableDictionary alloc] initWithCapacity:5];
    for (UIBarButtonItem *item in self.toolbarItems) {
        if (item.tag != 0) {
            [self.toolbarItemsLoadedInStoryboard setObject:item forKey:[NSString stringWithFormat:@"%li", (long)item.tag]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    self.navigationController.toolbarHidden = NO;
    
    [self setEntryToolbarItems];
    
//    UIEdgeInsets insets = { .left = 0, .right = 0, .top = 0, .bottom = 50.0 };
//    [self.tableView setContentInset:insets];
    //[self.tableView setScrollIndicatorInsets:insets];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.entryService = nil;
}


- (void)setEntryToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *spacer = [UIBarButtonItem spacer];

    NPEntry *entry = [self getCurrentEntry];
    if ([entry.accessInfo iAmOwner]) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_MOVE_ENTRY]];
        [items addObject:spacer];
        
        if ([self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FAVORITE_ENTRY] != nil) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FAVORITE_ENTRY]];
            [items addObject:spacer];
        }

        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_EMAIL_ENTRY]];
        [items addObject:spacer];

        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_DELETE_ENTRY]];

    } else {
        if ([entry.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_EMAIL_ENTRY]];
            [items addObject:spacer];
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_DELETE_ENTRY]];
        } else {
            [items addObject:spacer];
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_EMAIL_ENTRY]];
        }
    }
    
    if ([entry.accessInfo iCanWrite]) {
        self.navigationItem.rightBarButtonItem = self.editEntryButton;
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.toolbarItems = items;
}

@end
