//
//  AcctService.h
//  nexuspad
//
//  Created by Ren Liu on 5/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPWebApiService.h"
#import "Account.h"

// Hardcoded parameters for REST interface
#define NP_ACCT_LOGIN       @"login"
#define NP_ACCT_PASS        @"password"


// AcctService is solely used to log in user. It is mostly consumed by AcctManager.
// Notice it is not a subclass of NPService.
@interface AccountService : NPWebApiService

- (Account*)login:(NSString*)userName password:(NSString*)password;

- (Account*)createAccount:(Account*)newAcct;

- (void)getSettingsAndUsageInfo:(Account*)acct;

- (void)checkSpaceUsage:(NPUser*)user completion:(void (^)(BOOL spaceLeft))completion;

- (void)resetPassword:(NSString*)email;

- (void)turnOffExternalService:(NSString*)provider;

@property (nonatomic, weak) id<NPDataServiceDelegate> serviceDelegate;

@end
