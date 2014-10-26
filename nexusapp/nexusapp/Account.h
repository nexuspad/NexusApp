//
//  Account.h
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPUser.h"
#import "UserExtService.h"
#import "UserPreference.h"

@interface Account : NPUser

@property (nonatomic, strong) NSString *errorCode;      // This is used to handle both login and register error code

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *sessionId;

@property (nonatomic, strong) UserPreference *preference;

@property float spaceAllocation;
@property float spaceUsage;

@property (nonatomic, strong) UserExtService *externalService;

- (BOOL)isLoggedIn;
- (id)initWithData:(NSDictionary*)dict;

- (NSString*)profileImageUrlForEditing;                 // For settings screen. Returns null is not available

- (void)setTimezoneStr:(NSString *)timezoneStr;
- (void)setLocaleStr:(NSString*)localeStr;

@end
