//
//  PhotoUploadViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PhotoUploadViewController.h"
#import "NotificationUtil.h"
#import "UIColor+NPColor.h"
#import "NPUploadHelper.h"
#import "UIImageView+NPUtil.h"


@interface PhotoUploadViewController ()
@property BOOL uploadStarted;
@end

@implementation PhotoUploadViewController

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AssetCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    UploadItem *item = [self.incompleteItems objectAtIndex:indexPath.row];
    
    UIImageView *tnImageView = (UIImageView*)[cell.contentView viewWithTag:5];

    if (item.assetThumbnail != nil) {
        tnImageView.image = item.assetThumbnail;
        [UIImageView roundedCorner:tnImageView];

    } else {
        tnImageView.image = [UIImage imageNamed:@"placeholder.png"];
    }
    
    [self updateUploadCell:item theCell:cell];
    
    return cell;
}


- (IBAction)startUploading:(id)sender {
    self.uploadStarted = YES;
    self.uploadButton.enabled = NO;
    
    [[NPUploadHelper instance] startUploading];
}


#pragma mark - Table view delegate

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO];
    
    UIApplication *application = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier backgroundUploadTask;

    backgroundUploadTask = [application beginBackgroundTaskWithExpirationHandler:^ {
        // Clean up code. Tell the system that we are done.
        [application endBackgroundTask:backgroundUploadTask];
        backgroundUploadTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Start doing uploading.
        [[NPUploadHelper instance] startUploading];
        
        // Clean up code. Tell the system that we are done.
        [application endBackgroundTask:backgroundUploadTask];
        backgroundUploadTask = UIBackgroundTaskInvalid;
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Upload photos",);
}

- (void)viewDidUnload
{
    [self setUploadButton:nil];
    [super viewDidUnload];
}

@end
