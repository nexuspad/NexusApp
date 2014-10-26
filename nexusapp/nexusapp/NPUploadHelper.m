//
//  BackgroundUploader.m
//  nexusapp
//
//  Created by Ren Liu on 8/29/13.
//
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NPUploadHelper.h"
#import "NPEntry.h"
#import "NPFolder.h"
#import "NPServiceNotificationUtil.h"
#import "NSString+NPStringUtil.h"

static NPUploadHelper *instance = nil;

@interface NPUploadHelper ()
@property (nonatomic, strong) NSMutableArray *uploadItems;
@property (nonatomic, strong) NSMutableDictionary *uploaderPool;
@end

@implementation NPUploadHelper

@synthesize uploadItems = _uploadItems;


// Get the shared instance and create it if necessary.
+ (NPUploadHelper*)instance {
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    self.uploadItems = [[NSMutableArray alloc] init];
    self.uploaderPool = [[NSMutableDictionary alloc] init];
    return self;
}

- (NSMutableArray*)uploadItems {
    return _uploadItems;
}

- (void)addAssets:(NSArray*)assetsUrls destination:(id)destination {
    if (_uploadItems == nil) {
        _uploadItems = [[NSMutableArray alloc] initWithCapacity:assetsUrls.count];
    }
    
    for (NSURL *url in assetsUrls) {
        NSURL *urlCopy = [NSURL URLWithString:url.path];
        UploadItem *item = [[UploadItem alloc] initWithAssetUrl:urlCopy destination:destination];
        item.sessionKey = [NSString genRandString:8];
        [_uploadItems addObject:item];
    }
}

- (void)addAsset:(NSURL*)assetUrl thumbnailImage:(UIImage*)thumbnailImage destination:(id)destination {
    NSURL *urlCopy = [NSURL URLWithString:assetUrl.absoluteString];
    UploadItem *item = [[UploadItem alloc] initWithAssetUrl:urlCopy destination:destination];
    item.assetThumbnail = thumbnailImage;
    
    item.sessionKey = [NSString genRandString:8];
    [_uploadItems addObject:item];
}


// Upload a image in the background
- (void)uploadImage:(UIImage*)image metaData:(NSDictionary*)metaData destination:(id)destination {
    NSString *sessionKey = [NSString genRandString:8];
    
    UploadItem *item = [[UploadItem alloc] initWithSingleImage:image destination:destination];
    item.sessionKey = sessionKey;
    item.status = UPLOADING;
    self.uploadItems = [NSMutableArray arrayWithObject:item];

    UploadService *uploader = [[UploadService alloc] init];

    uploader.progressDelegate = self;
    uploader.uploadSessionKey = sessionKey;
    
    NSString *dateTimeStr = [NSDateFormatter localizedStringFromDate:[[NSDate alloc] init]
                                                           dateStyle:NSDateFormatterMediumStyle
                                                           timeStyle:NSDateFormatterMediumStyle];
    
    NSString *fileName = [NSString stringWithFormat:@"Picture note %@.jpg", dateTimeStr];
    NSString *filePath = [self saveImageWithMetaData:image metaData:metaData fileName:fileName];
    
    if (filePath != nil) {
        if (item.toFolder != nil) {
            [uploader uploadFileToFolder:filePath fileName:fileName toFolder:item.toFolder];

        } else if (item.toEntry != nil) {
            [uploader uploadFileToEntry:filePath fileName:fileName toEntry:item.toEntry];
            
        } else {
            DLog(@"Error: there is no upload destination.");
        }        
    }
}


- (NSString*)saveImageWithMetaData:(UIImage*)image metaData:(NSDictionary*)metaData fileName:(NSString*)fileName {
    // Create your file URL.
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cacheURL = [[defaultManager URLsForDirectory:NSCachesDirectory
                                              inDomains:NSUserDomainMask] lastObject];

    NSURL *outputURL = [cacheURL URLByAppendingPathComponent:fileName];
    
    // Set your compression quuality (0.0 to 1.0).
    NSMutableDictionary *mutableMetadata = [metaData mutableCopy];
    [mutableMetadata setObject:@(1.0) forKey:(__bridge NSString *)kCGImageDestinationLossyCompressionQuality];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outputURL, kUTTypeJPEG , 1, NULL);

    if (imageDestination == NULL ) {
        // Handle failure.
        NSLog(@"Error: failed to create image destination.");
        return nil;
    }
    
    // Add your image to the destination.
    CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)mutableMetadata);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        CFRelease(imageDestination);
        return nil;
    }
    
    CFRelease(imageDestination);
    
    return outputURL.path;
}


- (void)startUploading {
    UploadItem *item = [self nextUploadItem];
    if (item != nil) {
        [self upload:item];
    }
}


- (void)upload:(UploadItem*)item {
    UploadService *uploader = [[UploadService alloc] init];
    
    uploader.progressDelegate = self;
    
    item.status = UPLOADING;
    
    uploader.uploadSessionKey = [NSString stringWithString:item.sessionKey];
    
    [self.uploaderPool setObject:uploader forKey:item.sessionKey];
    

    if ([item.itemUrl.scheme isEqualToString:@"assets-library"]) {
        ALAssetsLibrary *assetLib = [[ALAssetsLibrary alloc] init];
        
        [assetLib assetForURL:item.itemUrl
                  resultBlock:^(ALAsset *asset) {
                      
                      DLog(@"Upload asset at URL: %@", item.itemUrl);
                      
                      NSInteger assetSize = asset.defaultRepresentation.size;
                      NSString *fileName = asset.defaultRepresentation.filename;
                      
                      // When importing doc, fileName is nil.
                      if (fileName.length == 0) {
                          fileName = [[item.itemUrl pathComponents] lastObject];
                      }
                      
                      NSMutableData* rawData = [[NSMutableData alloc]initWithCapacity:assetSize];
                      void* bufferPointer = [rawData mutableBytes];
                      
                      NSError* error = nil;
                      [asset.defaultRepresentation getBytes:bufferPointer fromOffset:0 length:assetSize error:&error];
                      
                      if (error) {
                          DLog(@"%@",error);
                      }
                      
                      rawData = [NSMutableData dataWithBytes:bufferPointer length:assetSize];
                      
                      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                      NSString *cachesDirectory = [paths objectAtIndex:0];
                      NSString* filePath = [NSString stringWithFormat:@"%@/upload_tmp_%@.jpg", cachesDirectory, item.sessionKey];
                      
                      [rawData writeToFile:filePath atomically:YES];
                      
                      if (item.toFolder != nil) {
                          [uploader uploadFileToFolder:filePath fileName:fileName toFolder:item.toFolder];
                          
                      } else if (item.toEntry != nil) {
                          [uploader uploadFileToEntry:filePath fileName:fileName toEntry:item.toEntry];
                          
                      } else {
                          DLog(@"Error: there is no upload destination.");
                      }
                      
                  } failureBlock:^(NSError *error) {
                      DLog(@"Error: %@", error);
                  }
         ];

    } else {
        DLog(@"Upload asset at URL: %@", item.itemUrl);
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:item.itemUrl.path];
        
        NSString *fileName = [item.itemUrl lastPathComponent];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths objectAtIndex:0];
        NSString* filePath = [NSString stringWithFormat:@"%@/upload_tmp_%@.%@", cachesDirectory, item.sessionKey, [fileName pathExtension]];
        [data writeToFile:filePath atomically:YES];

        if (item.toFolder != nil) {
            [uploader uploadFileToFolder:filePath fileName:fileName toFolder:item.toFolder];
            
        } else if (item.toEntry != nil) {
            [uploader uploadFileToEntry:filePath fileName:fileName toEntry:item.toEntry];
            
        } else {
            DLog(@"Error: there is no upload destination.");
        }
    }
}


- (UploadItem*)nextUploadItem {
    for (UploadItem *item in self.uploadItems) {
        if (item.status == WAITING) {
            return item;
        }
    }
    return nil;
}


- (void)removeUploadItem:(UploadItem*)itemToRemove {
    int index = -1;
    for (int i=0; i<_uploadItems.count; i++) {
        if ([[[_uploadItems objectAtIndex:i] sessionKey] isEqualToString:itemToRemove.sessionKey]) {
            index = i;
        }
    }
    if (index != -1) {
        [_uploadItems removeObjectAtIndex:index];
        [self.uploadHelperDelegate updateUploadItemStatus:nil];
    }
}


- (void)cancelUpload:(UploadItem*)canceledItem {
    NSArray *items = [self uploadItems];
    
    for (UploadItem *item in items) {
        if ([item.sessionKey isEqualToString:canceledItem.sessionKey]) {
            item.status = CANCELED;
            
            DLog(@"Cancel the upload session: %@", item.sessionKey);
            UploadService *uploader = [self.uploaderPool objectForKey:canceledItem.sessionKey];
            uploader.shouldCancelUpload = YES;

            [self removeUploadItem:item];

            break;
        }
    }
}


- (void)retryUpload:(UploadItem*)item {
    NSArray *items = [self uploadItems];
    
    for (UploadItem *item in items) {
        if ([item.sessionKey isEqualToString:item.sessionKey]) {
            if (item.status != UPLOADING && item.status != COMPLETED) {
                item.status = WAITING;
            }
        }
    }
}


- (void)cleanup {
    NSMutableArray *itemsIncomplete = [[NSMutableArray alloc] init];
    for (UploadItem *item in _uploadItems) {
        if (item.status != COMPLETED) {
            [itemsIncomplete addObject:item];
        }
    }
    _uploadItems = itemsIncomplete;
}


# pragma mark - UploadService delegate

// This is received for each upload item. It is used for uploading asset urls or individual image.
- (void)uploadComplete:(NSString *)sessionKey returnedEntry:(NPEntry *)returnedEntry {
    for (UploadItem *item in self.uploadItems) {
        if ([item.sessionKey isEqualToString:sessionKey]) {
            item.status = COMPLETED;
            
            DLog(@"Remove the uploader for session: %@", item.sessionKey);
            [self.uploaderPool removeObjectForKey:item.sessionKey];

            // Update visual status
            if (self.uploadHelperDelegate) {
                [self.uploadHelperDelegate updateUploadItemStatus:item];
            }

            break;
        }
    }
    
    UploadItem *nextItem = [self nextUploadItem];
    
    if (nextItem != nil) {
        DLog(@"Continue to upload next item.");
        [self upload:nextItem];
        
    } else {
        // At this point, there might be items BEING uploaded.
        DLog(@"No more item waiting to be uploaded...send destination data refresh notification");
        
        NSMutableArray *notifyDests = [[NSMutableArray alloc] init];
        
        for (UploadItem *item in self.uploadItems) {
            if (item.status == COMPLETED) {
                if (item.toEntry != nil) {
                    if (![notifyDests containsObject:item.toEntry]) {
                        [notifyDests addObject:item.toEntry];
                    }
                } else if (item.toFolder != nil) {
                    if (![notifyDests containsObject:item.toFolder]) {
                        [notifyDests addObject:item.toFolder];
                    }
                }
            }

            DLog(@"Upload item final status: %@", item);
        }
        
        if (notifyDests.count > 0) {
            for (id dest in notifyDests) {
                if ([dest isKindOfClass:[NPFolder class]] || [dest isKindOfClass:[NPEntry class]]) {
                    DLog(@"Notify upload destination: %@", dest);
                    [NPServiceNotificationUtil sendDataRefreshNotification:dest];
                }
            }
        }
        
        // Clean up the caches directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths objectAtIndex:0];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *cachedFiles = [manager contentsOfDirectoryAtPath:cachesDirectory error:nil];
        
        // use fast enumeration to iterate the array and delete the files
        for (NSString *aFile in cachedFiles) {
            NSError *error = nil;
            
            if ([aFile rangeOfString:@"upload_tmp_"].location != NSNotFound ||
                [aFile rangeOfString:@"Picture note"].location != NSNotFound)
            {
                DLog(@"Remove upload tmp file: %@", aFile);
                [manager removeItemAtPath:[cachesDirectory stringByAppendingPathComponent:aFile] error:&error];
            }
        }
    }
}


- (void)updateProgress:(NSNumber *)completedBytes totalUploadBytes:(NSNumber *)totalBytes sessionKey:(NSString *)sessionKey {
    for (UploadItem *item in self.uploadItems) {
        if ([item.sessionKey isEqualToString:sessionKey]) {
            item.status = UPLOADING;
            if (totalBytes != 0) {
                item.percentage = [completedBytes floatValue]/[totalBytes floatValue];
            }
            
            if (self.uploadHelperDelegate) {
                [self.uploadHelperDelegate updateUploadItemStatus:item];
            }
            
            break;
        }
    }
}


- (void)uploadCanceled:(NSString *)sessionKey {
    for (UploadItem *item in self.uploadItems) {
        if ([item.sessionKey isEqualToString:sessionKey]) {
            item.status = CANCELED;
            
            if (self.uploadHelperDelegate) {
                [self.uploadHelperDelegate updateUploadItemStatus:item];
            }
            
            break;
        }
    }
}

- (void)uploadError:(NSString *)reason sessionKey:(NSString *)sessionKey {
    for (UploadItem *item in self.uploadItems) {
        if ([item.sessionKey isEqualToString:sessionKey]) {
            item.status = ERROR;
            
            if (self.uploadHelperDelegate) {
                [self.uploadHelperDelegate updateUploadItemStatus:item];
            }
            
            break;
        }
    }
}

@end
