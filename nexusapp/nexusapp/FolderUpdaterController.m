//
//  FolderUpdaterController.m
//  nexuspad
//
//  Created by Ren Liu on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FolderUpdaterController.h"
#import "FolderActionResult.h"
#import "ViewDisplayHelper.h"
#import "NotificationUtil.h"
#import "KHFlatButton.h"
#import "AddUserAutoCompletionHelper.h"
#import "AccessPermission.h"

static float SHARING_TABLE_TOP_SPACE;

@interface FolderUpdaterController ()
@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) AddUserAutoCompletionHelper *addUserACHelper;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sharingTableTopSpaceConstraint;
@property (strong, nonatomic) IBOutlet UITableView *sharingTableView;
@property (strong, nonatomic) FolderService *folderService;
@end

@implementation FolderUpdaterController

@synthesize folderNameTextField = _folderNameTextField;
@synthesize parentFolder, currentFolder;


// Cancel the updater screen
- (IBAction)cancelButtonTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

// The function is not used because move can be done in other places.
// The toolbar button is removed from the bottom bar.
- (IBAction)moveFolder:(id)sender {
    FolderViewController* folderViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    if (folderViewController) {
        folderViewController.purpose = ForMoving;
        folderViewController.foldersCannotMoveInto = [NSArray arrayWithObjects:[NSNumber numberWithInt:self.currentFolder.folderId],
                                                      [NSNumber numberWithInt:self.currentFolder.parentId], nil];
        
        [folderViewController showFolderTree:self.currentFolder];
        
        folderViewController.folderViewDelegate = self;
        [ViewDisplayHelper pushViewControllerBottomUp:self.navigationController viewController:folderViewController];
    }
}

// Handles either creating new folder or updating an existing folder
- (IBAction)saveButtonTapped:(id)sender {
    if (self.folderNameTextField.text.length == 0) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil
                                                             message:NSLocalizedString(@"Invalid folder name",)
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"OK",), nil];
        [alertView show];

    }

    if (![self.currentFolder.folderName isEqualToString:self.folderNameTextField.text]) {
        self.currentFolder.folderName = [NSString stringWithString:self.folderNameTextField.text];
        self.currentFolder.accessInfo.owner = [[NPUser alloc] initWithUser:[[AccountManager instance] getCurrentLoginAcct]];
        
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];

        // In Folder Update screen, we only need to save the new folder name, so here we remove the sharing information.
        NPFolder *f = [self.currentFolder copy];
        f.sharings = nil;
        [self.folderService addOrUpdateFolder:f];
        
    } else {
        // The name is not changed, just dismiss the view controller.
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)deleteFolderButtonTapped:(id)sender {
    NSString *message = NSLocalizedString(@"Are you sure you want to delete this folder and its content?",);
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
}

#pragma mark - accessor changes

- (void)addAccessorButtonTapped:(id)sender {
    NSString *email = nil;
    if ([NSString isValidEmail:self.addUserACHelper.userNameOrEmailTextField.text]) {
        email = self.addUserACHelper.userNameOrEmailTextField.text;
    } else if (self.addUserACHelper.userEmailLabel != nil && [NSString isValidEmail:self.addUserACHelper.userEmailLabel.text]) {
        email = self.addUserACHelper.userEmailLabel.text;
    }

    if (email != nil) {
        NPUser *accessor = [[NPUser alloc] init];
        accessor.email = email;
        AccessPermission *accessPermission = [[AccessPermission alloc] init];
        accessPermission.accessor = accessor;
        accessPermission.read = YES;
        [self.folderService updateSharing:self.currentFolder accessPermission:accessPermission];
        
        self.addUserACHelper.userNameOrEmailTextField.text = @"";
        self.addUserACHelper.userEmailLabel.text = @"";

    } else {
        NSLog(@"!!!! No valid email defined. This shouldn't happen.");
    }
}

- (void)deleteAccessorButtonTapped:(id)sender {
    AccessPermission *selectedAccessPermission = [self getSelectedAccessPermission:(UIView*)sender];
    selectedAccessPermission.read = NO;
    selectedAccessPermission.write = NO;
    [self updateSharing:selectedAccessPermission];
}

// Permission UISwitch changed
- (void)permissionChangedForUser:(id)sender {
    UISwitch *permissionSwitch = (UISwitch*)sender;
    
    AccessPermission *selectedAccessPermission = [self getSelectedAccessPermission:sender];
    if (selectedAccessPermission != nil) {
        if ([permissionSwitch isOn]) {
            selectedAccessPermission.write = YES;
        } else {
            selectedAccessPermission.write = NO;
        }
        [self updateSharing:selectedAccessPermission];
        
    } else {
        NSLog(@"Not able to find the user to change permission...");
    }
}

- (AccessPermission*)getSelectedAccessPermission:(id)sender {
    UIView *view = (UIView*)sender;
    
    //maximum 5 attempts
    for(int i = 0; i < 5; i++) {
        view = view.superview;
        if([view isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)view;
            NSIndexPath *indexPath = [self.sharingTableView indexPathForCell:cell];
            
            if ([self.currentFolder.sharings objectAtIndex:indexPath.row - 1] != nil) {
                AccessPermission *access = [self.currentFolder.sharings objectAtIndex:indexPath.row - 1];
                return access;
            }
        }
    }
    return nil;
}


#pragma mark - service calls

// Add new accessor, delete or update permission
- (void)updateSharing:(AccessPermission*)accessPermission {
    [self.folderService updateSharing:self.currentFolder accessPermission:accessPermission];
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (index == sender.destructiveButtonIndex) {
        [self.folderService deleteFolder:self.currentFolder];
        [self.navigationController popViewControllerAnimated:YES];

    } else if (index == sender.cancelButtonIndex) {
        [sender dismissWithClickedButtonIndex:index animated:YES];
    }
}


#pragma mark - folder selector delegate - for moving folder
- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    if (forAction == ForMoving) {
        // Dismiss the folder picker
        [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
        
        if (selectedFolder.folderId == self.currentFolder.parentId) {
            NSString *firstPart = NSLocalizedString(@"Already in folder",);
            NSString *message = [firstPart stringByAppendingFormat:@" \"%@\"", selectedFolder.folderName];
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid selection",)
                                                                 message:message
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"OK",), nil];
            [alertView show];
            
        } else if (selectedFolder.folderId == self.currentFolder.folderId) {
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid selection",)
                                                                 message:@"I can't move it under itself."
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"OK",), nil];
            [alertView show];
            
        } else {
            self.parentFolder = [selectedFolder copy];
            [ViewDisplayHelper displayWaiting:self.view messageText:nil];
            [self.folderService moveFolder:self.currentFolder parentFolder:selectedFolder];
        }        
    }
}


#pragma mark - Web service delegate

// Update the folder update result
- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];

    if ([serviceResult isKindOfClass:[NPFolder class]]) {
        self.currentFolder = (NPFolder*)serviceResult;
        [self.sharingTableView reloadData];

    } else if ([serviceResult isKindOfClass:[FolderActionResult class]]) {
        FolderActionResult *actionResponse = (FolderActionResult*)serviceResult;
        
        if ([actionResponse.name isEqualToString:ACTION_UPDATE_FOLDER]) {
            [NotificationUtil sendFolderUpdatedNotification:[actionResponse.folder copy]];
            [self.navigationController popViewControllerAnimated:YES];

        } else if ([actionResponse.name isEqualToString:ACTION_MOVE_FOLDER]) {
            NPFolder *returnedFolder = [actionResponse.folder copy];
            returnedFolder.previousParentId = self.currentFolder.parentId;
            [NotificationUtil sendFolderMovedNotification:returnedFolder];
            
            // Close the folder update view controller
            [self.navigationController popViewControllerAnimated:NO];

        } else if ([actionResponse.name isEqualToString:ACTION_SHARE_FOLDER]) {
            self.currentFolder = actionResponse.folder;
            [self.sharingTableView reloadData];
            
        } else if ([actionResponse.name isEqualToString:ACTION_DELETE_FOLDER]) {
            if (actionResponse.success) {
                [NotificationUtil sendFolderDeletedNotification:[actionResponse.folder copy]];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)serviceError:(ServiceResult*)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];

    if (serviceResult.code == NP_WEB_SERVICE_NOT_AVAILABLE) {
        // No need to report the error here.
        return;
    }

    NSString *message = NSLocalizedString(@"There is an error updating folder.",);
    if (serviceResult.message.length > 0) {
        message = [serviceResult.message copy];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
}


#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.currentFolder.moduleId == CALENDAR_MODULE) {
        self.navigationItem.title = NSLocalizedString(@"Update calendar",);
        
        NSMutableArray *toolBarItems = [self.toolbarItems mutableCopy];
        [toolBarItems removeObjectAtIndex:0];
        self.toolbarItems = toolBarItems;
        
    } else {
        self.navigationItem.title = NSLocalizedString(@"Update folder",);
    }

    self.folderNameTextField.text = self.currentFolder.folderName;
    
    self.folderService = [[FolderService alloc] init];
    self.folderService.moduleId = self.currentFolder.moduleId;
    self.folderService.serviceDelegate = self;

    self.sharingTableView.delegate = self;
    self.sharingTableView.dataSource = self;

    self.sharingTableView.separatorColor = [UIColor clearColor];
    
    SHARING_TABLE_TOP_SPACE = self.sharingTableTopSpaceConstraint.constant;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onKeyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // This has to be called for showing update screen from EntryListFolderViewController
    self.navigationController.toolbarHidden = NO;
    
    if (self.startAtSharing) {
        self.sharingTableTopSpaceConstraint.constant = 66.0;
    }

    [self.folderService getFolderDetail:self.currentFolder];    
}

- (void)viewDidUnload
{
    [self setFolderNameTextField:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


# pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 77.0;
    }
    return 80.0;;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentFolder.sharings.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        UITableViewCell *addUserCell = [tableView dequeueReusableCellWithIdentifier:@"AddUserCell"];
        if (self.addUserACHelper == nil) {
            self.addUserACHelper = [[AddUserAutoCompletionHelper alloc] initWithTextField:(UITextField *)[addUserCell viewWithTag:10]];
            self.addUserACHelper.userNameOrEmailTextField.delegate = self;
            
            UILabel *userEmailLabel = (UILabel*)[addUserCell viewWithTag:11];
            self.addUserACHelper.userEmailLabel = userEmailLabel;
            
            UIButton *addUserButton = (UIButton*)[addUserCell viewWithTag:12];
            [addUserButton addTarget:self action:@selector(addAccessorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        }
        return addUserCell;
        
    } else {
        AccessPermission *shareToUser = [self.currentFolder.sharings objectAtIndex:indexPath.row - 1];

        UITableViewCell *userCell = [self.sharingTableView dequeueReusableCellWithIdentifier:@"UserCell"];
        UILabel *userNameLabel = (UILabel*)[userCell viewWithTag:11];
        UISwitch *allowWriteSwitch = (UISwitch*)[userCell viewWithTag:16];
        UIButton *deleteSharingButton = (UIButton*)[userCell viewWithTag:20];
        
        if ([shareToUser.accessor getDisplayName].length == 0) {
            userNameLabel.text = shareToUser.accessor.email;
        } else {
            userNameLabel.text = [shareToUser.accessor getDisplayName];
        }
        
        if (shareToUser.write) {
            [allowWriteSwitch setOn:YES];
        } else {
            [allowWriteSwitch setOn:NO];
        }
        
        [allowWriteSwitch addTarget:self action:@selector(permissionChangedForUser:) forControlEvents:UIControlEventValueChanged];
        
        // Bind delete button action.
        [deleteSharingButton addTarget:self action:@selector(deleteAccessorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        userCell.imageView.image = [UIImage imageNamed:@"avatar.png"];
        return userCell;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Sharing",);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}


#pragma mark - textfield and keyboard

- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    self.sharingTableTopSpaceConstraint.constant = 66.0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.addUserACHelper.userNameOrEmailTextField) {
        [self.addUserACHelper.userNameOrEmailTextField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)onKeyboardHide:(NSNotification *)notification {
    // Only move down the "rename" part when NOT starting updating folder as sharing.
    if (!self.startAtSharing) {
        self.sharingTableTopSpaceConstraint.constant = SHARING_TABLE_TOP_SPACE;
    }
}

@end
