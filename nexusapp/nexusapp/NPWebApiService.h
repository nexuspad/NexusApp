//
//  NPWebApiService.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPService.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "HostInfo.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"


@interface NPWebApiService : NPService

@property (nonatomic, strong) NSMutableData *responseData;

- (void)doGet:(NSString *)urlAsString
   completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion;

- (void)doPost:(NSString *)urlAsString
    parameters:(NSDictionary*)parameters
    completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion;

- (void)doDelete:(NSString *)urlAsString
      parameters:(NSDictionary*)parameters
      completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion;

- (void)doRequest:(NSURLRequest *)request
       completion:(void (^)(BOOL success, NSURLRequest *originalRequest, NSData *responseData))completion;

+ (float)timeoutValue;

+ (NSString*)getUToken;
+ (NSString*)getUUID;
+ (NSString*)appendAuthParams:(NSString*)urlString;
+ (NSString*)appendOwnerParam:(NSString*)urlString ownerId:(int)ownerId;
+ (NSString*)appendParamToUrlString:(NSString*)urlAsString paramName:(NSString*)name paramValue:(NSString*)value;

+ (NSArray*)toUrlParamArr:(NSDictionary*)params;

@end
