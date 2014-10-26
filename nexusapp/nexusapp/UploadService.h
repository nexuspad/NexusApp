//
//  UploadService.h
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPWebApiService.h"
#import "NPFolder.h"
#import "NPEntry.h"

#define UPLOAD_INPUT_NAME @"Upload_0"
#define UPLOAD_BOUNDRY @"--0xKhTmLbOuNdArY"

@protocol UploadServiceProgressDelegate <NSObject>
- (void)updateProgress:(NSNumber*)completedBytes totalUploadBytes:(NSNumber*)totalBytes sessionKey:(NSString*)sessionKey;
- (void)uploadComplete:(NSString*)sessionKey returnedEntry:(NPEntry*)returnedEntry;
- (void)uploadCanceled:(NSString*)sessionKey;
- (void)uploadError:(NSString*)reason sessionKey:(NSString*)sessionKey;
@end

@interface UploadService : NPWebApiService

@property (nonatomic, strong) NSString *uploadSessionKey;

@property (nonatomic, weak) id<UploadServiceProgressDelegate> progressDelegate;

@property BOOL shouldCancelUpload;

- (void)postToServer:(NSString*)urlAsString data:(NSData*)data params:(NSMutableDictionary*)params;

// Generic upload methods
- (void)uploadDataToFolder:(NSData*)fileData fileName:(NSString*)fileName toFolder:(NPFolder*)toFolder;
- (void)uploadFileToFolder:(NSString*)filePath fileName:(NSString*)fileName toFolder:(NPFolder*)toFolder;
- (void)uploadFileToEntry:(NSString*)filePath fileName:(NSString*)fileName toEntry:(NPEntry*)entry;

- (BOOL)hasActiveSession;

@end
