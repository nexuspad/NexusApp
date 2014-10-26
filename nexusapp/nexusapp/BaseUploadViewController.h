//
//  BaseUploadViewController.h
//  nexuspad
//
//  Created by Ren Liu on 10/2/12.
//
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "NPUploadHelper.h"

@interface BaseUploadViewController : UITableViewController <NPUploadHelperDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (nonatomic, strong) NSMutableArray *incompleteItems;

- (void)setAssetArrayWithDestination:(NSMutableArray *)assetArray destination:(id)destination;

- (void)findIncompleteItems;

- (void)updateUploadCell:(UploadItem*)item theCell:(UITableViewCell*)theCell;

@end
