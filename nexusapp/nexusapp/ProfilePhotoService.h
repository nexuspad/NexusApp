//
//  PhotoUploadService.h
//  NexusAppCore
//
//  Created by Ren Liu on 12/4/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "UploadService.h"

@interface ProfilePhotoService : UploadService

- (void)addPhotoToContact:(NSData*)data fileName:(NSString*)fileName toEntry:(NPEntry*)entry;
- (void)deleteContactPhoto:(NSString*)entryId ownerId:(int)ownerId;

- (void)addMyProfilePhoto:(NSData*)data fileName:(NSString*)fileName;
- (void)deleteMyProfilePhoto;

@end
