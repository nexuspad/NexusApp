//
//  NewFolderController.m
//  nexuspad
//
//  Created by Ren Liu on 8/22/12.
//
//

#import "FolderCreateController.h"
#import "FolderActionResult.h"
#import "ViewDisplayHelper.h"
#import "NotificationUtil.h"
#import "KHFlatButton.h"
#import "AddUserAutoCompletionHelper.h"
#import "AccessPermission.h"

static float SHARING_TABLE_TOP_SPACE;

@interface FolderCreateController ()
@property (strong, nonatomic) IBOutlet UILabel *parentFolderNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) AddUserAutoCompletionHelper *addUserACHelper;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sharingTableTopSpaceConstraint;
@property (strong, nonatomic) IBOutlet UITableView *sharingTableView;
@property (strong, nonatomic) FolderService *folderService;

@end

@implementation FolderCreateController

@synthesize folderService, delegate;
@synthesize folderNameTextField = _folderNameTextField;

@synthesize parentFolder, theNewFolder;


// Cancel the updater screen
- (IBAction)cancelButtonTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

// Handles either creating new folder or updating an existing folder
- (IBAction)saveButtonTapped:(id)sender {
    self.theNewFolder.folderName = self.folderNameTextField.text;
    self.theNewFolder.accessInfo.owner = [[NPUser alloc] initWithUser:[[AccountManager instance] getCurrentLoginAcct]];
    
    // Post updated folder
    [self.folderService addOrUpdateFolder:self.theNewFolder];
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
        
        if (self.theNewFolder.sharings == nil) {
            self.theNewFolder.sharings = [[NSMutableArray alloc] init];
        }
        [self.theNewFolder.sharings addObject:accessPermission];
        [self.sharingTableView reloadData];
        
        self.addUserACHelper.userNameOrEmailTextField.text = @"";
        self.addUserACHelper.userEmailLabel.text = @"";
        
    } else {
        NSLog(@"!!!! No valid email defined. This shouldn't happen.");
    }
}

- (void)deleteAccessorButtonTapped:(id)sender {
    AccessPermission *selectedAccessPermission = [self getSelectedAccessPermission:(UIView*)sender];
    [self.theNewFolder.sharings removeObject:selectedAccessPermission];
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
        
    } else {
        NSLog(@"Not able to find the user to change permission...");
    }
}


#pragma mark - Web service delegate

// Update the folder update result
- (void)updateServiceResult:(id)serviceResult {
    if ([serviceResult isKindOfClass:[FolderActionResult class]]) {
        FolderActionResult *actionResponse = (FolderActionResult*)serviceResult;
        
        if ([actionResponse.name isEqualToString:ACTION_ADD_FOLDER]) {
            [NotificationUtil sendFolderAddedNotification:[actionResponse.folder copy]];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)serviceError:(ServiceResult*)serviceResult {
    if (serviceResult.code == NP_WEB_SERVICE_NOT_AVAILABLE) {
        // No need to report the error here.
        return;
    }

    NSString *message = NSLocalizedString(@"There is an error adding new folder.",);
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
    
    if (self.theNewFolder.moduleId == CALENDAR_MODULE) {
        self.navigationItem.title = NSLocalizedString(@"New calendar",);
    } else {
        self.navigationItem.title = NSLocalizedString(@"New folder",);
    }
    
    self.folderService = [[FolderService alloc] init];
    self.folderService.moduleId = self.theNewFolder.moduleId;
    self.folderService.serviceDelegate = self;
    
    self.sharingTableView.delegate = self;
    self.sharingTableView.dataSource = self;
    
    self.sharingTableView.separatorColor = [UIColor clearColor];
    
    SHARING_TABLE_TOP_SPACE = self.sharingTableTopSpaceConstraint.constant;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onKeyboardHide:) name:UIKeyboardWillHideNotification object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = YES;
    
    self.parentFolderNameLabel.text = [self.parentFolder displayName];
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

# pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 77.0;
    }
    return 80.0;;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.theNewFolder.sharings.count + 1;
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
        AccessPermission *shareToUser = [self.theNewFolder.sharings objectAtIndex:indexPath.row - 1];
        
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.sharingTableTopSpaceConstraint.constant = 66.0;
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
    self.sharingTableTopSpaceConstraint.constant = SHARING_TABLE_TOP_SPACE;
}


- (AccessPermission*)getSelectedAccessPermission:(id)sender {
    UIView *view = (UIView*)sender;
    
    //maximum 5 attempts
    for(int i = 0; i < 5; i++) {
        view = view.superview;
        if([view isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)view;
            NSIndexPath *indexPath = [self.sharingTableView indexPathForCell:cell];
            
            if ([self.theNewFolder.sharings objectAtIndex:indexPath.row - 1] != nil) {
                return [self.theNewFolder.sharings objectAtIndex:indexPath.row - 1];
            }
        }
    }
    return nil;
}

@end
