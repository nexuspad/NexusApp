//
//  AlbumEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 9/26/12.
//
//

#import "AlbumEditorViewController.h"

@interface AlbumEditorViewController ()

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet TextViewWithPlaceHolder *noteTextView;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@end

@implementation AlbumEditorViewController

@synthesize album = _album;

- (NPEntry*)currentEditedEntry {
    return _album;
}

- (void)setAlbum:(NPAlbum *)album
{
    _album = [album copy];
    [self.tableView reloadData];
}

- (IBAction)saveAlbum:(id)sender
{
    // Clear the old values
    [self.album.featureValuesDict removeAllObjects];
    
    // Set the values
    self.album.title = self.titleTextField.text;
    self.album.tags = self.tagsTextField.text;
    self.album.note = self.noteTextView.text;
    
    [super postEntry:self.album];
}

// Result of saving the album
- (void)updateServiceResult:(id)serviceResult
{
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        
        if (actionResponse.entry != nil) {
            self.album.entryId = actionResponse.entry.entryId;
        }

        if (actionResponse.success) {
            if (self.afterSavingDelegate != nil) {
                [self.afterSavingDelegate entryUpdateSaved:self.album];
            }
            
            [NotificationUtil sendEntryUpdatedNotification:self.album];
            [self cancelEditor:nil];
        }
    }
}

#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    self.album.folder = [selectedFolder copy];
    self.album.folder.folderId = selectedFolder.folderId;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    [theTextField resignFirstResponder];
    return YES;
}

- (void)handlePhotoAddedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPAlbum class]]) {
    } else {
        DLog(@"Cannot handle notification. The notification object is not the Photo type.");
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.noteTextView.placeholder = NSLocalizedString(@"Note",);
    
    self.titleTextField.text = self.album.title;
    self.tagsTextField.text = self.album.tags;
    self.noteTextView.text = self.album.note;
    
    self.titleTextField.delegate = self;
    self.tagsTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidUnload {
    self.titleTextField = nil;
    [self setNoteTextView:nil];
    [self setTagsTextField:nil];
    [self setTitleTextField:nil];
    [super viewDidUnload];
}

@end
