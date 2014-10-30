//
//  PhotoSearchCollectionViewController.m
//  nexusapp
//
//  Created by Ren Liu on 8/16/13.
//
//

#import <QuartzCore/QuartzCore.h>

#import "NPWebApiService.h"
#import "PhotoSearchCollectionViewController.h"
#import "LightboxViewController.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "NotificationUtil.h"
#import "UIImageView+NPUtil.h"


@interface PhotoSearchCollectionViewController ()
@end

@implementation PhotoSearchCollectionViewController

@synthesize searchListResult = _searchListResult, searchBar = _searchBar;

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionReusableView *header = [[UICollectionReusableView alloc] init];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(collectionView.frame), 44)];
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.delegate = self;
    self.searchBar.autoresizingMask = UIViewContentModeScaleToFill;
    self.searchBar.showsCancelButton = YES;
    [header addSubview:self.searchBar];
    
    return header;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _searchListResult.entries.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"PhotoCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *aImageView = (UIImageView *)[cell viewWithTag:100];
    
    [UIImageView roundedCorner:aImageView];
    aImageView.contentMode = UIViewContentModeScaleAspectFill;
    aImageView.userInteractionEnabled = YES;
    
    NPUpload *photo = [_searchListResult.entries objectAtIndex:indexPath.row];
    NSString *tnImageUrl = [NPWebApiService appendAuthParams:photo.tnUrl];
    DLog(@"Thumbnail image url: %@", tnImageUrl);
    
    [aImageView sd_setImageWithURL:[NSURL URLWithString:tnImageUrl] placeholderImage:[UIImage imageNamed:@"placeholder.png"] options:SDWebImageRetryFailed];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NPUpload *selectedPhoto = [_searchListResult.entries objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"OpenLightbox" sender:selectedPhoto];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenLightbox"]) {
        LightboxViewController *lightboxController = (LightboxViewController*)segue.destinationViewController;
        NPUpload *selectedPhoto = (NPUpload*)sender;
        
        NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];
        scrollIndex.currentIndex = selectedPhoto.displayIndex;
        scrollIndex.totalCount = _searchListResult.entries.count;
        
        lightboxController.scrollIndex = scrollIndex;
        lightboxController.navigationDelegate = self;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EntryViewPrevNextDelegate

- (id)getEntryAtIndex:(NSInteger)index {
    return nil;
}

- (NPScrollIndex*)deleteEntryAtIndex:(NSInteger)index {
    NPScrollIndex *scrollIndex = [[NPScrollIndex alloc] init];

    // TODO - need to implement the search
    return scrollIndex;
}

- (id)getPreviousEntry:(int)index
{
    if (index == 0) return [_searchListResult.entries objectAtIndex:0];
    
    int previousIndex = index - 1;
    
    NPUpload *photoAttachment = [_searchListResult.entries objectAtIndex:previousIndex];
    [NotificationUtil sendEntryAvailableNotification:photoAttachment];
    
    return photoAttachment;
}

- (id)getNextEntry:(int)index
{
    int nextIndex = 0;
    
    if (index >= ([_searchListResult.entries count] - 1)) {     // At the last item in the list
        // do nothing. nextIndex remains at 0
        
    } else {
        nextIndex = index + 1;
    }
    
    NPUpload *photoAttachment = [_searchListResult.entries objectAtIndex:nextIndex];
    [NotificationUtil sendEntryAvailableNotification:photoAttachment];
    
    return photoAttachment;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];            // In EntryListController, hideBackButton is set to YES
    self.navigationItem.hidesBackButton = NO;   // Need to show the back navigation button when displaying album photos
    self.navigationController.toolbarHidden = NO;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
