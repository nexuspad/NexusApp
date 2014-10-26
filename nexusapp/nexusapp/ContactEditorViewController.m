//
//  ContactEditorController.m
//  nexuspad
//
//  Created by Ren Liu on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ContactEditorViewController.h"
#import "AddressEditorViewController.h"
#import "NPPerson.h"
#import "BasicItemInputCell.h"
#import "UIImage+Resize.h"
#import "ProfilePhotoService.h"


@interface ContactEditorViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UIImageView *profilePhotoImageView;

@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *middleNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *businessNameTextField;

@property (weak, nonatomic) IBOutlet UITextField *webAddressTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet TextViewWithPlaceHolder *noteTextView;


@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *firstNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *lastNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *businessNameCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *addressCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *webAddressCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *noteCell;

@property (nonatomic, strong) UIImagePickerController *photoPicker;
@property BOOL hasProfilePhoto;
@property BOOL profilePhotoUpdated;
@property BOOL profilePhotoDeleted;
@property (nonatomic, strong) BasicItemInputCell *phoneListCell;
@property (nonatomic, strong) BasicItemInputCell *emailListCell;

@property (nonatomic, strong) PhotoHelper *photoHelper;
@end


@implementation ContactEditorViewController
@synthesize titleTextField;
@synthesize firstNameTextField;
@synthesize middleNameTextField;
@synthesize lastNameTextField;
@synthesize businessNameTextField;
@synthesize webAddressTextField;
@synthesize tagsTextField;
@synthesize noteTextView;
@synthesize titleCell;
@synthesize firstNameCell;
@synthesize lastNameCell;
@synthesize businessNameCell;
@synthesize addressCell;
@synthesize webAddressCell;
@synthesize tagsCell;
@synthesize noteCell;

@synthesize person = _person;

- (NPEntry*)currentEditedEntry {
    return _person;
}

- (void)setPerson:(NPPerson *)person {
    _person = [person copy];
    
    if (self.person.profileImageUrl != nil) {
        self.hasProfilePhoto = YES;
    } else {
        self.hasProfilePhoto = NO;
    }
    
    [self.tableView reloadData];
}

- (IBAction)saveContact:(id)sender {
    [self.tableView endEditing:YES];
    
    // Clear the old values
    [self.person.featureValuesDict removeAllObjects];

    self.person.title = self.titleTextField.text;
    self.person.firstName = self.firstNameTextField.text;
    self.person.middleName = self.middleNameTextField.text;
    self.person.lastName = self.lastNameTextField.text;
    self.person.businessName = self.businessNameTextField.text;
    self.person.tags = self.tagsTextField.text;
    self.person.note = self.noteTextView.text;
    self.person.webAddress = self.webAddressTextField.text;
    
    // Set the phones
    NSMutableArray *phones = [[NSMutableArray alloc] init];
    for (NPItem *item in self.phoneListCell.itemListArr) {
        if (![NSString isBlank:item.value]) {
            [phones addObject:item];
        }
    }
    self.person.phones = [NSMutableArray arrayWithArray:phones];

    // Set the emails
    NSMutableArray *emails = [[NSMutableArray alloc] init];
    for (NPItem *item in self.emailListCell.itemListArr) {
        if (![NSString isBlank:item.value]) {
            [emails addObject:item];
        }
    }
    self.person.emails = [NSMutableArray arrayWithArray:emails];
    
    if (self.profilePhotoDeleted) {
        ProfilePhotoService *photoService = [[ProfilePhotoService alloc] init];
        [photoService deleteContactPhoto:self.person.entryId ownerId:self.person.accessInfo.owner.userId];
    }

    [super postEntry:self.person];
}


// Result of saving the contact
- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[EntryActionResult class]]) {

        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        if (actionResponse.success) {
            
            if (actionResponse.entry != nil) {
                self.person.entryId = actionResponse.entry.entryId;
            }
            
            // Upload the updated profile photo if it has been changed

            if (self.person.profileImage != nil && self.profilePhotoUpdated) {
                ProfilePhotoService *uploader = [[ProfilePhotoService alloc] init];
                NSData *imageData = UIImagePNGRepresentation(self.person.profileImage);
                NSString *fileName = [NSString stringWithFormat:@"profile_%@.png", self.person.entryId];
                [uploader addPhotoToContact:imageData fileName:fileName toEntry:self.person];
                
                // We also need to delete the original attachment if there is one
                if (self.person.attachments != nil && [self.person.attachments count] > 0) {
                    NPUpload *originalPhotoAtt = [self.person.attachments objectAtIndex:0];
                    [self.entryService deleteAttachment:originalPhotoAtt];
                    self.person.attachments = nil;
                }
            }

            if (self.afterSavingDelegate != nil) {
                [self.afterSavingDelegate entryUpdateSaved:self.person];
            }
            
            [NotificationUtil sendEntryUpdatedNotification:self.person];
            [self cancelEditor:nil];
        }
    }
}

// Delegate to update the contact address
- (void)updateContactAddress:(NPLocation*)address {
    if (self.person.address == nil) {
        self.person.address = [[NPLocation alloc] init];
    }
    self.person.address = [address copy];
    [self displayAddress];
    [self.tableView reloadData];
}

- (void)displayAddress {
    NSArray *addrArr = [self.person.address getAddressInArray];
    
    if ([addrArr count] > 0) {
        NSString *fullAddress = [addrArr componentsJoinedByString:@" "];
        self.addressCell.textLabel.text = fullAddress;
        self.addressCell.textLabel.numberOfLines = [addrArr count];
        self.addressCell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
    } else {
        self.addressCell.textLabel.text = NSLocalizedString(@"Address",);
    }
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CONTACT_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {     
    switch (indexPath.section) {
        case CONTACT_TITLE_SECTION:
            return 72.0;

        case CONTACT_NAME_SECTION:
        case CONTACT_BUSINESS_SECTION:
            return 44.0;

        case CONTACT_PHONE_SECTION:
        {
            if (self.phoneListCell == nil) {
                return ([self.person.phones count] + 1) * 44.0;
            } else {
                return [self.phoneListCell.itemListArr count] * 44.0;
            }
            return 44.0;
        }
        case CONTACT_EMAIL_SECTION:
        {
            if (self.emailListCell == nil) {
                return ([self.person.emails count] + 1) * 44.0;
            } else {
                return [self.emailListCell.itemListArr count] * 44.0;
            }
            return 44.0;
        }            
        case CONTACT_ADDRESS_SECTION:
        {
            NSArray *addrArr = [self.person.address getAddressInArray];
            if ([addrArr count] > 0) {
                return (44.0 + ([[self.person.address getAddressInArray] count] - 1) * 19.0);
            } else {
                return 44.0;
            }
        }
        case CONTACT_WEB_SECTION:
            return 44.0;

        case CONTACT_TAG_SECTION:
            if (indexPath.row == 0) {
                return self.tagsCell.frame.size.height;
            } else if (indexPath.row == 1) {
                return self.noteCell.frame.size.height;
            }
            break;
            
        default:
            break;
    }
    
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CONTACT_TITLE_SECTION:
        {
            if (self.photoHelper == nil) {
                CGRect rect = CGRectMake(4.0, 4.0, 64.0, 64.0);
                if (self.person.profileImage != nil) {
                    self.photoHelper = [[PhotoHelper alloc] initWithExistingPhoto:self.person.profileImage isPlaceHolder:NO rect:rect];
                } else {
                    self.photoHelper = [[PhotoHelper alloc] initWithExistingPhoto:[UIImage imageNamed:@"avatar.png"] isPlaceHolder:YES rect:rect];
                }
                self.photoHelper.photoUpdateDelegate = self;
                [self.titleCell.contentView addSubview:self.photoHelper.photoImageView];
            }

            return self.titleCell;
        }
        case CONTACT_NAME_SECTION:
        {
            if (indexPath.row == 0) {
                return self.firstNameCell;
                
            } else if (indexPath.row == 1) {
                return self.lastNameCell;
            }
        }
        case CONTACT_BUSINESS_SECTION:
        {
            return self.businessNameCell;
        }
        case CONTACT_PHONE_SECTION:
        {
            return self.phoneListCell;
        }
        case CONTACT_EMAIL_SECTION:
        {
            return self.emailListCell;
        }              
        case CONTACT_ADDRESS_SECTION:
        {
            return self.addressCell;
        }
        case CONTACT_WEB_SECTION:
        {
            return self.webAddressCell;
        }
        case CONTACT_TAG_SECTION:
        {
            if (indexPath.row == 0) {
                return self.tagsCell;
                
            } else if (indexPath.row == 1) {
                return self.noteCell;
            }
        }
        default:
            break;
    }
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CONTACT_TITLE_SECTION:
            return 1;
        case CONTACT_NAME_SECTION:
            return 2;
        case CONTACT_BUSINESS_SECTION:
        case CONTACT_PHONE_SECTION:
        case CONTACT_EMAIL_SECTION:    
        case CONTACT_ADDRESS_SECTION:
        case CONTACT_WEB_SECTION:
            return 1;
        case CONTACT_TAG_SECTION:
            return 2;
        default:
            break;
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CONTACT_ADDRESS_SECTION) {
        [self performSegueWithIdentifier:@"ShowAddressEditor" sender:self];
    }
}

- (void)inputListChanged:(BasicItemInputCell*)inputCell
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma - segue to address editor
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.view endEditing:YES];

    if ([segue.identifier isEqualToString:@"ShowAddressEditor"]) {
        [segue.destinationViewController setAddress:[self.person.address copy]];
        [segue.destinationViewController setEntryUpdateDelegate:self];
        self.navigationController.toolbarHidden = YES;
    }
}

#pragma mark - profile photo delegate

- (void)didDeletedPhoto {
    self.person.attachments = nil;
    self.person.profileImage = nil;
    self.person.profileImageUrl = nil;

    self.hasProfilePhoto = NO;
    self.profilePhotoDeleted = YES;
}

- (void)didSelectedPhoto:(UIImage *)selectedPhoto {
    self.person.profileImage = selectedPhoto;
    self.profilePhotoUpdated = YES;
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction
{
    [super didSelectFolder:selectedFolder forAction:forAction];
    self.person.folder = [selectedFolder copy];
    self.person.folder.folderId = selectedFolder.folderId;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.noteTextView.placeholder = NSLocalizedString(@"Note",);
    
    self.titleTextField.text = [self.person addressBookTitle];
    self.firstNameTextField.text = self.person.firstName;
    self.lastNameTextField.text = self.person.lastName;
    self.middleNameTextField.text = self.person.middleName;
    self.businessNameTextField.text = self.person.businessName;
    self.webAddressTextField.text = self.person.webAddress;
    self.tagsTextField.text = self.person.tags;
    self.noteTextView.text = self.person.note;
    
    [self displayAddress];

    if (self.phoneListCell == nil) {
        self.phoneListCell = [[BasicItemInputCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        self.phoneListCell.parentTableSection = CONTACT_PHONE_SECTION;
        self.phoneListCell.parentTableRow = 0;
        self.phoneListCell.delegate = self;
        [self.phoneListCell displayInput:self.person.phones itemType:PhoneItem];
    }
    
    if (self.emailListCell == nil) {
        self.emailListCell = [[BasicItemInputCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        self.emailListCell.parentTableSection = CONTACT_EMAIL_SECTION;
        self.emailListCell.parentTableRow = 0;
        self.emailListCell.delegate = self;
        [self.emailListCell displayInput:self.person.emails itemType:EmailItem];
    }
}

- (void)viewDidUnload
{
    [self setTitleTextField:nil];
    [self setFirstNameTextField:nil];
    [self setMiddleNameTextField:nil];
    [self setLastNameTextField:nil];
    [self setBusinessNameTextField:nil];
    [self setAddressCell:nil];
    [self setWebAddressTextField:nil];
    [self setTagsTextField:nil];
    [self setNoteTextView:nil];
    [self setTitleCell:nil];
    [self setFirstNameCell:nil];
    [self setLastNameCell:nil];
    [self setBusinessNameCell:nil];
    [self setWebAddressCell:nil];
    [self setTagsCell:nil];
    [self setNoteCell:nil];
    [self setProfilePhotoImageView:nil];
    [super viewDidUnload];
}

@end
