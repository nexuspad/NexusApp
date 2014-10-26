//
//  ExtUserService.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/12/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "UserExtService.h"

@implementation UserExtService

- (id)initWithServiceData:(NSDictionary*)serviceData {
    self = [super init];
    
    // Parse the JSON response
    if ([serviceData objectForKey:PROVIDER_GOOGLE]) {
        NSDictionary *googleService = [serviceData objectForKey:PROVIDER_GOOGLE];
        
        if ([googleService objectForKey:OAUTH_URL] != nil) {
            self.googleOauthUrl = [googleService valueForKey:OAUTH_URL];

        } else {
            if ([googleService objectForKey:SERVICE_CALENDAR] != nil) {
                self.googleOauthed = YES;
                self.googleCalendarSync = YES;
            }
            
            if ([googleService objectForKey:SERVICE_CONTACT] != nil) {
                self.googleOauthed = YES;
                self.googleContactSync = YES;
            }
            
            if ([googleService objectForKey:LAST_SYNC_TIME] != nil) {
                self.lastSyncTime = [NSDate dateWithTimeIntervalSince1970:[[googleService valueForKey:LAST_SYNC_TIME] longLongValue]];
            }
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    UserExtService *service = [[UserExtService alloc] init];
    
    if (self.googleOauthUrl != nil) {
        service.googleOauthUrl = [NSString stringWithString:self.googleOauthUrl];
    }

    service.googleOauthed = self.googleOauthed;
    service.googleCalendarSync = self.googleCalendarSync;
    service.googleContactSync = self.googleContactSync;

    service.phoneContactSync = self.phoneContactSync;
    
    return service;
}

@end
