//
//  NPUploadHelper.h
//  nexusapp
//
//  Created by Ren Liu on 8/29/13.
//
//

#import <Foundation/Foundation.h>
#import "UploadService.h"
#import "UploadItem.h"

@protocol NPUploadHelperDelegate <NSObject>
- (void)updateUploadItemStatus:(UploadItem*)uploadItem;
@end

@interface NPUploadHelper : NSObject <UploadServiceProgressDelegate>

+ (id)instance;

// The delegate is the UploadViewController that visually shows the upload progress and status.
@property (nonatomic, weak) id<NPUploadHelperDelegate> uploadHelperDelegate;

- (NSMutableArray*)uploadItems;

- (void)addAssets:(NSArray*)assetsUrls destination:(id)destination;
- (void)addAsset:(NSURL*)assetUrl thumbnailImage:(UIImage*)thumbnailImage destination:(id)destination;

- (void)startUploading;
- (void)cleanup;

- (void)uploadImage:(UIImage*)image metaData:(NSDictionary*)metaData destination:(id)destination;

- (void)cancelUpload:(UploadItem*)canceledItem;
- (void)retryUpload:(UploadItem*)item;

@end