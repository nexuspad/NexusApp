//
//  NoteListController.m
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocListController.h"
#import "DocNoteViewController.h"
#import "DocNoteEditorViewController.h"
#import "UITableViewCell+NPUtil.h"
#import "NPUploadHelper.h"
#import "NPServiceNotificationUtil.h"
#import "NPEntry+Attribute.h"

#define ADD_PICTURE_NOTE_ACTION_SHEET     41

@interface DocListController ()
@property (nonatomic, strong) DocListController *childFolderDocListController;
@property (nonatomic, strong) UIImagePickerController *photoPicker;
@property (nonatomic, strong) UIImagePickerController *cameraPicker;

@property BOOL allowUploading;
@end

@implementation DocListController

- (void)retrieveEntryList {
    [super retrieveEntryList];

    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:[NPModule defaultTemplate:self.currentFolder.moduleId]];
    }
    
    self.navigationItem.title = [self.currentFolder displayName];
    
    [self.entryListService getEntries:self.currentEntryList.templateId inFolder:self.currentFolder pageId:1 countPerPage:self.currentEntryList.countPerPage];
}

// Basic handling of Service Result. Only handles EntryList result.
- (void)updateServiceResult:(id)serviceResult
{
    [super updateServiceResult:serviceResult];

    /*
     * 1. Load the regular returned entry list into table. Load more is handled in EntryListFolderViewController
     * 2. Handle "load more" for search result.
     */
    
    if ([serviceResult isKindOfClass:[EntryList class]]) {
        EntryList *returnedList = (EntryList*)serviceResult;
        
        if ([returnedList isFolderListResult]) {                                           // Regular listing result
            if ([returnedList isNotEmpty]) {
                [self.emptyListLabel removeFromSuperview];

                if (returnedList.pageId <= 1) {
                    self.currentEntryList = [returnedList copy];
                    DLog(@"Initial query result %@", [self.currentEntryList description]);
                    
                    [self.entryListTable reloadData];
                    
                    // Tug the search bar under only for non-root folder listing.
                    if (self.currentEntryList.folder.folderId != 0) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentEntryList.countPerPage*(returnedList.pageId-1) inSection:0];
                        
                        if (indexPath.row < [self.currentEntryList.entries count]) {
                            [self.entryListTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                        }
                    }
                    
                } else {
                    [self.currentEntryList.entries addObjectsFromArray:returnedList.entries];
                    DLog(@"More query, current list: %@", [self.currentEntryList description]);
                    
                    [self.entryListTable reloadData];
                }
                
            } else {
                [self.entryListTable addSubview:self.emptyListLabel];

                self.currentEntryList = [returnedList copy];
                [self.entryListTable reloadData];
            }
            
        } else {                                                                        // Search result
            
            if (self.searchResultList == nil) {
                self.searchResultList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:doc];
            }
            
            if (returnedList.pageId > 1) {
                [self.searchResultList.entries addObjectsFromArray:returnedList.entries];
                DLog(@"More search query %@", [returnedList description]);
                
            } else {
                self.searchResultList = [returnedList copy];
                DLog(@"Initial search query %@", [self.searchResultList description]);
            }
            
            [self unDimSearchTable];
            [self.listSearchDisplayController.searchResultsTableView reloadData];
        }
    }
}


// This is called in EntryListFolderViewController (ADD_ACTION_SHEET)
- (void)createNewEntry {
    [self performSegueWithIdentifier:@"NewDoc" sender:self];
}


- (IBAction)addPictureNoteButtonTapped:(id)sender {
    if (!self.allowUploading) {
        [ViewDisplayHelper displayOutOfSpaceMessage];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add picture note"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    actionSheet.tag = ADD_PICTURE_NOTE_ACTION_SHEET;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Take a picture",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Select from pictures",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 2;

    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Select from pictures",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        actionSheet.cancelButtonIndex = 1;
    }

    [actionSheet showInView:self.view];
}



- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index {
    [super actionSheet:sender clickedButtonAtIndex:index];
    
    if (sender.tag == ADD_PICTURE_NOTE_ACTION_SHEET) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES) {
            if (index == 0) {
                [self takeNewPicture];
            } else if (index == 1) {
                [self selectExistingPicture];
            }
            
        } else {
            if (index == 0) {
                [self selectExistingPicture];
            }
        }
        
        [sender dismissWithClickedButtonIndex:index animated:YES];
    }
}


// Show note detail
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)doc {
    if ([segue.identifier isEqualToString:@"OpenDoc"]) {
        DocNoteViewController *viewController = (DocNoteViewController*)segue.destinationViewController;
        viewController.doc = [doc copy];

    } else if ([segue.identifier isEqualToString:@"NewDoc"]) {
        DocNoteEditorViewController* editorController = (DocNoteEditorViewController*)[segue destinationViewController];
        editorController.entryFolder = self.currentFolder;
        NPDoc *newNote = [[NPDoc alloc] init];
        newNote.folder.folderId = self.currentFolder.folderId;
        newNote.accessInfo = [self.currentFolder.accessInfo copy];
        editorController.doc = newNote;
    }
}


// Display items after a folder selected
- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    if (self.childFolderDocListController == nil) {
        self.childFolderDocListController = [self.storyboard instantiateViewControllerWithIdentifier:@"DocList"];
    }

    self.childFolderDocListController.currentFolder = [selectedFolder copy];
    [self.navigationController pushViewController:self.childFolderDocListController animated:YES];
}


#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    [self.entryListService searchEntries:self.searchBar.text templateId:doc inFolder:self.currentFolder pageId:1 countPerPage:0];
}


#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isSearchTableView:tableView]) {
        return 1;
        
    } else {
        if (!self.entryListIsLoading && [self.currentEntryList isEmpty]) {
            return 1;
        }

        int sections = 0;
        if ([self.currentEntryList.folder.subFolders count] > 0) {
            sections++;
        }
        if ([self.currentEntryList.entries count] > 0) {
            sections++;
        }
        
        return sections;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isSearchTableView:tableView]) {
        NSInteger count = [self.searchResultList.entries count];
        if ([self hasMoreSearchResultToLoad:tableView]) {
            return count + 1;
        }
        return count;
        
    } else {
        if ([self.currentEntryList isEmpty]) {
            return 0;
        }

        // The number of folders
        if ([self foldersShown] && section == 0) {
            return [self.currentEntryList.folder.subFolders count];
        }
        
        // The number of entries
        NSInteger count = [self.currentEntryList.entries count];
        if ([self hasMoreToLoad:tableView]) {
            return count + 1;
        }
        
        return count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isSearchTableView:tableView]) {
        if ([NSString isBlank:self.searchResultList.keyword]) {
            return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DummyCell"];
        }
    }

    NSString *CellIdentifier = @"EntryCell";
    
    if (![self isSearchTableView:tableView] && [self foldersShown] && indexPath.section == 0) {
        CellIdentifier = @"FolderCell";
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        if ([CellIdentifier isEqualToString:@"FolderCell"]) {
            cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FolderCell"];
        } else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
    }
    
    // Folder or entry row
    NPEntry *entry = nil;
    
    if ([self isSearchTableView:tableView]) {
        entry = [self.searchResultList.entries objectAtIndex:indexPath.row];
        
        // Load more row
        if ([self isLoadMoreRowInSearchTable:tableView indexPath:indexPath]) {
            return [UITableViewCell loadMoreCell];
        }

        if ([entry isPinned]) {
            cell.imageView.image = [UIImage imageNamed:@"is-favorite.png"];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"icon-doc.png"];
        }

        cell.textLabel.text = entry.title;
        
    } else {
        
        if ([self foldersShown] && indexPath.section == 0) {
            NPFolder *folder = [self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row];
            [self configureFolderCell:cell forFolder:folder];
            
        } else {
            
            // Load more row
            if ([self isLoadMoreRow:tableView indexPath:indexPath]) {
                return [UITableViewCell loadMoreCell];
            }
            
            entry = [self.currentEntryList.entries objectAtIndex:indexPath.row];
            
            if ([entry isPinned]) {
                cell.imageView.image = [UIImage imageNamed:@"is-favorite.png"];
            } else {
                cell.imageView.image = [UIImage imageNamed:@"icon-doc.png"];
            }
            
            cell.textLabel.text = entry.title;
        }
        
        cell.textLabel.backgroundColor = [UIColor whiteColor];
    }
    
    cell.textLabel.textColor = [UIColor blackColor];                                // This is to make sure overwriting "load more" blue
    cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.sharersMenu != nil && [self.sharersMenu isMenuOpen]) {
        return;
    }
    
    if ([self isLoadMoreRowInSearchTable:tableView indexPath:indexPath]) {
        [self loadMoreSearchResultEntries];
        return;
        
    } else if ([self isLoadMoreRow:tableView indexPath:indexPath]) {
        [self loadMoreEntries];
        return;
    }
    
    NPDoc *doc = nil;
    
    if ([self isSearchTableView:tableView]) {
        doc = [self.searchResultList.entries objectAtIndex:indexPath.row];
        [self performSegueWithIdentifier:@"OpenDoc" sender:doc];

    } else {
        if ([self foldersShown] && indexPath.section == 0) {
            // Open a folder
            NPFolder *selectedFolder = [self.currentEntryList.folder.subFolders objectAtIndex:indexPath.row];
            [self showItemsAfterSelectingFolder:selectedFolder];
            
        } else {
            doc = [self.currentEntryList.entries objectAtIndex:indexPath.row];
            [self performSegueWithIdentifier:@"OpenDoc" sender:doc];
        }
    }
}


// ONLY handles entry add/update/delete action notifications
- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        
        NPEntry *updatedEntry = (NPEntry*)notification.object;
        
        if (updatedEntry.folder.moduleId != DOC_MODULE) {
            DLog(@"No doc notification action to take. This is for a different list view controller with module Id:%d", updatedEntry.folder.moduleId);
            return;
        }

        // If the view controller is the ROOT folder, go ahead try to update the entry because the entry might be pinned here.
        // Otherwise, check if the folder Ids match before proceeding.
        if (self.currentFolder.folderId != ROOT_FOLDER && updatedEntry.folder.folderId != self.currentFolder.folderId) {
            DLog(@"No doc notification action to take. This is for a different folder, my folder id:%i, other folder id:%i", self.currentFolder.folderId, updatedEntry.folder.folderId);
            return;
        }
        
        DLog(@"DocListController received notification for module %i received entry list updated: %@", self.currentFolder.moduleId, updatedEntry);
        
        NPEntry *affectedEntryInList = nil;
        
        for (NPEntry *entry in self.currentEntryList.entries) {
            if ([entry.entryId isEqualToString:updatedEntry.entryId]) {
                affectedEntryInList = entry;
                break;
            }
        }
        
        if (affectedEntryInList == nil) {                                       // This is a new entry
            [self.currentEntryList addToTopOfList:[updatedEntry copy]];
            
            if ([self.currentEntryList isNotEmpty]) {
                [self.emptyListLabel removeFromSuperview];
            }

            [self refreshListTable];
            
        } else {                                                                // Update an existing entry in the list: title and color label.
            [self.currentEntryList deleteFromList:affectedEntryInList];
            [self.currentEntryList addToTopOfList:[updatedEntry copy]];
            
            [self.entryListTable reloadData];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Because the editor screen hides the navigation bar, we need to make sure to un-hide it.
    self.navigationController.navigationBarHidden = NO;
    
    if (self.currentEntryList == nil) {
        [self retrieveEntryList];
    }
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        // Remove the folder update button
        if (self.toolbarItems.count == 3) {
            NSMutableArray *toolBarItems = [self.toolbarItems mutableCopy];
            [toolBarItems removeObjectAtIndex:0];
            self.toolbarItems = toolBarItems;
        }
    }
    
    // Check if there is any space left
    AccountService *acctService = [[AccountService alloc] init];
    [acctService checkSpaceUsage:self.currentFolder.accessInfo.owner completion:^(BOOL spaceLeft) {
        if (!spaceLeft) {
            self.allowUploading = NO;
        } else {
            self.allowUploading = YES;
        }
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }
    
    // Notification from NPService BackgroundUploader
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleServiceDataRefresh:) name:N_DATA_REFRESHED object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    self.childFolderDocListController = nil;
}

// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *spacer = [UIBarButtonItem spacer];
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD_PICTURE_NOTE]];
            [items addObject:spacer];       // For some reason have to use 2 spacers here. Not sure why.
            [items addObject:spacer];
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:spacer];
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }
        
    } else {
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UPDATE_FOLDER]];
            [items addObject:spacer];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE_FOLDER]];
            [items addObject:spacer];
        }

        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD_PICTURE_NOTE]];
            [items addObject:spacer];
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }
    
    self.toolbarItems = items;
}


#pragma mark - upload picture note

- (void)selectExistingPicture {
    if (self.photoPicker == nil) {
        self.photoPicker = [[UIImagePickerController alloc] init];
        self.photoPicker.delegate = self;
        self.photoPicker.allowsEditing = YES;
        self.photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self.navigationController presentViewController:self.photoPicker animated:YES completion:nil];
}

- (void)takeNewPicture {
    if (self.cameraPicker == nil) {
        self.cameraPicker = [[UIImagePickerController alloc] init];
        self.cameraPicker.delegate = self;
        //self.cameraPicker.allowsEditing = YES;                // ios7 bug
        self.cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.cameraPicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
    }
    [self.navigationController presentViewController:self.cameraPicker animated:YES completion:nil];
}

// Delegate method called from UIImagePickerController
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];          // Since the iOS bug, this is not editable.
                                                                                        // we can only get the Original image here.
    NSDictionary *metaData = [info objectForKey:UIImagePickerControllerMediaMetadata];
    
    [[NPUploadHelper instance] uploadImage:image metaData:(NSDictionary*)metaData destination:self.currentFolder];
    [self showActivityBar];
}

// Handle notification from BackgroundUploader
- (void)handleServiceDataRefresh:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPFolder class]]) {
        DLog(@"Handles data refresh notification from NPService BackgroundUploader.");
        
        NPFolder *folder = (NPFolder*)notification.object;
        if (folder.moduleId == DOC_MODULE) {
            [self retrieveEntryList];
            [self hideActivityBar];
        }
    }
}

@end
