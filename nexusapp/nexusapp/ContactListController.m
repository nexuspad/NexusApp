//
//  ContactListController.m
//  nexuspad
//
//  Created by Ren Liu on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <AddressBook/AddressBook.h>

#import "NPServiceNotificationUtil.h"

#import "ContactListController.h"
#import "ContactViewController.h"
#import "ContactEditorViewController.h"
#import "NPPerson.h"
#import "ImageCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "AddressbookService.h"
#import "UIImageView+NPUtil.h"
#import "UIViewController+KNSemiModal.h"


@interface ContactListController()
@property (nonatomic, strong) ContactListController *childFolderContactsListController;
@property (nonatomic, strong) NSMutableArray *peopleBySections;
@property (nonatomic, strong) UILabel *emptyListLabel;
@end

@implementation ContactListController
@synthesize peopleBySections = _peopleBySections, entryListTable = _entryListTable;

#pragma mark - data service delegate

- (void)retrieveEntryList {
    [super retrieveEntryList];

    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:contact];
    }
    
    self.navigationItem.title = [self.currentFolder displayName];
    
    [self.entryListService getEntries:self.currentEntryList.templateId
                             inFolder:[self.currentFolder copy]
                               pageId:0
                         countPerPage:self.currentEntryList.countPerPage];
}

- (void)updateServiceResult:(id)serviceResult {
    [super updateServiceResult:serviceResult];

    if ([serviceResult isKindOfClass:[EntryList class]]) {
        self.currentEntryList = serviceResult;
        
        [self refreshListTable];

        if ([self.currentEntryList isNotEmpty]) {
            [self.emptyListLabel removeFromSuperview];

        } else {
            [self.entryListTable addSubview:self.emptyListLabel];
        }
    }
}

- (void)refreshListTable {
    UILocalizedIndexedCollation *theCollation = [UILocalizedIndexedCollation currentCollation];

    NSMutableArray *people = [[NSMutableArray alloc] init];
    for (NPEntry *entry in self.currentEntryList.entries) {
        NPPerson *p = [NPPerson personFromEntry:entry];
        NSInteger sect = [theCollation sectionForObject:p collationStringSelector:@selector(sectionKey)];
        p.sectionNumber = sect;
        [people addObject:p];
    }
    
    // create high part of the sectioned array
    NSInteger highSection = [[theCollation sectionTitles] count];
    NSMutableArray *sectionArrays = [NSMutableArray arrayWithCapacity:highSection];
    for (int i=0; i<highSection; i++) {
        NSMutableArray *sectionArr = [[NSMutableArray alloc] init];
        [sectionArrays addObject:sectionArr];
    }
    
    // populate the sectioned array with detail elements
    for (NPPerson *p in people) {
        [[sectionArrays objectAtIndex:p.sectionNumber] addObject:p];
    }
    
    // init the peopleBySection and add the sorted sections
    NSMutableArray *contactsBySections = [[NSMutableArray alloc] initWithCapacity:highSection];
    
    // sort the section array by feature id
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"sectionKey" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil];
    
    for (NSMutableArray *sectionArr in sectionArrays) {
        NSArray *sortedSectionMembers = [sectionArr sortedArrayUsingDescriptors:sortDescriptors];
        [contactsBySections addObject:[NSMutableArray arrayWithArray:sortedSectionMembers]];
    }
        
    _peopleBySections = [contactsBySections copy];
    [_entryListTable reloadData];
}

- (IBAction)addButtonTapped:(id)sender {
    [self performSegueWithIdentifier:@"NewContact" sender:self];
}

- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    if (self.childFolderContactsListController == nil) {
        self.childFolderContactsListController = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactList"];
    }
    
    [self.childFolderContactsListController setCurrentFolder:[selectedFolder copy]];
    [self.navigationController pushViewController:self.childFolderContactsListController animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)person
{
    if ([segue.identifier isEqualToString:@"OpenContact"]) {
        ContactViewController *viewController = (ContactViewController*)segue.destinationViewController;
        viewController.person = person;

    } else if ([segue.identifier isEqualToString:@"NewContact"]) {
        ContactEditorViewController* editorController = (ContactEditorViewController*)[segue destinationViewController];
        NPPerson *newContact = [[NPPerson alloc] init];
        newContact.folder = [self.currentFolder copy];
        newContact.folder.folderId = self.currentFolder.folderId;
        newContact.accessInfo = [self.currentFolder.accessInfo copy];
        editorController.person = newContact;
    }
}

- (NPPerson*)getPersonByIndexPath:(UITableView*)tableView indexPath:(NSIndexPath*)indexPath {
    NPPerson *p = nil;
    if ([self isSearchTableView:tableView]) {
        p = [NPPerson personFromEntry:[self.searchResultList.entries objectAtIndex:indexPath.row]];
        
    } else {
        p = [[self.peopleBySections objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
    }
    
    return p;
}

#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    // Search local
    return;
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isSearchTableView:tableView]) {
        return 1;
    }
    return [self.peopleBySections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isSearchTableView:tableView]) {
        return [self.searchResultList.entries count];
    }
    return [[self.peopleBySections objectAtIndex:section] count];
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([[self.peopleBySections objectAtIndex:section] count] > 0) {
        return [[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles] objectAtIndex:section];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NPPerson *p = [self getPersonByIndexPath:tableView indexPath:indexPath];

    if ([p hasProfilePhoto]) {
        static NSString *CellIdentifier = @"ContactPhotoDetailCell";

        UITableViewCell *cell = [self.entryListTable dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        
        [UIImageView roundedCorner:imageView];
        
        if (p.profileImage != nil) {
            imageView.image = p.profileImage;
            
        } else if ([NSString isNotBlank:p.profileImageUrl]) {
            NSString *imageUrl = [NPWebApiService appendAuthParams:p.profileImageUrl];
            imageUrl = [NPWebApiService appendOwnerParam:imageUrl ownerId:p.accessInfo.owner.userId];
            [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrl]
                      placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                               options:SDWebImageRetryFailed];
        } else {
            imageView.image = [UIImage imageNamed:@"placeholder.png"];
        }
        
        cell.textLabel.text = [NSString stringWithString:[p addressBookTitle]];
        cell.accessoryView = imageView;
        
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

        cell.textLabel.backgroundColor = [UIColor whiteColor];

        return cell;

    } else {
        static NSString *CellIdentifier = @"ContactDetailCell";
        
        UITableViewCell *cell = [self.entryListTable dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = [NSString stringWithString:[p addressBookTitle]];
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

        cell.textLabel.backgroundColor = [UIColor whiteColor];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    NPPerson *p = [self getPersonByIndexPath:tableView indexPath:indexPath];
    if ([p hasProfilePhoto]) {
        return 55.0;
    }
    return 44.0;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.sharersMenu != nil && [self.sharersMenu isMenuOpen]) {
        return;
    }
    
    NPPerson *p = [self getPersonByIndexPath:tableView indexPath:indexPath];
    if (p != nil) {
        [self performSegueWithIdentifier:@"OpenContact" sender:p];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the entry at row
        NPPerson *deletePerson = [[[self.peopleBySections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] copy];
        [[self.peopleBySections objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
        [self.entryService deleteEntry:deletePerson];
        [NotificationUtil sendEntryDeletedNotification:deletePerson];
        [self.entryListTable reloadData];
    }    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // empty label
    CGRect rect = self.entryListTable.frame;
    rect.origin.x = 12.0;
    rect.origin.y = 44.0;
    rect.size.height = 44.0;
    
    if (self.emptyListLabel == nil) {
        self.emptyListLabel = [[UILabel alloc] init];
        if (self.currentFolder.folderId == ROOT_FOLDER) {
            self.emptyListLabel.text = NSLocalizedString(@"No contact has been added.",);
        } else {
            self.emptyListLabel.text = NSLocalizedString(@"No contact in this folder.",);
        }
        
        self.emptyListLabel.textColor = [UIColor lightGrayColor];
    }
    self.emptyListLabel.frame = rect;
    
    // refresh entry list
    if (self.currentEntryList == nil) {
        [self retrieveEntryList];
    }
    
    // If the contact sync option has not been set
    if (![AddressbookService isPhoneContactSyncOptionSet]) {
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            
            if (addressBook != nil) {
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    if (granted) {
                        [AddressbookService syncPhoneContact:YES];
                        [[AddressbookService instance] start];
                        
                    } else {
                        [AddressbookService syncPhoneContact:NO];
                    }
                });
            }
            
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            [AddressbookService syncPhoneContact:YES];
            [[AddressbookService instance] checkLastSyncTimeAndStart];
            
        } else {
            // The user has previously denied access. There is nothing to be done here.
            [AddressbookService syncPhoneContact:NO];
        }
        
    } else {
        // The sync option is set. And the permission to access contact is allowed. We sync.
        if ([AddressbookService syncPhoneContactAllowed]) {
            [[AddressbookService instance] checkLastSyncTimeAndStart];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }

    [self initPullRefresh:self.entryListTable];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceDataRefresh:) name:N_DATA_REFRESHED object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_DATA_REFRESHED object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.childFolderContactsListController = nil;
}

// Just filter the existing rows
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    NSPredicate *resultPredicate = [NSPredicate
                                    predicateWithFormat:@"searchKey contains[cd] %@",
                                    searchText];
    
    if (self.searchResultList == nil) {
        self.searchResultList = [[EntryList alloc] init];
    }
    self.searchResultList.entries = [NSMutableArray arrayWithArray:[self.currentEntryList.entries filteredArrayUsingPredicate:resultPredicate]];
}


// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }

    } else {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }
    self.toolbarItems = items;
}


#pragma mark - notifications handling

// ONLY handles entry add/update/delete action notifications
- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPPerson class]]) {
        
        NPPerson *updatedPerson = (NPPerson*)notification.object;
        
        if (updatedPerson.folder.moduleId != CONTACT_MODULE) {
            DLog(@"No action to take. This is for a different list view controller. my module Id:%i, other module Id:%i, my folder id:%i, other folder id:%i", self.currentFolder.moduleId, updatedPerson.folder.moduleId, self.currentFolder.folderId, updatedPerson.folder.folderId);
            return;
        }
        
        DLog(@"ContactListController received notification for module %i received entry list updated: %@",
             self.currentFolder.moduleId, updatedPerson);
        
        NPEntry *affectedEntryInList = nil;
        
        for (NPEntry *entry in self.currentEntryList.entries) {
            if ([entry.entryId isEqualToString:updatedPerson.entryId]) {
                affectedEntryInList = entry;
                break;
            }
        }
        
        if (affectedEntryInList == nil) {                                       // This is a new entry
            [self.currentEntryList addToTopOfList:updatedPerson];
            [self refreshListTable];
            
        } else {                                                                // Update an existing entry in the list: title and color label.
            [self.currentEntryList deleteFromList:affectedEntryInList];
            [self.currentEntryList addToTopOfList:updatedPerson];
            [self refreshListTable];
        }
    }
}


- (void)handleServiceDataRefresh:(NSNotification*)notification {
    DLog(@"Received service data refresh notification. Refresh entry list...");
    [self retrieveEntryList];
}


@end
