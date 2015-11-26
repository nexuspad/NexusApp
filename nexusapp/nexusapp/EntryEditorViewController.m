//
//  EntryEditorViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "EntryEditorViewController.h"
#import "ViewDisplayHelper.h"

@interface EntryEditorViewController ()

@end

@implementation EntryEditorViewController

@synthesize entryFolder, entryService, afterSavingDelegate;


- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        [self.navigationController setToolbarHidden:NO];
    }
    return self;
}

#pragma mark - data service delegate

// This will ALWAYS be called. Either from web service callback or data store callback.
- (void)updateServiceResult:(id)serviceResult {
    // Implementation in subclass
}

- (void)serviceError:(id)serviceResult {
    NSLog(@"NPService returned error: %@", [serviceResult description]);
    [ViewDisplayHelper dismissWaiting:self.view];   // This shouldn't be really necessary
}


#pragma mark - open folders

- (IBAction)openFolderView:(id)sender {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        folderViewController.purpose = ForEntrySaving;
        [folderViewController showFolderTree:self.entryFolder];
        
        folderViewController.folderViewDelegate = self;
        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
}

- (IBAction)cancelEditor:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Editor save action and NP service response delegate

- (void)postEntry:(NPEntry*)entry {
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
    [self.entryService addOrUpdateEntry:entry];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.entryService == nil) {
        self.entryService = [[EntryService alloc] init];
    }
    self.entryService.accessInfo = [self.entryFolder.accessInfo copy];
    self.entryService.serviceDelegate = self;
    
    self.navigationItem.title = [self.entryFolder displayName];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

@end
