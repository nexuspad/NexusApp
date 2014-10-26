//
//  UploadItem.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/2/14.
//  Copyright (c) 2014 Ren Liu. All rights reserved.
//

#import "UploadItem.h"

@implementation UploadItem

@synthesize sessionKey, image = _image, itemUrl = _itemUrl, toEntry, toFolder, status;

- (id)initWithAssetUrl:(NSURL*)assetUrl destination:(id)destination {
    self = [super init];
    
    _itemUrl = assetUrl;
    
    if ([destination isKindOfClass:[NPFolder class]]) {
        self.toFolder = [(NPFolder*)destination copy];
        
    } else if ([destination isKindOfClass:[NPEntry class]]) {
        self.toEntry = [(NPEntry*)destination copy];
    }
    
    self.status = WAITING;
    
    return self;
}

- (id)initWithSingleImage:(UIImage *)image destination:(id)destination {
    self = [super init];
    
    _image = image;
    
    if ([destination isKindOfClass:[NPFolder class]]) {
        self.toFolder = [(NPFolder*)destination copy];
        
    } else if ([destination isKindOfClass:[NPEntry class]]) {
        self.toEntry = [(NPEntry*)destination copy];
    }
    
    self.status = WAITING;
    
    return self;
}

- (NSString*)uploadStatusString {
    switch (status) {
        case WAITING:
            return NSLocalizedString(@"WAITING",);
        case UPLOADING:
            return NSLocalizedString(@"UPLOADING",);
        case COMPLETED:
            return NSLocalizedString(@"COMPLETED",);
        case CANCELED:
            return NSLocalizedString(@"CANCELED",);
        case ERROR:
            return NSLocalizedString(@"ERROR",);
            
        default:
            break;
    }
    
    return @"";
}


- (NSString*)description {
    return [NSString stringWithFormat:@"%@ - status: %d", sessionKey, status];
}

@end
