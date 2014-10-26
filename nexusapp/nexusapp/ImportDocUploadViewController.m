//
//  DocUploadViewController.m
//  nexuspad
//
//  Created by Ren Liu on 9/10/12.
//
//

#import "ImportDocUploadViewController.h"
#import "DashboardController.h"
#import "UIBarButtonItem+NPUtil.h"
#import "ViewDisplayHelper.h"
#import "KHFlatButton/KHFlatButton.h"
#import "UIColor+NPColor.h"

@interface ImportDocUploadViewController ()
@property (nonatomic, strong) UIBarButtonItem *dashboardButton;
@property (nonatomic, strong) NPFolder *destinationFolder;
@end

@implementation ImportDocUploadViewController

- (void)addFileURLWithDestination:(NSURL*)fileUrl toFolder:(NPFolder*)toFolder {
    NPUploadHelper *uploader = [NPUploadHelper instance];
    uploader.uploadHelperDelegate = self;

    [uploader addAsset:fileUrl thumbnailImage:nil destination:toFolder];
    self.destinationFolder = toFolder;
    
    [self findIncompleteItems];
}

- (IBAction)startUploading:(id)sender {
    [[NPUploadHelper instance] startUploading];
}


#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DocCell";
    UITableViewCell *theCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UploadItem *item = [self.incompleteItems objectAtIndex:indexPath.row];
    NSURL *fileUrl = item.itemUrl;

    UILabel *fileNameLabel = (UILabel*)[theCell viewWithTag:5];
    fileNameLabel.text = [[fileUrl pathComponents] lastObject];
    fileNameLabel.textAlignment = NSTextAlignmentCenter;
    
    UIProgressView *progressBar = (UIProgressView*)[theCell.contentView viewWithTag:10];
    
    UIButton *uploadButn = (UIButton*)[theCell.contentView viewWithTag:50];
    
    if (item.status == WAITING) {
        progressBar.progress = 0.0;
        
    } else if (item.status == UPLOADING) {
        uploadButn.hidden = YES;
        progressBar.progress = item.percentage;
        
    } else if (item.status == CANCELED) {
        uploadButn.hidden = NO;
        progressBar.progress = 0.0;
        
    } else if (item.status == ERROR) {
        uploadButn.hidden = NO;
        progressBar.progress = 0.0;
        
    } else if (item.status == COMPLETED) {
        uploadButn.hidden = YES;
        progressBar.progress = 100.0;
    }
    
    return theCell;
}

- (void)openDashboard:(id)sender
{
    UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_main" bundle:nil];
    DashboardController *dashboardController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"DashboardView"];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:YES];
    
    [self.navigationController setViewControllers:[NSArray arrayWithObject:dashboardController] animated:NO];

    [UIView commitAnimations];
}

// Open the folder picker
- (IBAction)openFolderPicker:(id)sender {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    FolderViewController* folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        folderViewController.purpose = ForEntrySaving;
        [folderViewController showFolderTree:self.destinationFolder];
        folderViewController.folderViewDelegate = self;
        folderViewController.navigationItem.leftBarButtonItem = nil;
        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    DLog(@"In didSelectedFolder selected folder id %i", selectedFolder.folderId);
    self.destinationFolder = [selectedFolder copy];
    self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Upload to",), [self.destinationFolder displayName]];
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
    
    NSMutableArray *uploadItems = [[NPUploadHelper instance] uploadItems];
    for (UploadItem *item in uploadItems) {
        item.toFolder = self.destinationFolder;
    }
}


#pragma mark - Table view delegate

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationItem.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Upload to",), [self.destinationFolder displayName]];
    
    if (self.dashboardButton == nil) {
        self.dashboardButton = [UIBarButtonItem dashboardButtonPlain:self action:@selector(openDashboard:)];
    }
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.leftBarButtonItem = self.dashboardButton;
}

- (void)viewDidUnload {
    [self setUploadButton:nil];
    [super viewDidUnload];
}

@end
