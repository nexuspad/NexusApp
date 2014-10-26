//
//  BookmarkEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkEditorViewController.h"

@interface BookmarkEditorViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *urlCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *noteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagCell;

@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet TextViewWithPlaceHolder *noteTextView;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@end

@implementation BookmarkEditorViewController

@synthesize bookmark = _bookmark;


- (NPEntry*)currentEditedEntry {
    return _bookmark;
}

- (void)setBookmark:(NPBookmark *)bookmark {
    _bookmark = [bookmark copy];
    [self.tableView reloadData];
}

- (IBAction)saveBookmark:(id)sender
{
    // Clear the old values
    [self.bookmark.featureValuesDict removeAllObjects];

    // Set the values
    self.bookmark.webAddress = self.urlTextField.text;
    self.bookmark.tags = self.tagsTextField.text;
    self.bookmark.note = self.noteTextView.text;
    
    if ([NSString isBlank:self.bookmark.webAddress]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Nothing to bookmark",) delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];

    } else {
        DLog(@"%@", [self.bookmark buildParamMap]);
        [super postEntry:self.bookmark];
    }
}

// Result of saving the bookmark
- (void)updateServiceResult:(id)serviceResult
{
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        
        if (actionResponse.entry != nil) {
            self.bookmark.entryId = actionResponse.entry.entryId;
        }
        
        if (actionResponse.success) {
            if (self.afterSavingDelegate != nil) {
                [self.afterSavingDelegate entryUpdateSaved:self.bookmark];
            }

            [NotificationUtil sendEntryUpdatedNotification:self.bookmark];

            [self cancelEditor:nil];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case BOOKMARK_URL_SECTION:
        {
            self.urlCell.selectionStyle = UITableViewCellSelectionStyleNone;
            return self.urlCell;
        }
        case BOOKMARK_TAGS_SECTION:
        {
            if (indexPath.row == 0) {
                return self.tagCell;
            } else if (indexPath.row == 1) {
                return self.noteCell;
            }
        }
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    }
    return 1;
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    self.bookmark.folder = [selectedFolder copy];
    self.bookmark.folder.folderId = selectedFolder.folderId;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.noteTextView.placeholder = NSLocalizedString(@"Note",);
    
    self.urlTextField.text = self.bookmark.webAddress;
    self.tagsTextField.text = self.bookmark.tags;

    self.noteTextView.text = self.bookmark.note;
    //[self addToolbarToTextView:self.noteTextView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.bookmark.entryId == nil) {
        [self.urlTextField becomeFirstResponder];
    }
}

- (void)viewDidUnload {
    [self setUrlCell:nil];
    [self setUrlTextField:nil];
    [self setNoteCell:nil];
    [self setNoteTextView:nil];
    [self setTagCell:nil];
    [self setTagsTextField:nil];
    [super viewDidUnload];
}


@end
