//
//  HostInfo.m
//  nexuspad
//
//  Created by Ren Liu on 9/27/12.
//
//

#import "HostInfo.h"
#import "Constants.h"
#import "NSString+NPStringUtil.h"
#import "AccountManager.h"


static HostInfo *currentHostInfo;

@interface HostInfo ()
@property NSString *protocol;
@property AccountManager *acctManager;
@end

@implementation HostInfo

@synthesize appEnv, isOnline;


- (id)init
{
    self = [super init];
    self.appEnv = NP_ENV;
    
    if ([self.appEnv hasPrefix:@"lab"]) {
        if (NP_SSL) {
            self.protocol = @"https";
        } else {
            self.protocol = @"http";
        }
    } else {
        if (NP_SSL) {
            self.protocol = @"https";
        } else {
            self.protocol = @"http";
        }
    }
    
    self.isOnline = YES;

    self.acctManager = [AccountManager instance];

    return self;
}

- (NSString*)getApiUrl
{
    // We are testing sandbox environment
    if ([self.appEnv hasPrefix:@"lab"]) {
        NSString *apiHost = [NSString stringWithFormat:@"%@2", self.appEnv];
        return [NSString stringWithFormat:@"%@://api-%@.nexuspad.com", self.protocol, apiHost];

    } else {
        NSString *padHost = [[self.acctManager getCurrentLoginAcct] padHost];
        
        // Using prod
        if (![NSString isBlank:padHost]) {
            NSString *apiHost = [NSString stringWithFormat:@"%@2", padHost];
            return [NSString stringWithFormat:@"%@://api-%@.nexuspad.com", self.protocol, apiHost];
            
        } else {
            
            // The padhost is blank. There can be a few scenarios:
            // 1. The user has not logged in yet - in this case, if we are testing, we need to manually insert it, but not to update self.padHost here.
            // 2. The user's padhost is blank (intentionally)
            if ([NSString isBlank:TEST_PAD_HOST]) {
                return [NSString stringWithFormat:@"%@://api2.nexuspad.com", self.protocol];
                
            } else {
                return [NSString stringWithFormat:@"%@://api-%@.nexuspad.com", self.protocol, TEST_PAD_HOST];
            }
        }
        
        return [NSString stringWithFormat:@"%@://api2.nexuspad.com", self.protocol];
    }
}

- (NSString*)getHostUrl
{
    NSString *padHost = [[self.acctManager getCurrentLoginAcct] padHost];
    
    if (![NSString isBlank:self.appEnv] && ![self.appEnv isEqualToString:@"prod"]) {
        return [NSString stringWithFormat:@"%@://%@.nexuspad.com", @"http", self.appEnv];
        
    } else if (![NSString isBlank:padHost]) {
        return [NSString stringWithFormat:@"%@://%@.nexuspad.com", @"http", padHost];
    }
    
    return [NSString stringWithFormat:@"%@://nexuspad.com", @"http"];
}

- (NSString*)description
{
    NSString *padHost = [[self.acctManager getCurrentLoginAcct] padHost];
    return [NSString stringWithFormat:@"Host info: %@ %@ ", padHost, [self getApiUrl]];
}

+ (HostInfo*)current
{
    if (currentHostInfo == nil) {
        currentHostInfo = [[HostInfo alloc] init];
    }
    
    return currentHostInfo;
}

@end
