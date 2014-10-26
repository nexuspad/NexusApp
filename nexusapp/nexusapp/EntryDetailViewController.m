//
//  BaseEntryViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "EntryDetailViewController.h"
#import "NPModule.h"
#import "EmailEntryViewController.h"
#import "UIBarButtonItem+NPUtil.h"

@interface EntryDetailViewController ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editEntryButton;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation EntryDetailViewController

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

// Open the folder view controller to move the entry around
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
        
        // In DocNoteViewController, the navigationBar is hidden. We need to unhide it here before pushing the folder selector.
        self.navigationController.navigationBarHidden = NO;

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


#pragma mark - tableview delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.toolbarHidden = NO;

    [self setEntryToolbarItems];
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
