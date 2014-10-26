//
//  BaseUploadViewController.m
//  nexuspad
//
//  Created by Ren Liu on 10/2/12.
//
//

#import "BaseUploadViewController.h"
#import "NotificationUtil.h"
#import "UIColor+NPColor.h"

@interface BaseUploadViewController ()
@end

@implementation BaseUploadViewController


- (void)setAssetArrayWithDestination:(NSMutableArray *)assetArray destination:(id)destination {
    NPUploadHelper *uploader = [NPUploadHelper instance];
    uploader.uploadHelperDelegate = self;
    
    for (NSDictionary *assetDict in assetArray) {
        [uploader addAsset:[assetDict objectForKey:@"UIImagePickerControllerReferenceURL"]
            thumbnailImage:(UIImage*)[assetDict objectForKey:@"UIImagePickerControllerThumbnailImage"]
               destination:destination];
    }
    
    [self findIncompleteItems];
}

- (void)findIncompleteItems {
    if (self.incompleteItems == nil) {
        self.incompleteItems = [[NSMutableArray alloc] init];
    }
    
    [self.incompleteItems removeAllObjects];

    NSArray *items = [[NPUploadHelper instance] uploadItems];
    for (UploadItem *item in items) {
        if (item.status != COMPLETED) {
            [self.incompleteItems addObject:item];
        }
    }
}

- (void)updateUploadItemStatus:(UploadItem *)uploadItem {
    [self findIncompleteItems];
    
    if (self.incompleteItems.count == 0) {
        [self.navigationController popViewControllerAnimated:YES];      // Pop back to the previous view controller.
    }
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger cnt = self.incompleteItems.count;
    if (cnt == 0) {
        self.uploadButton.enabled = NO;
    } else {
        self.uploadButton.enabled = YES;
    }

    return cnt;
}


// Update the cell with the current item
- (void)updateUploadCell:(UploadItem*)item theCell:(UITableViewCell*)theCell {
    UIProgressView *progressBar = (UIProgressView*)[theCell.contentView viewWithTag:10];
    UILabel *uploadStatusTextLabel = (UILabel*)[theCell.contentView viewWithTag:20];

    UIButton *cancelButn = (UIButton*)[theCell.contentView viewWithTag:30];
    [cancelButn addTarget:self action:@selector(cancelUploadItem:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *retryButn = (UIButton*)[theCell.contentView viewWithTag:40];
    [retryButn addTarget:self action:@selector(retryUploadItem:) forControlEvents:UIControlEventTouchUpInside];

    uploadStatusTextLabel.text = [[item uploadStatusString] lowercaseString];

    if (item.status == WAITING) {
        cancelButn.hidden = NO;
        retryButn.hidden = YES;
        progressBar.progress = 0.0;
        
    } else if (item.status == UPLOADING) {
        uploadStatusTextLabel.textColor = [UIColor blackColor];
        cancelButn.hidden = NO;
        retryButn.hidden = YES;
        progressBar.progress = item.percentage;
        
    } else if (item.status == CANCELED) {
        uploadStatusTextLabel.textColor = [UIColor redColor];
        cancelButn.hidden = YES;
        retryButn.hidden = NO;
        progressBar.progress = 0.0;
        
    } else if (item.status == ERROR) {
        uploadStatusTextLabel.textColor = [UIColor redColor];
        cancelButn.hidden = YES;
        retryButn.hidden = NO;
        progressBar.progress = 0.0;

    } else if (item.status == COMPLETED) {
        uploadStatusTextLabel.textColor = [UIColor darkGreen];
        cancelButn.hidden = YES;
        retryButn.hidden = YES;
        progressBar.progress = 100.0;
    }
}


- (void)cancelUploadItem:(id)sender {
    UIButton *cancelButn = (UIButton*)sender;
    UITableViewCell *parentCell = (UITableViewCell*)[[cancelButn superview] superview];     // Need the superView twice because it's

    NSIndexPath *indexPath = [self.tableView indexPathForCell:parentCell];
    
    NSArray *items = [[NPUploadHelper instance] uploadItems];
    UploadItem *item = [items objectAtIndex:indexPath.row];

    [[NPUploadHelper instance] cancelUpload:item];
}


- (void)retryUploadItem:(id)sender {
    UIButton *retryButn = (UIButton*)sender;
    UITableViewCell *parentCell = (UITableViewCell*)[[retryButn superview] superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:parentCell];

    NSArray *items = [[NPUploadHelper instance] uploadItems];
    UploadItem *item = [items objectAtIndex:indexPath.row];
    
    [[NPUploadHelper instance] retryUpload:item];
}


@end
