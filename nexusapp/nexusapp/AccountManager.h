//
//  AcctManager.h
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Account.h"
#import "KeychainItemWrapper.h"
#import "AccountService.h"


@interface AccountManager : NSObject

@property (nonatomic, strong) AccountService *acctService;
@property (nonatomic, strong) KeychainItemWrapper *keyChainItem;
@property (nonatomic, retain) Account* currentLoginAcct;

+ (AccountManager*)instance;

- (NSString*)getSessionId;              // Created on the server side
- (NSString*)getUUID;                   // Created on the client side

- (BOOL)resetPassword:(NSString*)email;
- (Account*)login:(NSString*)login password:(NSString *)password;
- (BOOL)loginWithStoredInfo;
- (void)logout;

- (Account*)createAccount:(Account*)acct;

- (void)saveUserPrefValue:(NSString*)key value:(id)value;
- (id)getUserPrefValue:(NSString*)key;

- (Account*)getCurrentLoginAcct;

@end
