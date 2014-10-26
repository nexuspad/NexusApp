//
//  UserManager.h
//  NexusAppCore
//
//  Created by Ren Liu on 1/6/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPUser.h"
#import "AccessEntitlement.h"

@interface UserManager : NSObject

@property (nonatomic, strong) NPUser *currentUser;
@property (nonatomic, strong) NPUser *itemOwner;

+ (UserManager*)instance;

+ (AccessEntitlement*)storeOwnerAccessInfo;

- (NPUser*)getItemOwner;
- (AccessEntitlement*)defaultAccessInfo;
- (AccessEntitlement*)accessInfo:(NPUser *)viewer owner:(NPUser*)owner;

@end
