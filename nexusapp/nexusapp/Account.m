//
//  Account.m
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Account.h"
#import "HostInfo.h"

@implementation Account

@synthesize sessionId = _sessionId;
@synthesize password = _password;
@synthesize preference = _preference;
@synthesize profileImageUrl = _profileImageUrl;


- (id)init {
    self = [super init];
    if (self) {
        return self;
    }
    return self;
}

- (id)initWithData:(NSDictionary*)dict {
    self = [super initWithData:dict];
    
    self.sessionId = [dict valueForKey:ACCT_SESSION_ID];

    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        // Decode properties
        self.sessionId = [decoder decodeObjectForKey:@"sessionId"];
        self.userId = [[decoder decodeObjectForKey:@"userId"] intValue];
        self.email = [decoder decodeObjectForKey:@"email"];
        self.userName = [decoder decodeObjectForKey:@"userName"];
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.padHost = [decoder decodeObjectForKey:@"padHost"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    // Encode properties
    [encoder encodeObject:self.sessionId forKey:@"sessionId"];
    [encoder encodeObject:[NSNumber numberWithInt:self.userId] forKey:@"userId"];
    [encoder encodeObject:self.email forKey:@"email"];
    [encoder encodeObject:self.userName forKey:@"userName"];
    [encoder encodeObject:self.firstName forKey:@"firstName"];
    [encoder encodeObject:self.lastName forKey:@"lastName"];
    [encoder encodeObject:self.padHost forKey:@"padHost"];
}

- (id)copyWithZone:(NSZone*)zone {
    Account *acct = [[Account alloc] init];
    
    if (self.sessionId != nil) {
        acct.sessionId = [self.sessionId copy];
    }

    acct.userId = self.userId;
    
    if (self.email.length > 0) {
        acct.email = [self.email copy];
    }
    
    if (self.userName.length > 0) {
        acct.userName = [self.userName copy];
    }
    
    if (self.firstName.length > 0) {
        acct.firstName = [self.firstName copy];
    }
    
    if (self.lastName.length > 0) {
        acct.lastName = [self.lastName copy];
    }
    
    if (self.padHost != nil) {
        acct.padHost = [self.padHost copy];
    }
    
    return acct;
}

- (BOOL)isLoggedIn
{
    if (self.sessionId != nil) 
        return YES;
    return NO;
}

- (NSString*)profileImageUrlForEditing {
    if (_profileImageUrl.length > 0) {
        return _profileImageUrl;
    }
    return nil;
}

- (void)setTimezoneStr:(NSString *)timezoneStr {
    if (_preference == nil) {
        _preference = [[UserPreference alloc] init];
    }
    _preference.timezoneStr = timezoneStr;
}

- (void)setLocaleStr:(NSString*)localeStr {
    if (_preference == nil) {
        _preference = [[UserPreference alloc] init];
    }
    _preference.localeStr = localeStr;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"userId:%i userName:%@ email:%@ sessionId:%@ padhost:%@",
                                        self.userId,
                                        self.userName,
                                        self.email==nil?@"":self.email,
                                        self.sessionId==nil?@"":self.sessionId,
                                        self.padHost==nil?@"":self.padHost];
}
@end
