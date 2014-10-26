//
//  BookmarkViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkViewController.h"
#import "EntryEditorTableViewController.h"
#import "UIColor+NPColor.h"
#import "NPEntry+Attribute.h"


@interface BookmarkViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NoteCell *titleCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *urlCell;
@property (weak, nonatomic) IBOutlet NoteCell *noteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagCell;
@property (weak, nonatomic) IBOutlet UILabel *urlTextLabel;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *favoriteButton;
@property BOOL hasTags;
@property BOOL hasNote;
@end

@implementation BookmarkViewController
@synthesize bookmark = _bookmark;

// Overwrite EntryViewController method
- (NPEntry*)getCurrentEntry {
    return _bookmark;
}

// Not used
- (void)retrieveEntryDetail {
    [self.entryService getEntryDetail:_bookmark];
}

- (void)updateServiceResult:(id)serviceResult {
    [super updateServiceResult:serviceResult];
    if ([serviceResult isKindOfClass:[NPEntry class]]) {
        _bookmark = [NPBookmark bookmarkFromEntry:serviceResult];
        
        [self updateBookmarkFields];
        [self.tableView reloadData];

    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        
        if ([actionResponse.name isEqualToString:ACTION_UPDATE_ENTRY]) {
            if (actionResponse.success) {
                self.bookmark = (NPBookmark*)actionResponse.entry;              // Make sure setBookmark is called
                [NotificationUtil sendEntryUpdatedNotification:_bookmark];
            }
        }
    }
}


- (IBAction)favoriteButtonTapped:(id)sender {
    if ([_bookmark isPinned]) {
        [self.entryService updateAttribute:_bookmark attributeName:ENTRY_PINNED attributeValue:@"0"];    // Toggle off
    } else {
        [self.entryService updateAttribute:_bookmark attributeName:ENTRY_PINNED attributeValue:@"1"];    // Toggle on
    }
}


// This is called in the data service delegate
- (void)setBookmark:(NPBookmark *)bookmark {
    _bookmark = [bookmark copy];
    
    if (self.favoriteButton != nil) {
        if ([_bookmark isPinned]) {
            [self.favoriteButton setImage:[UIImage imageNamed:@"is-favorite.png"]];
        } else {
            [self.favoriteButton setImage:[UIImage imageNamed:@"favorite.png"]];
        }
    }
}

// This is called after successfuly saving the entry in the editor.
- (void)entryUpdateSaved:(NPBookmark*)bookmark {
    _bookmark = bookmark;
    [self.tableView reloadData];
}

- (void)updateBookmarkFields {
    self.titleCell.textLabel.text = _bookmark.title;
    [self.titleCell layoutSubviews];

    self.urlCell.textLabel.text = _bookmark.webAddress;
    self.urlCell.textLabel.textColor = [UIColor darkBlue];
    self.urlCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.tagCell.textLabel.text = NSLocalizedString(@"Tags",);
    self.tagCell.detailTextLabel.text = _bookmark.tags;
    
    self.noteCell.textLabel.text = _bookmark.note;
    [self.noteCell layoutSubviews];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case BOOKMARK_URL_SECTION:
        {
            if (indexPath.row == 0) {
                return self.titleCell.frame.size.height;
            }
            break;
        }
        case BOOKMARK_TAGS_SECTION:
        {
            float cellHeight = 0;
            
            if (indexPath.row == 0 && self.hasTags) {
                cellHeight = self.tagCell.frame.size.height;
            }
            if ((indexPath.row == 0 && !self.hasTags) || indexPath.row == 1) {
                cellHeight += self.noteCell.contentView.frame.size.height;
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
        case BOOKMARK_URL_SECTION:
        {
            if (indexPath.row == 0) {
                return self.titleCell;
                
            } else if (indexPath.row == 1) {
                return self.urlCell;
            }

        }
        case BOOKMARK_TAGS_SECTION:
        {
            if (indexPath.row == 0 && self.hasTags) {
                return self.tagCell;
            }
            if ((indexPath.row == 0 && !self.hasTags) || indexPath.row == 1) {
                return self.noteCell;
            }
        }
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == BOOKMARK_TAGS_SECTION) {
        
        int rows = 0;
        if (_bookmark.tags != nil) {
            self.hasTags = YES;
            rows++;
        } else {
            self.hasTags = NO;
        }
        
        if (_bookmark.note != nil && _bookmark.note.length > 0) {
            rows++;
            self.hasNote = YES;
        } else {
            self.hasNote = NO;
        }
        
        return rows;
    }
    
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == BOOKMARK_URL_SECTION) {
        NSString* launchUrl = [NSString prependHttp:_bookmark.webAddress];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: launchUrl]];
    }
}

#pragma - segue to editor
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EditBookmark"]) {
        [segue.destinationViewController setAfterSavingDelegate:self];
        [segue.destinationViewController setBookmark:_bookmark];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_bookmark != nil) {
        self.titleCell.textLabel.text = _bookmark.title;            // Display something while entry detail is being loaded.
    }
    self.titleCell.noteFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBookmarkFields];
}

- (void)viewDidUnload {
    [self setUrlCell:nil];
    [self setNoteCell:nil];
    [self setTagCell:nil];
    [self setUrlTextLabel:nil];
    [self setTitleCell:nil];
    [super viewDidUnload];
}

@end
