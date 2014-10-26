//
//  PhotoUploadService.m
//  NexusAppCore
//
//  Created by Ren Liu on 12/4/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "ProfilePhotoService.h"

@implementation ProfilePhotoService

// Upload a profile photo
- (void)addPhotoToContact:(NSData*)data fileName:(NSString*)fileName toEntry:(NPEntry*)entry {
    NSString *urlStr = [NSString stringWithFormat:@"%@/contact/%@/photo", [[HostInfo current] getApiUrl], entry.entryId];

    urlStr = [NPWebApiService appendAuthParams:urlStr];
    urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:entry.accessInfo.owner.userId];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, nil]
                                                                     forKeys:[NSArray arrayWithObjects:@"file_name", nil]];
    
    [self postToServer:urlStr data:data params:params];
}


- (void)deleteContactPhoto:(NSString*)entryId ownerId:(int)ownerId {
    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@/contact/%@/photo",
                        [[HostInfo current] getApiUrl],
                        entryId];
    
    urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:ownerId];
    
    [self doDelete:urlStr parameters:nil completion:nil];
}


- (void)addMyProfilePhoto:(NSData*)data fileName:(NSString*)fileName {
    NSString *urlStr = [NSString stringWithFormat:@"%@/user/profile/photo", [[HostInfo current] getApiUrl]];
    urlStr = [NPWebApiService appendAuthParams:urlStr];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, nil]
                                                                     forKeys:[NSArray arrayWithObjects:@"file_name", nil]];
    
    [self postToServer:urlStr data:data params:params];
}


- (void)deleteMyProfilePhoto {
    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@/user/profile/photo", [[HostInfo current] getApiUrl]];
    [self doDelete:urlStr parameters:nil completion:nil];
}

@end
