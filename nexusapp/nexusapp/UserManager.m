//
//  UserManager.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/6/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "UserManager.h"

@implementation UserManager

static UserManager* theManager = nil;
static AccessEntitlement *storeOwnerAccessInfo;

@synthesize currentUser = _currentUser, itemOwner = _itemOwner;

+ (UserManager*)instance {
    if (theManager == nil) {
        theManager = [[UserManager alloc] init];
    }
    return theManager;
}

+ (AccessEntitlement*)storeOwnerAccessInfo {
    if (storeOwnerAccessInfo == nil)
        storeOwnerAccessInfo = [[UserManager instance] defaultAccessInfo];
    return storeOwnerAccessInfo;
}

- (NPUser*)getItemOwner {
    if (_itemOwner == nil) {
        return _currentUser;
    }
    
    return _itemOwner;
}

- (AccessEntitlement*)defaultAccessInfo {
    AccessEntitlement *accessInfo = [[AccessEntitlement alloc] init];
    accessInfo.owner = [_currentUser copy];
    accessInfo.viewer = [_currentUser copy];
    accessInfo.read = YES;
    accessInfo.write = YES;
    
    return accessInfo;
}

- (AccessEntitlement*)accessInfo:(NPUser *)viewer owner:(NPUser*)owner {
    AccessEntitlement *accessInfo = [[AccessEntitlement alloc] init];
    accessInfo.owner = [owner copy];
    accessInfo.viewer = [viewer copy];
    accessInfo.read = NO;
    accessInfo.write = NO;
    
    return accessInfo;
}

@end
