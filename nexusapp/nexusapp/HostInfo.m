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
@property AccountManager *acctManager;
@end

@implementation HostInfo

@synthesize appEnv, isOnline;


- (id)init
{
    self = [super init];
    self.appEnv = NP_ENV;
    self.isOnline = YES;
    self.acctManager = [AccountManager instance];

    return self;
}

- (NSString*)getApiUrl
{
    // We are testing sandbox environment
    if ([self.appEnv hasPrefix:@"lab"]) {
        return [NSString stringWithFormat:@"http://lab.nexuspad.com/api"];

    } else {
        return [NSString stringWithFormat:@"https://davinci.nexuspad.com/api"];
        
//        NSString *padHost = [[self.acctManager getCurrentLoginAcct] padHost];
//        
//        // Using prod
//        if (![NSString isBlank:padHost]) {
//            // For Beta release users
//            NSString *apiHost = [NSString stringWithFormat:@"%@2", padHost];
//            return [NSString stringWithFormat:@"http://%@.nexuspad.com", apiHost];
//            
//        } else {
//            
//            // The padhost is blank. There can be a few scenarios:
//            // 1. The user has not logged in yet - in this case, if we are testing, we need to manually insert it, but not to update self.padHost here.
//            // 2. The user's padhost is blank (intentionally)
//            if ([NSString isBlank:TEST_PAD_HOST]) {
//                return [NSString stringWithFormat:@"https://nexuspad.com/api"];
//                
//            } else {
//                return [NSString stringWithFormat:@"http://%@.nexuspad.com/api", TEST_PAD_HOST];
//            }
//        }
//        
//        return [NSString stringWithFormat:@"https://nexuspad.com/api"];
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
