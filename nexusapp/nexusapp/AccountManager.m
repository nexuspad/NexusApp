//
//  AcctManager.m
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountManager.h"
#import "NPService.h"
#import "DataStore.h"
#import "SyncDownService.h"
#import "UserPrefUtil.h"
#import "NSString+NPStringUtil.h"

@interface AccountManager ()
@end

@implementation AccountManager

static AccountManager* theManager = nil;

@synthesize acctService = _acctService;
@synthesize keyChainItem = _keyChainItem;
@synthesize currentLoginAcct = _currentLoginAcct;

+ (AccountManager*)instance {
    if (theManager == nil) {
        theManager = [[AccountManager alloc] init];
    }
    return theManager;
}

- (AccountManager*)init {
    if (self = [super init]) {
        self.keyChainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"NexusPadApp" accessGroup:nil];
        _currentLoginAcct.userId = 0;
    }

    return self;
}

- (BOOL)resetPassword:(NSString*)email {
    if (self.acctService == nil) {
        self.acctService = [[AccountService alloc] init];
    }
    [self.acctService resetPassword:email];

    // Always returns YES
    return YES;
}

- (Account*)login:(NSString*)login password:(NSString *)password {
    if (self.acctService == nil) {
        self.acctService = [[AccountService alloc] init];
    }
    
    DLog(@"Login with this: %@, %@", login, password);

    Account *acct = [self.acctService login:login password:password];

    if (acct.userId > 0) {
        DLog(@"Account detail stored in preference.");

        _currentLoginAcct = [acct copy];
        
        [self.keyChainItem setObject:acct.userName forKey:(__bridge id)kSecAttrAccount];
        [self.keyChainItem setObject:password forKey:(__bridge id)kSecValueData];
        
        [self saveUserAccount:_currentLoginAcct];

    } else {             // This captures the error condition
        _currentLoginAcct = [[Account alloc] init];
        _currentLoginAcct.userId = -1;
        _currentLoginAcct.errorCode = acct.errorCode;
        
        [self clearUserAccount];
    }
    
    DLog(@"Account detail: %@", _currentLoginAcct);
    
    return _currentLoginAcct;
}

// Using the login credential stored in keychain
- (BOOL)loginWithStoredInfo {
    NSString *login = [self.keyChainItem objectForKey:(__bridge id)kSecAttrAccount];
    NSString *pass = [self.keyChainItem objectForKey:(__bridge id)kSecValueData];

    if ((login != nil && [login length] != 0) && (pass != nil && [pass length] != 0)) {
        DLog(@"Try to re-login with keychain data: %@ %@", login, pass);
        [self login:login password:pass];
        return YES;

    } else {
        return NO;
    }
}

- (void)logout {
    _currentLoginAcct = nil;
    
    // Remove the data store records
    DLog(@"----> Clear data store...");
    dispatch_queue_t entryStoreUpdateQ = dispatch_queue_create("com.nexusapp.AccountManager", NULL);
    dispatch_async(entryStoreUpdateQ, ^{
        // Clear the local data store
        DataStore *dataStore = [[DataStore alloc] init];
        [dataStore clearAllOfflineItems];
    });

    // Remove the keychain items
    DLog(@"----> Reset keychain...");
    [self.keyChainItem resetKeychainItem];

    DLog(@"----> Keychain information - login:[%@] pass:[%@] ",
            [self.keyChainItem objectForKey:(__bridge id)kSecAttrAccount],
            [self.keyChainItem objectForKey:(__bridge id)kSecValueData]);

    
    // Clear the stored account information
    DLog(@"----> Clear user account...");
    [self clearUserAccount];

    // Reset the Last Sync Time
    DLog(@"----> Reset last sync time...");
    [[SyncDownService instance] resetLastSyncTime];
    
    // Remove all preferences
    DLog(@"----> Remove preferences...");
    [UserPrefUtil clearAll];

    // Clear the cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookieJar = [storage cookies];
    
    for (NSHTTPCookie *cookie in cookieJar) {
        [storage deleteCookie:cookie];
    }
}

- (Account*)createAccount:(Account*)acct {
    if (self.acctService == nil) {
        self.acctService = [[AccountService alloc] init];
    }
    
    _currentLoginAcct = [self.acctService createAccount:acct];
    
    if (_currentLoginAcct.userId != -1) {
        [self saveUserAccount:_currentLoginAcct];
    }
    
    return self.currentLoginAcct;
}


- (NSString*)getSessionId {
    if (_currentLoginAcct == nil) {
        _currentLoginAcct = [self getCurrentLoginAcct];
    }

    if (_currentLoginAcct.sessionId.length == 0) {
        DLog(@"Login to get the session id using the stored information.");

        if ([self loginWithStoredInfo]) {
            return _currentLoginAcct.sessionId;
        } else {
            return nil;
        }

    } else {
        return _currentLoginAcct.sessionId;
    }
}

- (Account*)getCurrentLoginAcct {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObj = [defaults objectForKey:@"ACCOUNT"];
 
    _currentLoginAcct = (Account*)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObj];
    
    if (_currentLoginAcct == nil) {
        _currentLoginAcct = [[Account alloc] init];
    }

    return _currentLoginAcct;
}


- (void)saveUserAccount:(Account*)acct {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObj = [NSKeyedArchiver archivedDataWithRootObject:acct];
    [defaults setObject:encodedObj forKey:@"ACCOUNT"];
    [defaults synchronize];
}


- (void)clearUserAccount {
    DLog(@"Remove stored account information.");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:@"ACCOUNT"];
    [defaults synchronize];
}


- (NSString*)getUUID {
    NSString *uuid = [self getUserPrefValue:NP_UUID];
    
    if ([NSString isBlank:uuid]) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef aString = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        uuid = (__bridge NSString*)aString;
        DLog(@"Created new UUID and stored. %@", uuid);
        [self saveUserPrefValue:NP_UUID value:uuid];
        
        CFRelease(aString);
    }
    
    return uuid;
}

- (void)saveUserPrefValue:(NSString*)key value:(id)value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
}

- (id)getUserPrefValue:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    
    if (value == nil) {
        return @"";
    }
    return value;
}


- (void)deleteDatabase {
    NSError *error;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = nil;

    url = [[fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"ImageCache"];

    NSString *imageCachePath = [url path];
    NSArray *imageCachedFiles = [fileManager contentsOfDirectoryAtPath:imageCachePath error:&error];

    for (NSString *file in imageCachedFiles) {
        NSString *filePath = [imageCachePath stringByAppendingPathComponent:file];
        BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
        if (fileDeleted) {
            DLog(@"%@ is deleted...", filePath);
        } else {
            DLog(@"%@ cannot be deleted...Error:%@", filePath, error);
        }

    }

    //Clean up the inbox, the received "Open in" files.
    url = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"Inbox"];

    NSString *inboxPath = [url path];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:inboxPath error:&error];

    for (NSString *file in files) {
        NSString *filePath = [inboxPath stringByAppendingPathComponent:file];
        BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
        if (fileDeleted) {
            DLog(@"%@ is deleted...", filePath);
        } else {
            DLog(@"%@ cannot be deleted...Error:%@", filePath, error);
        }
        
    }
}

@end
