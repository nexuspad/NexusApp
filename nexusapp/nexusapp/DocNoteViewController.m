//
//  DocNoteViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/15/13.
//
//

#import "DocNoteViewController.h"
#import "ViewDisplayHelper.h"
#import "EntryEditorTableViewController.h"
#import "UIColor+NPColor.h"
#import "NSAttributedString+HTML.h"
#import "UIBarButtonItem+NPUtil.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "NPEntry+Attribute.h"
#import "UIColor+NPColor.h"

@interface DocNoteViewController ()
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *richTextViewerBottomSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *richTextViewerTopSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *attachmentsViewBottomSpace;
@property (strong, nonatomic) IBOutlet UICollectionView *attachmentsCollectionView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *favoriteButton;

@property (nonatomic, strong) NSCache *imageViewCache;

@property (strong, nonatomic) EntryService *entryService;

@end

@implementation DocNoteViewController

@synthesize doc = _doc;

// Overwrite EntryViewController method
- (NPEntry*)getCurrentEntry {
    return _doc;
}

- (void)retrieveEntryDetail {
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
    [self.entryService getEntryDetail:_doc];
}

- (IBAction)saveDoc:(id)sender {
    // Clear the old values
    [_doc.featureValuesDict removeAllObjects];
    
    _doc.note = [self getHTML];
    
    DLog(@"%@", [_doc buildParamMap]);
    
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
    [self.entryService addOrUpdateEntry:_doc];
}

- (void)serviceError:(id)serviceResult {
    NSLog(@"NPService returned error: %@", [serviceResult description]);
    [ViewDisplayHelper dismissWaiting:self.view];   // This shouldn't be really necessary
}

- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[NPEntry class]]) {
        _doc = [NPDoc docFromEntry:serviceResult];
        [self.attachmentsCollectionView reloadData];
        
    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;

        if ([actionResponse.name isEqualToString:ACTION_ADD_ENTRY]) {
            if (actionResponse.success) {
                if (actionResponse.entry != nil) {
                    _doc.entryId = actionResponse.entry.entryId;
                }
                
                NPDoc *returnedDoc = [actionResponse.entry copy];
                
                [NotificationUtil sendEntryUpdatedNotification:returnedDoc];
            }

        } else if ([actionResponse.name isEqualToString:ACTION_UPDATE_ENTRY]) {
            if (actionResponse.success) {
                self.doc = (NPDoc*)actionResponse.entry;                // Make sure setDoc is called
                [NotificationUtil sendEntryUpdatedNotification:_doc];
                [self.attachmentsCollectionView reloadData];
            }
        }
    }
}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)favoriteButtonTapped:(id)sender {
    if ([_doc isPinned]) {
        [self.entryService updateAttribute:_doc attributeName:ENTRY_PINNED attributeValue:@"0"];    // Toggle off
    } else {
        [self.entryService updateAttribute:_doc attributeName:ENTRY_PINNED attributeValue:@"1"];    // Toggle on
    }
}

// This is called in the data service delegate
- (void)setDoc:(NPDoc*)doc {
    _doc = [doc copy];
    
    if (self.favoriteButton != nil) {
        if ([_doc isPinned]) {
            [self.favoriteButton setImage:[UIImage imageNamed:@"is-favorite.png"]];
        } else {
            [self.favoriteButton setImage:[UIImage imageNamed:@"favorite.png"]];
        }
    }
}

// Load whole doc view screen
- (void)loadDocView {
    [self setHTML:_doc.note];
    
    self.navigationItem.title = _doc.title;

    if (_doc.hasAttachments) {
        [self.attachmentsCollectionView setHidden:NO];
        self.attachmentsViewBottomSpace.constant = 0.0;

        // Adjust attachment section's position if there is no text.
        if (_doc.note.length < 10) {
            UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

            if (UIInterfaceOrientationIsLandscape(orientation)) {
                // 212 is the max value because in landscape mode it's the height minus top space: 320 - (20 + 44 + 44)
                self.richTextViewerBottomSpace.constant = 212.0;
            } else {
                self.richTextViewerBottomSpace.constant = [ViewDisplayHelper screenHeight] - (20 + 44 + 44) - 20;
            }
        }
        
        [self retrieveEntryDetail];

    } else {
        // Need to set both bottom space constraints to 0
        self.richTextViewerBottomSpace.constant = 32.0;
        self.attachmentsViewBottomSpace.constant = 0.0;
        [self.attachmentsCollectionView setHidden:YES];
    }
}


# pragma mark - after saving the entry delegate

// This is called after successfuly saving the entry in the editor.
- (void)entryUpdateSaved:(NPDoc*)doc {
    _doc = doc;
    [self loadDocView];
}


- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index {
    if (sender.tag >= 1000) {
        // Attachment actions
        NSInteger row = sender.tag - 1000;
        if (index == sender.destructiveButtonIndex) {
            if ([self.doc.attachments objectAtIndex:row] != nil) {
                // Make service call to delete attachment
                NPUpload *att = [_doc.attachments objectAtIndex:row];
                [self.entryService deleteAttachment:att];
                
                NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:_doc.attachments];
                [tmpArr removeObjectAtIndex:row];
                _doc.attachments = [NSArray arrayWithArray:tmpArr];
                
                [self.attachmentsCollectionView reloadData];
            }

        } else if (index == sender.cancelButtonIndex) {
            [sender dismissWithClickedButtonIndex:index animated:YES];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.attachmentsCollectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

        } else {
            NPUpload *att = [_doc.attachments objectAtIndex:row];
            NSURL *fileUrl = [NSURL URLWithString:[NPWebApiService appendAuthParams:att.url]];
            [[UIApplication sharedApplication] openURL:fileUrl];
        }
        
    } else {
        
        if (index == sender.destructiveButtonIndex) {
            if (_doc != nil) {
                [self.entryService deleteEntry:_doc];
                [NotificationUtil sendEntryDeletedNotification:_doc];
            }
            
            [sender dismissWithClickedButtonIndex:index animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            
        } else if (index == sender.cancelButtonIndex) {
            [sender dismissWithClickedButtonIndex:index animated:YES];
        }
    }
}

#pragma - segue to editor

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"OpenNoteEditor"]) {
        [segue.destinationViewController setDoc:[_doc copy]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if (self.entryService == nil) {
        self.entryService = [[EntryService alloc] init];
    }
    self.entryService.accessInfo = [self.entryFolder.accessInfo copy];
    self.entryService.serviceDelegate = self;

    self.attachmentsCollectionView.dataSource = self;
    self.attachmentsCollectionView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDocView];
}


- (void)viewDidUnload {
    [self setDoc:nil];
    [super viewDidUnload];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    DLog(@"Memory warning received...");
}

#pragma mark Properties

- (NSCache *)imageViewCache {
    if (!_imageViewCache) {
        _imageViewCache = [[NSCache alloc] init];
    }
    
    return _imageViewCache;
}

@synthesize imageViewCache = _imageViewCache;

# pragma mark - attachment collection list

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _doc.attachments.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NPUpload *att = [_doc.attachments objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"AttachmentCell";

    UICollectionViewCell *cell = [self.attachmentsCollectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView *iconImageView = (UIImageView*)[cell viewWithTag:10];

    NSString *ext = [att.fileName pathExtension];

    if (ext.length > 0) {
        NSString *fileTypeImageUrl = [NSString stringWithFormat:@"https://s3.amazonaws.com/nexuspad_static/images/%@.png", ext];
        [iconImageView sd_setImageWithURL:[NSURL URLWithString:fileTypeImageUrl]
                      placeholderImage:[UIImage imageNamed:@"document.png"]
                               options:SDWebImageLowPriority];
    }
    
    UILabel* fileNameLabel = (UILabel*)[cell viewWithTag:11];

    NSString *displayFileName;
    
    /*
     * Shorten the first part of the file name.
     *
     */
    if (ext.length > 0) {
        NSString *firstPart = [att.fileName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", ext]
                                                                      withString:@""];
        NSString *shortenedName = [firstPart reducedToWidth:90.0 withFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
        if (shortenedName.length == firstPart.length) {
            displayFileName = att.fileName;
        } else {
            displayFileName = [NSString stringWithFormat:@"%@...%@", shortenedName, ext];
        }
        
    } else {
        displayFileName = [att.fileName reducedToWidth:125.0 withFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
    }

    fileNameLabel.adjustsFontSizeToFitWidth = YES;
    
    fileNameLabel.text = displayFileName;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NPUpload *att = [_doc.attachments objectAtIndex:indexPath.row];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:att.fileName
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open",)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete",)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
    
    actionSheet.cancelButtonIndex = 2;
    actionSheet.destructiveButtonIndex = 1;
    
    actionSheet.tag = 1000 + indexPath.row;
    [actionSheet showInView:self.view];
}


//- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
//    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
//        return;
//    }
//    
//    CGPoint p = [gestureRecognizer locationInView:self.attachmentsCollectionView];
//    
//    NSIndexPath *indexPath = [self.attachmentsCollectionView indexPathForItemAtPoint:p];
//    
//    if (indexPath == nil){
//        NSLog(@"couldn't find index path");
//        
//    } else {
//        NPUpload *att = [_doc.attachments objectAtIndex:indexPath.row];
//        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:att.fileName
//                                                                 delegate:self
//                                                        cancelButtonTitle:nil
//                                                   destructiveButtonTitle:nil
//                                                        otherButtonTitles:nil];
//        
//        [actionSheet addButtonWithTitle:NSLocalizedString(@"Open",)];
//        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete",)];
//        [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
//        
//        actionSheet.cancelButtonIndex = 2;
//        actionSheet.destructiveButtonIndex = 1;
//        
//        actionSheet.tag = 1000 + indexPath.row;
//        [actionSheet showInView:self.view];
//    }
//}

@end
