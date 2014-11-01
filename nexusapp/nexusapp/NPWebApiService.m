//
//  NPWebApiService.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"
#import "AFNetworking/AFNetworking.h"
#import "NPService.h"
#import "AccountManager.h"
#import "NSString+NPStringUtil.h"
#import "Reachability.h"
#import "DataStore.h"


@implementation NPWebApiService

@synthesize responseData = _responseData;

- (void)doGet:(NSString *)urlAsString
   completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion
{
    NSString *requestUrl = urlAsString;
    requestUrl = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    requestUrl = [NPWebApiService appendAuthParams:requestUrl];
    DLog(@"GET request to URL: %@", requestUrl);
    
    NSURL *url = [NSURL URLWithString:requestUrl];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:[NPWebApiService timeoutValue]];
    [urlRequest setHTTPMethod:@"GET"];
    
    [self doRequest:urlRequest completion:completion];
}

- (void)doPost:(NSString *)urlAsString
    parameters:(NSDictionary*)parameters
    completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion
{
    urlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlAsString = [NPWebApiService appendAuthParams:urlAsString];
    
    DLog(@"POST request to URL: %@", urlAsString);
    DLog(@"POST request parameters: %@", [parameters description]);
    
    
    NSError *error = nil;
    
    NSMutableURLRequest *urlRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST"
                                                                                    URLString:urlAsString
                                                                                   parameters:parameters
                                                                                        error:&error];
    
    [urlRequest setTimeoutInterval:[NPWebApiService timeoutValue]];
    [self doRequest:urlRequest completion:completion];
}

- (void)doDelete:(NSString *)urlAsString
      parameters:(NSDictionary*)parameters
      completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion
{
    urlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlAsString = [NPWebApiService appendAuthParams:urlAsString];
    
    DLog(@"DELETE request to URL: %@", urlAsString);
    
    NSError *error = nil;
    
    NSMutableURLRequest *urlRequest = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"DELETE"
                                                                                    URLString:urlAsString
                                                                                   parameters:parameters
                                                                                        error:&error];
    
    [urlRequest setTimeoutInterval:[NPWebApiService timeoutValue]];
    [self doRequest:urlRequest completion:completion];
}

- (void)doRequest:(NSURLRequest *)request
       completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (self.responseData == nil) {
            self.responseData = [[NSMutableData alloc] init];
        }
        [self.responseData setLength:0];
        [self.responseData appendData:responseObject];
        
        if (completion) {
            completion(YES, request, self.responseData);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle the error properly
        DLog(@"Web service error: \n%@ \n%@", operation.responseString, operation.request.URL.description);
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        // Handles athentication error.
        if ([operation.response statusCode] == 401 || [operation.response statusCode] == 403) {
            if ([self.serviceDelegate respondsToSelector:@selector(serviceDeniedAccess:)]) {
                [self.serviceDelegate serviceDeniedAccess:nil];
            }

        } else {
            if ([self.serviceDelegate respondsToSelector:@selector(serviceError:)]) {
                ServiceResult *result = [[ServiceResult alloc] initWithCodeAndMessage:NP_WEB_SERVICE_NOT_AVAILABLE
                                                                              message:NSLocalizedString(@"Web service not available.",)];
                [self.serviceDelegate serviceError:result];
                
            }
        }
        
        // This can handle ServiceError response such as a WiFi is available, but not connected to Internet.
        if (completion) {
            completion(NO, request, nil);
        }
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [[[AFHTTPRequestOperationManager manager] operationQueue] addOperation:operation];
}


+ (float)timeoutValue {
    float timeoutSeconds = 4.0;
    switch ([NPService getServiceSpeed]) {
        case threeG:
            timeoutSeconds = 4.0;
            break;
        case wifi:
            timeoutSeconds = 4.0;
            break;
        case lte:
            timeoutSeconds = 4.0;
            break;
        case none:
            timeoutSeconds = 1.0;
            break;
        default:
            break;
    }
    
    return timeoutSeconds;
}

+ (NSString*)getUToken {
    return [[AccountManager instance] getSessionId];
}

+ (NSString*)getUUID {
    return [[AccountManager instance] getUUID];
}

+ (NSString*)appendAuthParams:(NSString*)urlString {
    NSString *urlStr = [self appendParamToUrlString:urlString paramName:NP_UTOKEN_PARAM paramValue:[self getUToken]];
    return [self appendParamToUrlString:urlStr paramName:NP_UUID paramValue:[NPWebApiService getUUID]];
}

+ (NSString*)appendOwnerParam:(NSString*)urlString ownerId:(int)ownerId {
    if (ownerId != 0) {
        return [self appendParamToUrlString:urlString paramName:OWNER_ID paramValue:[NSString stringWithFormat:@"%d", ownerId]];
    } else {
        return urlString;
    }
}

+ (NSString*)appendParamToUrlString:(NSString*)urlAsString paramName:(NSString*)name paramValue:(NSString*)value {
    if ([urlAsString rangeOfString:@"?"].location == NSNotFound) {
        return [NSString stringWithFormat:@"%@?%@=%@", urlAsString, name, value];
    } else {
        return [NSString stringWithFormat:@"%@&%@=%@", urlAsString, name, value];
    }
}

+ (NSArray*)toUrlParamArr:(NSDictionary*)params {
    NSMutableArray *paramArr = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [params keyEnumerator];
    id key;
    
    while ((key = [enumerator nextObject])) {
        id value = [params valueForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            [paramArr addObject:[NSString stringWithFormat:@"%@=%@", key, [NSString convertStringForPosting:value]]];
        } else {
            [paramArr addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
        }
    }
    
    return paramArr;
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    [self.responseData setLength:0];
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.responseData appendData:data];
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    // Handle the error properly
    DLog(@"Web service error: \n%@", error);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if ([self.serviceDelegate respondsToSelector:@selector(serviceError:)]) {
        ServiceResult *result = [[ServiceResult alloc] initWithCodeAndMessage:NP_WEB_SERVICE_NOT_AVAILABLE
                                                                      message:NSLocalizedString(@"Web service not available.",)];
        [self.serviceDelegate serviceError:result];
    }
}


@end
