//
//  SettingsViewController.m
//  nexuspad
//
//  Created by Ren Liu on 8/26/12.
//
//

#import "StartViewController.h"
#import "SettingsViewController.h"
#import "WebPageViewController.h"
#import "AccountService.h"
#import "AccountManager.h"
#import "UserPrefUtil.h"
#import "NSString+NPStringUtil.h"
#import "DateUtil.h"
#import "SyncDownService.h"
#import "OAuthViewController.h"
#import "AddressbookService.h"
#import "ProfilePhotoService.h"
#import "DataStore.h"
#import "ViewDisplayHelper.h"
#import <AddressBook/AddressBook.h>


@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *contactSyncCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *googleSyncCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *emailCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *touCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *spaceUsageCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *lastSyncTimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *emailSupportCell;

@property (nonatomic, strong) UISwitch *googleServiceSwitch;
@property (nonatomic, strong) UISwitch *contactSyncSwitch;

@property (nonatomic, strong) Account *account;
@property (nonatomic, strong) AccountService *acctService;

@property (nonatomic, strong) PhotoHelper *photoHelper;

@end

@implementation SettingsViewController
@synthesize emailCell;
@synthesize touCell;
@synthesize spaceUsageCell;
@synthesize emailSupportCell;

- (void)updateServiceResult:(id)serviceResult
{
    if ([serviceResult isKindOfClass:[Account class]]) {
        // Contact sync
        self.account = (Account*)serviceResult;

        if ([AddressbookService syncPhoneContactAllowed] && [self isAddressBookAuthorized]) {
            self.account.externalService.phoneContactSync = YES;
        } else {
            self.account.externalService.phoneContactSync = NO;
        }

        [self.tableView reloadData];

        NSString *profileImageUrlForEditing = [self.account profileImageUrlForEditing];
        
        if (self.photoHelper == nil) {
            CGRect rect = CGRectMake(self.view.frame.size.width - 56.0, 16.0, 48.0, 48.0);
            
            if (profileImageUrlForEditing != 0) {
                self.photoHelper = [[PhotoHelper alloc] initWithExistingPhoto:profileImageUrlForEditing isPlaceHolder:NO rect:rect];
            } else {
                self.photoHelper = [[PhotoHelper alloc] initWithExistingPhoto:[UIImage imageNamed:@"avatar.png"] isPlaceHolder:YES rect:rect];
            }
            
            self.photoHelper.photoUpdateDelegate = self;
            [self.view addSubview:self.photoHelper.photoImageView];

        } else {
            if (profileImageUrlForEditing.length != 0) {
                [self.photoHelper updatePhoto:profileImageUrlForEditing];
            }
        }
    }
}

- (void)serviceError:(id)serviceResult {
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenTOU"]) {
        [segue.destinationViewController setPageUrl:@"/page/termsofuse?mobile"];

    } else if ([segue.identifier isEqualToString:@"OAuthAuthorization"]) {
        OAuthViewController *viewController = (OAuthViewController*)segue.destinationViewController;
        viewController.externalService = self.account.externalService;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = NSLocalizedString(@"Settings",);
    self.navigationController.toolbarHidden = YES;
    
    // Do this in appear to get the latest info when returning from OAuthViewController
    [self.acctService getSettingsAndUsageInfo:self.account];
    
    if (![NPService isServiceAvailable]) {
        [ViewDisplayHelper displayWarningMessage:NSLocalizedString(@"No Internet connection",)
                                         message:NSLocalizedString(@"Connect to the Internet to change settings",)];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.acctService == nil) {
        self.acctService = [[AccountService alloc] init];
        self.acctService.serviceDelegate = self;
    }
    
    self.account = [[AccountManager instance] getCurrentLoginAcct];
}

- (void)viewDidUnload
{
    [self setEmailCell:nil];
    [self setTouCell:nil];
    [self setSpaceUsageCell:nil];
    self.emailSupportCell = nil;
    [super viewDidUnload];
}

- (void)updateGoogleSyncState:(id)sender {
    if ([sender isOn]) {
        // Turn on the google service
        if (self.account.externalService.googleOauthUrl != nil) {
            // Try to authorize
            [self performSegueWithIdentifier:@"OAuthAuthorization" sender:self];
        }

    } else {
        // Turn off the google service
        [self.acctService turnOffExternalService:@"google"];
    }
}

- (void)updatePhoneContactSyncState:(id)sender {
    if ([sender isOn]) {                                    // Sync is turned on
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            
            if (addressBook == nil) {
                return;
            }

            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    self.account.externalService.phoneContactSync = YES;
                    [AddressbookService syncPhoneContact:YES];
                    [self.tableView reloadData];
                    [[AddressbookService instance] start];
                    
                } else {
                    self.account.externalService.phoneContactSync = NO;
                    [AddressbookService syncPhoneContact:NO];
                    [self.contactSyncSwitch setOn:NO];
                    [self.tableView reloadData];
                }
            });
            
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            self.account.externalService.phoneContactSync = YES;
            [AddressbookService syncPhoneContact:YES];
            [self.tableView reloadData];
            [[AddressbookService instance] start];

        } else {
            // The user has previously denied access
            // Send an alert telling user to change privacy setting in settings app
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Contact Access Denied",)
                                                                 message:NSLocalizedString(@"Please go to Settings/Privacy to turn on contact access.",)
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"OK",), nil];
            [alertView show];
            
            self.account.externalService.phoneContactSync = NO;
            [self.contactSyncSwitch setOn:NO];
            [self.tableView reloadData];
        }
        
    } else {                                                // Sync is turned off
        self.account.externalService.phoneContactSync = NO;
        [AddressbookService syncPhoneContact:NO];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 4) {
        return 2;
    }
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = NSLocalizedString(@"Account",);
            break;
        case 1:
            sectionName = NSLocalizedString(@"Link Google Calendar",);
            break;
        case 2:
            sectionName = NSLocalizedString(@"Backup Phone Contact",);
            break;
        case 3:
            sectionName = NSLocalizedString(@"Last synced with nexuspad.com",);
            break;
        case 4:
            sectionName = NSLocalizedString(@"Support",);
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.emailCell.textLabel.text = self.account.email;
            return self.emailCell;

        } else if (indexPath.row == 1) {
            float percent = 0.0;
            if (self.account.spaceAllocation != 0) {
                percent = 100 * (self.account.spaceUsage/self.account.spaceAllocation);
            }
            
            self.spaceUsageCell.textLabel.text = [NSString stringWithFormat:@"%@: %.1f%% out of %@",
                                                  NSLocalizedString(@"Usage",), percent, [NSString displayBytes:self.account.spaceAllocation]];
            
            return self.spaceUsageCell;
        }
    
    } else if (indexPath.section == 1) {
        self.googleServiceSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        
        [self.googleServiceSwitch addTarget:self action:@selector(updateGoogleSyncState:) forControlEvents:UIControlEventValueChanged];

        if (self.account.externalService.googleOauthed) {
            self.googleSyncCell.textLabel.text = NSLocalizedString(@"Enabled",);
            [self.googleServiceSwitch setOn:YES animated:NO];
        } else {
            self.googleSyncCell.textLabel.text = NSLocalizedString(@"Disabled",);
            [self.googleServiceSwitch setOn:NO animated:NO];
        }
        
        self.googleSyncCell.accessoryView = self.googleServiceSwitch;

        return self.googleSyncCell;

    } else if (indexPath.section == 2) {
        self.contactSyncSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        
        [self.contactSyncSwitch addTarget:self action:@selector(updatePhoneContactSyncState:) forControlEvents:UIControlEventValueChanged];
        
        if (self.account.externalService.phoneContactSync) {
            [self.contactSyncSwitch setOn:YES animated:NO];
            
            double syncTimeStamp = [[AddressbookService instance] getLastPhoneContactsSyncTime];
            if (syncTimeStamp != 0) {
                NSDate *lastSyncTime = [NSDate dateWithTimeIntervalSince1970:syncTimeStamp];
                NSString *localDateStr = [NSDateFormatter localizedStringFromDate:lastSyncTime dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
                
                self.contactSyncCell.textLabel.text = [NSString stringWithFormat:@"%@", localDateStr];
                
            } else {
                self.contactSyncCell.textLabel.text = NSLocalizedString(@"Enabled",);
            }
            
            self.contactSyncCell.textLabel.adjustsFontSizeToFitWidth = YES;
            
        } else {
            self.contactSyncCell.textLabel.text = NSLocalizedString(@"Disabled",);
            [self.contactSyncSwitch setOn:NO animated:NO];
        }
        
        self.contactSyncCell.accessoryView = self.contactSyncSwitch;
        return self.contactSyncCell;
        
    } else if (indexPath.section == 3) {
        double syncTimeStamp = [[SyncDownService instance] getLastSyncTime];
        if (syncTimeStamp != 0) {
            NSDate *lastSyncTime = [NSDate dateWithTimeIntervalSince1970:syncTimeStamp];
            NSString *localDateStr = [NSDateFormatter localizedStringFromDate:lastSyncTime dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
            
            self.lastSyncTimeCell.textLabel.text = [NSString stringWithFormat:@"%@", localDateStr];
            
        } else {
            self.lastSyncTimeCell.textLabel.text = @"";
        }
        
        self.lastSyncTimeCell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [resetButton setTitle:NSLocalizedString(@"Reset",) forState:UIControlStateNormal];
        [resetButton addTarget:self action:@selector(resetSyncTime) forControlEvents:UIControlEventTouchUpInside];
        [resetButton setFrame:CGRectMake(0, 0, 100, 35)];
        self.lastSyncTimeCell.accessoryView = resetButton;

        return self.lastSyncTimeCell;

    } else if (indexPath.section == 4) {
        if (indexPath.row == 0) {
            //self.inviteCell.textLabel.text = NSLocalizedString(@"Invite friend",);
            self.emailSupportCell.textLabel.text = NSLocalizedString(@"Email support",);
            return self.emailSupportCell;

        } else if (indexPath.row == 1) {
            self.touCell.textLabel.text = NSLocalizedString(@"Terms of service",);
            return self.touCell;
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 4 && indexPath.row == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://support@nexuspad.com"]];
    }
}

- (void)resetSyncTime {
    // Clear the local data store
    DataStore *dataStore = [[DataStore alloc] init];
    [dataStore clearAllOfflineItems];

    [[SyncDownService instance] resetLastSyncTime];
    [self.tableView reloadData];
    [[SyncDownService instance] start];
}

- (IBAction)logout:(id)sender
{
    DLog(@"Log out of session...");
    [[AccountManager instance] logout];
    
    StartViewController *startView = [self.storyboard instantiateViewControllerWithIdentifier:@"StartView"];
    [self.navigationController setViewControllers:[NSArray arrayWithObject:startView] animated:NO];
}


- (BOOL)isAddressBookAuthorized {
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (addressBook == nil) {
        return NO;
    }

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        CFRelease(addressBook);
        return YES;
    }
    
    CFRelease(addressBook);
    return NO;
}


#pragma mark - photo update delegate

- (void)didDeletedPhoto {
    ProfilePhotoService *photoService = [[ProfilePhotoService alloc] init];
    [photoService deleteMyProfilePhoto];
    [self.photoHelper setToDefaultPlaceholder];
}


- (void)didSelectedPhoto:(UIImage *)selectedPhoto {
    NSData *imageData = UIImagePNGRepresentation(self.photoHelper.photoImageView.image);
    NSString *fileName = [NSString stringWithFormat:@"avatar_photo.png"];

    ProfilePhotoService *photoService = [[ProfilePhotoService alloc] init];
    [photoService addMyProfilePhoto:imageData fileName:fileName];
}

@end
