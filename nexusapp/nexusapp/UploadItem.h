//
//  UploadItem.h
//  NexusAppCore
//
//  Created by Ren Liu on 1/2/14.
//  Copyright (c) 2014 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "NPFolder.h"

typedef enum {WAITING, UPLOADING, COMPLETED, CANCELED, ERROR} UploadItemStatus;

@interface UploadItem : NSObject

@property (nonatomic, strong) NSString *sessionKey;

@property (nonatomic, strong) UIImage *image;           // This is the image that needs to be uploaded

@property (nonatomic, strong) UIImage *assetThumbnail;
@property (nonatomic, strong) NSURL *itemUrl;           // This can be the URL to a file or to an asset

@property (nonatomic, strong) NSNumber *totalBytes;
@property float percentage;

@property (nonatomic, strong) NPEntry *toEntry;
@property (nonatomic, strong) NPFolder *toFolder;

@property UploadItemStatus status;

- (id)initWithAssetUrl:(NSURL*)assetUrl destination:(id)destination;
- (id)initWithSingleImage:(UIImage*)image destination:(id)destination;

- (NSString*)uploadStatusString;

@end
