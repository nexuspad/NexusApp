//
//  EntryEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryEditorTableViewController.h"
#import "AddressEditorViewController.h"
#import "FolderService.h"
#import "DropdownButton.h"

@interface EntryEditorTableViewController ()
@property (nonatomic, strong) UIButton *changeFolderButton;
@end

@implementation EntryEditorTableViewController

@synthesize entryService, afterSavingDelegate;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self.navigationController setToolbarHidden:NO];
    }
    return self;
}

// This must be overridden by the subclass.
- (NPEntry*)currentEditedEntry {
    NSLog(@"ERROR - currentEditedEntry must be overriden!");
    return nil;
}

#pragma mark - data service delegate

- (void)updateServiceResult:(id)serviceResult {
    // Implementation in subclass
}

- (void)serviceError:(id)serviceResult {
    NSLog(@"NPService returned error: %@", [serviceResult description]);
    [ViewDisplayHelper dismissWaiting:self.view];
}


#pragma mark - open folders

- (IBAction)openFolderView:(id)sender {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        NPEntry *editedEntry = [self currentEditedEntry];
        folderViewController.purpose = ForEntrySaving;
        [folderViewController showFolderTree:editedEntry.folder];
        folderViewController.folderViewDelegate = self;        
        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
    [self showChangeFolderButton:[selectedFolder displayName]];
}

- (void)showChangeFolderButton:(NSString*)folderDisplayName {
    if (folderDisplayName.length == 0) {
        folderDisplayName = NSLocalizedString(@"Select folder",);
    }

    self.changeFolderButton = [[DropdownButton alloc] init:self action:@selector(openFolderView:) line1:folderDisplayName line2:nil rightImage:[UIImage imageNamed:@"arrow-down.png"]];

    self.navigationItem.titleView = self.changeFolderButton;
}

- (IBAction)cancelEditor:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setSelectedValue:(id)sender
{    
}

- (void)inputListChanged:(id)sender
{
}

#pragma mark - Editor save action and NP service response delegate

- (void)postEntry:(NPEntry*)entry {
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
    [self.entryService addOrUpdateEntry:entry];
}

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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.toolbarHidden = YES;
    
    NPEntry *editedEntry = [self currentEditedEntry];
    
    if ([editedEntry.accessInfo iAmOwner]) {
        [self showChangeFolderButton:[editedEntry.folder displayName]];
    } else {
        self.navigationItem.title = [editedEntry.folder displayName];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    
    if (self.entryService == nil) {
        self.entryService = [[EntryService alloc] init];
    }

    self.entryService.serviceDelegate = self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
