//
//  ContactVcardUploadService.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/16/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "ContactVcardUploadService.h"
#import "NPModule.h"
#import "NPFolder.h"


@implementation ContactVcardUploadService

- (void)uploadToServer:(NSData*)vcardData params:(NSMutableDictionary*)params {
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", [[HostInfo current] getApiUrl], [NPModule getModuleCode:CONTACT_MODULE]];

    urlStr = [NPWebApiService appendAuthParams:urlStr];
    
    DLog(@"POST upload request to URL: %@", urlStr);
    
    NSError *error = nil;
    
    NSMutableURLRequest *request =
    [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                               URLString:urlStr
                                                              parameters:nil
                                               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                   [formData appendPartWithFileData:vcardData
                                                                               name:@"filename"
                                                                           fileName:[params valueForKey:@"file_name"]
                                                                           mimeType:@"application/octet-stream"];
                                               }
                                                                   error:&error];

    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        // Handle the error properly
        DLog(@"Upload contact vcard data failed with error: %@", [error description]);
    }];
    
    [operation start];

}

@end
