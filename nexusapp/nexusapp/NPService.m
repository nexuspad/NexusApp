//
//  NPService.m
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "NPService.h"
#import "AccountManager.h"

@implementation NPService

static ServiceSpeed serviceSpeed = none;

- (id)init {
    self = [super init];
    return self;
}

+ (void)setServiceSpeed:(ServiceSpeed)speed {
    serviceSpeed = speed;
}

+ (ServiceSpeed)getServiceSpeed {
    return serviceSpeed;
}

+ (BOOL)isServiceAvailable {
    if (serviceSpeed == none) {
        return NO;
    }
    return YES;
}

+ (BOOL)isLoggedIn {
    NSString *sessionId = [[AccountManager instance] getSessionId];
    
    if (sessionId == nil || [sessionId length] == 0) {
        return NO;
    }
    
    return YES;
}

@end
