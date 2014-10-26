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

@interface ContactVcardUploadService()
@property (nonatomic, strong) AFHTTPClient *httpClient;
@end

@implementation ContactVcardUploadService

- (void)uploadToServer:(NSData*)vcardData params:(NSMutableDictionary*)params {
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", [[HostInfo current] getApiUrl], [NPModule getModuleCode:CONTACT_MODULE]];

    urlStr = [NPWebApiService appendAuthParams:urlStr];

    NSURL *url = [NSURL URLWithString:urlStr];
    
    DLog(@"POST upload request to URL: %@", urlStr);
    
    if (self.httpClient == nil) {
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    }
    
    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:@"POST"
                                                                             path:@""
                                                                       parameters:params
                                                        constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                            [formData appendPartWithFormData:vcardData
                                                                                        name:@"filename"];
                                                            
                                                        }];
    
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
