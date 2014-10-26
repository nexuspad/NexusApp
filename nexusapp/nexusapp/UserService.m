//
//  UserService.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/6/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "UserService.h"
#import "NPModule.h"

@implementation UserService

- (void)getSharers:(int)moduleId
        completion:(void (^)(NSArray *sharers))completion
{
    if ([NPService isServiceAvailable] == YES) {
        NSString *sharersUrl = [NSString stringWithFormat:@"%@/sharing/%@/sharers", [[HostInfo current] getApiUrl], [NPModule getModuleCode:moduleId]];
        
        self.responseData = [[NSMutableData alloc] init];
        
        [self doGet:sharersUrl
         completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
             if (responseData != nil) {
                 NSError *error = nil;
                 NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                 
                 ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                 
                 if (result.success) {
                     NSMutableArray *sharers = [[NSMutableArray alloc] init];
                     
                     if ([result.body objectForKey:@"sharers"]) {
                         NSMutableArray *sharerRecords = [[NSMutableArray alloc] init];
                         [sharerRecords addObjectsFromArray:[result.body objectForKey:@"sharers"]];
                         
                         if ([sharerRecords count] > 0) {
                             for (NSDictionary *userDict in sharerRecords) {
                                 NPUser *sharer = [[NPUser alloc] initWithData:userDict];
                                 [sharers addObject:sharer];
                             }
                             
                             completion(sharers);
                         }
                     }
                 }
             }
         }];
    }
}

@end
