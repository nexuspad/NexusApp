//
//  UploadService.m
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UploadService.h"
#import "NPModule.h"
#import "EntryActionResult.h"

@interface UploadService()
@property (nonatomic, strong) NSURLConnection *connection;
@property long currentUploadSize;
@property BOOL sessionActive;
- (void)postToServer : (NSString*)urlAsString data:(NSData*)data params:(NSMutableDictionary*)params;
@end

@implementation UploadService
@synthesize progressDelegate = _progressDelegate;
@synthesize uploadSessionKey;

- (id)init
{
    self = [super init];
    self.currentUploadSize = 0;
    self.sessionActive = NO;
    self.shouldCancelUpload = NO;
    return self;
}

- (NSString*)uploadToFolderPostUrl:(NPFolder*)toFolder fileName:(NSString*)fileName {
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", [[HostInfo current] getApiUrl], [NPModule getModuleCode:toFolder.moduleId]];
    urlStr = [NPWebApiService appendParamToUrlString:urlStr paramName:@"folder_id" paramValue:[NSString stringWithFormat:@"%d", toFolder.folderId]];
    
    if (![toFolder.accessInfo iAmOwner]) {
        urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:toFolder.accessInfo.owner.userId];
    }
    
    return urlStr;
}


- (NSString*)uploadToEntryPostUrl:(NPEntry*)entry fileName:(NSString*)fileName {
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/%@",
                                    [[HostInfo current] getApiUrl],
                                    [EntryTemplate convertToCode:entry.templateId],
                                    entry.entryId];
    
    if (![entry.accessInfo iAmOwner]) {
        urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:entry.accessInfo.owner.userId];
    }
    
    return urlStr;
}


// Upload data to folder
- (void)uploadDataToFolder:(NSData*)fileData fileName:(NSString*)fileName toFolder:(NPFolder*)toFolder {
    NSString *urlStr = [self uploadToFolderPostUrl:toFolder fileName:fileName];
    
    urlStr = [NPWebApiService appendAuthParams:urlStr];

    NSMutableDictionary *params = nil;
    
    params = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, [NSNumber numberWithInt:toFolder.folderId], nil]
                                                forKeys:[NSArray arrayWithObjects:@"file_name", @"folder_id", nil]];

    NSError *error = nil;    
    if (error == nil) {
        [self postToServer:urlStr data:fileData params:params];
    } else {
        [self.progressDelegate uploadError:[error description] sessionKey:self.uploadSessionKey];
    }
}

// Upload file to folder
- (void)uploadFileToFolder:(NSString*)filePath fileName:(NSString*)fileName toFolder:(NPFolder*)toFolder {
    NSString *urlStr = [self uploadToFolderPostUrl:toFolder fileName:fileName];
    
    urlStr = [NPWebApiService appendAuthParams:urlStr];
    
    NSMutableDictionary *params = nil;
    
    params = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, [NSNumber numberWithInt:toFolder.folderId], nil]
                                                forKeys:[NSArray arrayWithObjects:@"file_name", @"folder_id", nil]];
    
    NSError *error = nil;
    NSData *uploadData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&error];
    
    if (error == nil) {
        [self postToServer:urlStr data:uploadData params:params];
    } else {
        [self.progressDelegate uploadError:[error description] sessionKey:self.uploadSessionKey];
    }
}

// Upload file to entry
- (void)uploadFileToEntry:(NSString*)filePath fileName:(NSString*)fileName toEntry:(NPEntry*)entry {
    NSString *urlStr = [self uploadToEntryPostUrl:entry fileName:fileName];
    
    urlStr = [NPWebApiService appendAuthParams:urlStr];
    
    NSError *error = nil;
    NSData *uploadData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&error];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:fileName, nil]
                                                                     forKeys:[NSArray arrayWithObjects:@"file_name", nil]];
    
    if (error == nil) {
        [self postToServer:urlStr data:uploadData params:params];
    } else {
        [self.progressDelegate uploadError:[error description] sessionKey:self.uploadSessionKey];
    }
}


- (BOOL)hasActiveSession {
    return self.sessionActive;
}

- (void)postToServer:(NSString*)urlAsString data:(NSData*)data params:(NSMutableDictionary*)params {    
    DLog(@"POST upload request to URL: %@", urlAsString);
    
    self.sessionActive = YES;
    self.shouldCancelUpload = NO;
    self.currentUploadSize = [data length];
    
    NSDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
    
    NSError *error = nil;
    
    NSMutableURLRequest *request =
    [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                               URLString:urlAsString
                                                              parameters:parameters
                                               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                   [formData appendPartWithFileData:data
                                                                               name:@"filename"
                                                                           fileName:[params valueForKey:@"file_name"]
                                                                           mimeType:@"image/jpeg"];
                                               }
                                                                   error:&error];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __weak AFHTTPRequestOperation *operationRef = operation;

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (self.shouldCancelUpload) {
            DLog(@"Received cancel request for session:%@, upload is cancelled.", self.uploadSessionKey);
            self.sessionActive = NO;
            [operationRef cancel];
            [self.progressDelegate uploadCanceled:self.uploadSessionKey];
            
        } else {
            if (self.progressDelegate != nil) {
                [self.progressDelegate updateProgress:[NSNumber numberWithLongLong:totalBytesWritten]
                                     totalUploadBytes:[NSNumber numberWithLongLong:self.currentUploadSize]
                                           sessionKey:self.uploadSessionKey];
            }
        }
    }];
    
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        if (self.responseData == nil) {
            self.responseData = [[NSMutableData alloc] init];
        }
        [self.responseData setLength:0];
        [self.responseData appendData:responseObject];

        NSError *error = nil;
        if (!self.responseData) return;
        
        NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&error];
        
        self.sessionActive = NO;
        
        ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
        
        NPEntry *returnedEntry = nil;
        
        if (result.success) {
            /*
             * Entry action response
             */
            if ([result isEntryActionResponse]) {
                EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                
                /*
                 * Update the data store.
                 * Server response is the truth of the data.
                 */
                if (entryActionResult.success) {
                    if ([entryActionResult.name isEqualToString:ACTION_UPLOAD_ENTRY]) {
                        returnedEntry = entryActionResult.entry;
                    }
                }
            }
            
            [self.progressDelegate uploadComplete:self.uploadSessionKey returnedEntry:returnedEntry];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        // Handle the error properly
        DLog(@"Upload session %@ connection failed with error: %@", self.uploadSessionKey, [error description]);
        self.sessionActive = NO;
        
        if (self.shouldCancelUpload) {                  // The failure was probably caused by attempting to cancel the upload
            [self.progressDelegate uploadCanceled:self.uploadSessionKey];
        } else {
            [operationRef cancel];
            [self.progressDelegate uploadError:NSLocalizedString(@"Upload has encountered error",) sessionKey:self.uploadSessionKey];
        }
    }];

    [operation start];
}


@end
