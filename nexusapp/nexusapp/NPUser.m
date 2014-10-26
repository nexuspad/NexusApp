//
//  NPUser.m
//  nexuspad
//
//  Created by Ren Liu on 9/4/12.
//
//

#import "NPUser.h"
#import "NSDictionary+NPUtil.h"
#import "HostInfo.h"

@implementation NPUser

@synthesize email, userName, padHost, firstName, lastName, middleName, profileImageUrl = _profileImageUrl;

- (id)init {
    self = [super init];
    self.userId = 0;
    return self;
}

- (id)initWithUser:(NPUser*)user
{
    self = [super init];
    
    if (self) {
        self.userId = user.userId;
        self.email = user.email;
        self.userName = user.userName;
        
        self.firstName = user.firstName;
        self.lastName = user.lastName;
        self.middleName = user.middleName;
        self.profileImageUrl = user.profileImageUrl;
        
        self.padHost = user.padHost;
    }
    
    return self;
}

- (id)initWithData:(NSDictionary*)dict
{
    self = [self init];
    
    if (self) {
        self.userId = [[dict valueForKey:ACCT_USER_ID] intValue];

        self.userName = [dict valueForKey:ACCT_USER_NAME];        
        self.email = [dict valueForKey:ACCT_USER_EMAIL];
        
        if ([dict objectForKeyNotNull:ACCT_PAD_HOST]) {
            self.padHost = [dict valueForKey:ACCT_PAD_HOST];
        } else {
            self.padHost = @"";
        }
        
        if ([dict objectForKeyNotNull:ACCT_FIRST_NAME]) {
            self.firstName = [dict valueForKey:ACCT_FIRST_NAME];
        } else {
            self.firstName = @"";
        }
        
        if ([dict objectForKeyNotNull:ACCT_LAST_NAME]) {
            self.lastName = [dict valueForKey:ACCT_LAST_NAME];
        } else {
            self.lastName = @"";
        }
    }
    
    return self;
}

- (NSString*)getDisplayName {
    if (self.firstName.length > 0) {
        NSString *fName = [self.firstName capitalizedString];
        
        if (self.lastName.length > 0) {
            return [NSString stringWithFormat:@"%@ %@", fName, [self.lastName capitalizedString]];
        }
        
        return fName;
    }
    
    return self.userName;
}

- (NSString*)getProfileImageUrl {
    if (_profileImageUrl != nil)
        return _profileImageUrl;
    return [NSString stringWithFormat:@"%@/user/profile/%d/photo", [[HostInfo current] getApiUrl], self.userId];
}

- (id)copyWithZone:(NSZone*)zone
{
    NPUser *user = [[[self class] allocWithZone:zone] init];
    
    user.userId = self.userId;
    
    if (self.email != nil) {
        user.email = [self.email copyWithZone:zone];
    }
    
    if (self.userName != nil) {
        user.userName = [self.userName copyWithZone:zone];
    }
    
    if (self.firstName != nil) {
        user.firstName = [self.firstName copyWithZone:zone];
    }
    
    if (self.lastName != nil) {
        user.lastName = [self.lastName copyWithZone:zone];
    }
    
    if (self.middleName != nil) {
        user.middleName = [self.middleName copyWithZone:zone];
    }
    
    if (self.padHost != nil) {
        user.padHost = [self.padHost copyWithZone:zone];
    }
    
    return user;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"userId:%i userName:%@ email:%@ padhost:%@",
                                        self.userId,
                                        self.userName,
                                        self.email==nil?@"":self.email,
                                        self.padHost==nil?@"":self.padHost];
}

@end
