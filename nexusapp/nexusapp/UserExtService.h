//
//  ExtUserService.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/12/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROVIDER_GOOGLE     @"google"
#define OAUTH_URL           @"oauth_url"

#define SERVICE_CALENDAR    @"calendar"
#define SERVICE_CONTACT     @"contact"
#define LAST_SYNC_TIME      @"last_sync_time"


@interface UserExtService : NSObject

// Google service
@property BOOL googleOauthed;
@property (nonatomic, strong) NSString* googleOauthUrl;

@property BOOL googleCalendarSync;
@property BOOL googleContactSync;

// Phone contact service
@property BOOL phoneContactSync;

@property NSDate* lastSyncTime;

- (id)initWithServiceData:(NSDictionary*)serviceData;

@end
