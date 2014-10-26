//
//  ContactViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ContactViewController.h"
#import "EntryEditorTableViewController.h"
#import "PhotoCell.h"
#import "NoteCell.h"
#import "MapViewController.h"
#import "UIImageView+WebCache.h"
#import "UIImageView+NPUtil.h"
#import "UIViewController+KNSemiModal.h"


@interface ContactViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UIImageView *profilePhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;

@property (weak, nonatomic) IBOutlet NoteCell *addressCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagCell;
@property (weak, nonatomic) IBOutlet NoteCell *noteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *webCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *firstNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *middleNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *lastNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *businessCell;

@property BOOL hasTags;
@property BOOL hasNote;
@end

@implementation ContactViewController

@synthesize person = _person;
@synthesize titleCell;
@synthesize profilePhotoImageView;
@synthesize titleTextLabel;
@synthesize addressCell;
@synthesize tagCell;
@synthesize noteCell;
@synthesize webCell;
@synthesize firstNameCell;
@synthesize lastNameCell;
@synthesize businessCell;

// Overwrite EntryViewController method
- (NPEntry*)getCurrentEntry {
    return _person;
}

// Not used
- (void)retrieveEntryDetail {
    [self.entryService getEntryDetail:_person];
}

// Service data retrieval delegate
- (void)updateServiceResult:(id)responseObj {
    [super updateServiceResult:responseObj];

    if ([responseObj isKindOfClass:[NPEntry class]]) {
        _person = [NPPerson personFromEntry:responseObj];
        
        [self updateContactFields];
        [self.tableView reloadData];
    }
}

// This is called in the data service delegate
- (void)setPerson:(NPPerson*)person {
    _person = [person copy];
}

// This is called after successfuly saving the entry in the editor.
- (void)entryUpdateSaved:(NPPerson*)person {
    _person = person;
    [self.tableView reloadData];
}

- (void)updateContactFields {
    if (_person == nil) {
        return;
    }
    if (_person.profileImage != nil) {
        self.profilePhotoImageView.image = _person.profileImage;
        
    } else if (_person.profileImageUrl != nil) {
        NSString *urlStr = [NPWebApiService appendAuthParams:_person.profileImageUrl];
        urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:_person.accessInfo.owner.userId];

        [self.profilePhotoImageView sd_setImageWithURL:[NSURL URLWithString:urlStr]
                                   placeholderImage:[UIImage imageNamed:@"avatar.png"] options:SDWebImageProgressiveDownload];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfilePhoto:)];
        singleTap.delegate = self;
        [self.profilePhotoImageView addGestureRecognizer:singleTap];
        self.profilePhotoImageView.userInteractionEnabled = YES;

        // This is to populate _person.profileImage
        [self loadProfilePhoto:urlStr];
        
    } else {
        self.profilePhotoImageView.image = [UIImage imageNamed:@"avatar.png"];
    }
    
    [UIImageView roundedCorner:self.profilePhotoImageView];
    
    self.titleTextLabel.text = [_person addressBookTitle];
    
    self.firstNameCell.textLabel.text = NSLocalizedString(@"First name",);
    self.firstNameCell.detailTextLabel.text = _person.firstName;
    
    self.middleNameCell.textLabel.text = NSLocalizedString(@"Middle",);
    self.middleNameCell.detailTextLabel.text = _person.middleName;
    
    self.lastNameCell.textLabel.text = NSLocalizedString(@"Last name",);
    self.lastNameCell.detailTextLabel.text = _person.lastName;
    
    self.businessCell.textLabel.text = NSLocalizedString(@"Business",);
    self.businessCell.detailTextLabel.text = _person.businessName;
    
    self.webCell.textLabel.text = NSLocalizedString(@"Web",);
    self.webCell.detailTextLabel.text = [NSString displayUrl:_person.webAddress];
    self.webCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([_person.address getAddressStringForMap] != nil) {
        self.addressCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.addressCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    NSArray *addrArr = [_person.address getAddressInArray];
    NSString *fullAddress = [addrArr componentsJoinedByString:@"\n"];
    self.addressCell.textLabel.text = NSLocalizedString(@"Address",);
    self.addressCell.detailTextLabel.text = fullAddress;
    
    if (_person.note.length > 0) {
        self.noteCell.textLabel.text = _person.note;
    }
    
    // Has to reloadData twice to get the note cell to display properly.
    // I think it is because that layoutSubViews method has to be called.
    // TODO - investigate how to displat the NoteCell properly.
    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return CONTACT_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CONTACT_TITLE_SECTION:
        {
            return self.titleCell.frame.size.height;
        }
        case CONTACT_PHONE_SECTION:
        {
            if (_person.phones != nil) {
                return [_person.phones count] * 44.0;
            }
            break;
        }
        case CONTACT_EMAIL_SECTION:
        {
            if (_person.emails != nil) {
                return [_person.emails count] * 44.0;
            }
            break;
        }
        case CONTACT_ADDRESS_SECTION:
        {
            [self.addressCell layoutSubviews];
            return self.addressCell.frame.size.height;
        }
        case CONTACT_TAG_SECTION:
        {
            float cellHeight = 0;

            if (indexPath.row == 0 && self.hasTags) {
                self.tagCell.textLabel.text = NSLocalizedString(@"Tags",);
                self.tagCell.detailTextLabel.text = _person.tags;
                cellHeight = self.tagCell.frame.size.height;
            }
            
            if (self.hasNote || indexPath.row == 1) {
                self.noteCell.textLabel.text = _person.note;
                [self.noteCell layoutSubviews];
                cellHeight += self.noteCell.frame.size.height;
            }

            return cellHeight;
        }
        default:
            break;
    }
    
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case CONTACT_TITLE_SECTION:
        {
            return self.titleCell;
        }
        case CONTACT_NAME_SECTION:
        {
            if (indexPath.row == 0) {
                return self.firstNameCell;

            } else if (indexPath.row == 1) {
                if (_person.middleName.length > 0) {
                    return self.middleNameCell;
                } else {
                    return self.lastNameCell;   
                }

            } else if (indexPath.row == 2) {
                return self.lastNameCell;
            }
        }
        case CONTACT_BUSINESS_SECTION:
        {
            return self.businessCell;
        }
        case CONTACT_PHONE_SECTION:
        {
            ClickableItemListCell *cell = [[ClickableItemListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell displayValue:nil valueData:_person.phones];
            return cell;
        }
        case CONTACT_EMAIL_SECTION:
        {
            ClickableItemListCell *cell = [[ClickableItemListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            [cell displayValue:nil valueData:_person.emails];
            return cell;
        }
        case CONTACT_ADDRESS_SECTION:
        {
            return self.addressCell;
        }
        case CONTACT_WEB_SECTION:
        {
            return self.webCell;
        }
        case CONTACT_TAG_SECTION:
        {
            if (indexPath.row == 0 && self.hasTags) {
                return self.tagCell;
            }

            if (self.hasNote || indexPath.row == 1) {
                return self.noteCell;
            }
        }
        default:
            break;
    }
    
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case CONTACT_TITLE_SECTION:
        {
            return 1;
        }
        case CONTACT_NAME_SECTION:
        {
            int row = 0;
            if (_person.firstName.length > 0) {
                row++;
            }
            if (_person.middleName.length > 0) {
                row++;
            }
            if (_person.lastName.length > 0) {
                row++;
            }
            return row;
        }   
        case CONTACT_BUSINESS_SECTION:
        {
            if (_person.businessName.length > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case CONTACT_PHONE_SECTION:
        {            
            if (_person.phones != nil && [_person.phones count] > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case CONTACT_EMAIL_SECTION:
        {
            if (_person.emails != nil && [_person.emails count] > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case CONTACT_ADDRESS_SECTION:
        {
            if ([[_person.address getAddressInArray] count] > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case CONTACT_WEB_SECTION:
        {
            if (_person.webAddress.length > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case CONTACT_TAG_SECTION:
        {
            int rows = 0;
            if (_person.tags.length > 0) {
                self.hasTags = YES;
                rows++;
            } else {
                self.hasTags = NO;
            }

            if (_person.note.length > 0) {
                rows++;
                self.hasNote = YES;
            } else {
                self.hasNote = NO;
            }
            
            return rows;
        }
        default:
            break;
    }

    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == CONTACT_ADDRESS_SECTION && indexPath.row == 0 && [_person.address getAddressStringForMap] != nil) {
        [self performSegueWithIdentifier:@"OpenMap" sender:self];
        
    } else if (indexPath.section == CONTACT_WEB_SECTION) {
        if (indexPath.row == 0) {
            NSURL *url = [NSURL URLWithString:[NSString prependHttp:_person.webAddress]];
            if (![[UIApplication sharedApplication] openURL:url]) {
                NSLog(@"%@%@",@"Failed to open url:",[url description]);
            }
        }
    }
}


#pragma - segue to editor, map view
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenContactEditor"]) {
        [segue.destinationViewController setAfterSavingDelegate:self];
        [segue.destinationViewController setPerson:_person];

    } else if ([segue.identifier isEqualToString:@"OpenMap"]) {
        [segue.destinationViewController setMyLocation:_person.address];
    }
}

- (void)loadProfilePhoto:(NSString*)urlString
{
    dispatch_queue_t imageDownloadQ = dispatch_queue_create("PhotoCell downloader", NULL);
    dispatch_async(imageDownloadQ, ^{
        NSURL *imageUrl = [[NSURL alloc] initWithString:urlString];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];

        dispatch_async(dispatch_get_main_queue(), ^{
            _person.profileImage = image;
        });
    });
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleTextLabel.text = _person.title;            // Display something while entry detail is being loaded.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateContactFields];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [self setTitleCell:nil];
    [self setAddressCell:nil];
    [self setTagCell:nil];
    [self setNoteCell:nil];
    [self setWebCell:nil];
    [self setFirstNameCell:nil];
    [self setLastNameCell:nil];
    [self setBusinessCell:nil];
    [self setProfilePhotoImageView:nil];
    [self setTitleTextLabel:nil];
    [self setMiddleNameCell:nil];
    [super viewDidUnload];
}


- (void)openProfilePhoto:(id)sender {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 250, 320)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    NSString *urlStr = [NPWebApiService appendAuthParams:_person.profileImageUrl];
    [imageView sd_setImageWithURL:[NSURL URLWithString:urlStr]
                               placeholderImage:[UIImage imageNamed:@"avatar.png"] options:SDWebImageProgressiveDownload];

    [self presentSemiView:imageView withOptions:@{
                                               KNSemiModalOptionKeys.pushParentBack    : @(YES),
                                               KNSemiModalOptionKeys.animationDuration : @(0.3),
                                               KNSemiModalOptionKeys.shadowOpacity     : @(0.3),
                                               }];
    
}

@end
