//
//  AcctService.m
//  nexuspad
//
//  Created by Ren Liu on 5/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountService.h"
#import "AccountManager.h"

@interface AccountService()
@end

@implementation AccountService

// Login using username and password
- (Account*)login:(NSString*)userName password:(NSString*)password {
    NSString *urlAsString = [NSString stringWithFormat:@"%@/login", [self accountBaseUrl]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:userName, password, [NPWebApiService getUUID], nil]
                                                       forKeys:[NSArray arrayWithObjects:NP_ACCT_LOGIN, NP_ACCT_PASS, NP_UUID, nil]];
    
    NSData *data = [self postForm:urlAsString parameters:params];
    Account *acct = [[Account alloc] init];
    
    if (data != nil) {
        NSError *error = nil;
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        if (error != nil) {
            NSLog(@"Error logging in: %@", error);
            return nil;
        }
      
        if ([[result valueForKey:NP_RESPONSE_CODE] intValue] == NP_SERVICE_200) {
            // Get the message body
            NSDictionary *loginResult = [result objectForKey:NP_RESPONSE_DATA];
            
            if ([[loginResult valueForKey:ACCT_USER_ID] intValue] == -1) {                          // Login failed
                acct.userId = -1;
                acct.errorCode = [loginResult valueForKey:ACCT_LOGIN_FAIL_REASON];
                
            } else {
                acct = [[Account alloc] initWithData:loginResult];
            }
        }
        
        return acct;
        
    } else {
        return nil;
    }
}


- (Account*)createAccount:(Account*)newAcct {
    NSString *urlAsString = [NSString stringWithFormat:@"%@/register", [self accountBaseUrl]];

    NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newAcct.email,
                                                                                        newAcct.password,
                                                                                        newAcct.firstName,
                                                                                        newAcct.lastName,
                                                                                        newAcct.preference.timezoneStr,
                                                                                        [NPWebApiService getUUID],
                                                                                        nil]
                                                       forKeys:[NSArray arrayWithObjects:ACCT_USER_EMAIL,
                                                                                        NP_ACCT_PASS,
                                                                                        ACCT_FIRST_NAME,
                                                                                        ACCT_LAST_NAME,
                                                                                        @"timezone",
                                                                                        NP_UUID,
                                                                                        nil]];
    
    NSData *data = [self postForm:urlAsString parameters:params];
    Account *acct = [[Account alloc] init];
    
    if (data != nil) {
        NSError *error = nil;
        
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        if ([[result valueForKey:NP_RESPONSE_CODE] intValue] == NP_SERVICE_200) {
            // Get the message body
            NSDictionary *acctResult = [result objectForKey:NP_RESPONSE_DATA];
            DLog(@"%@", acctResult);
            
            if ([acctResult valueForKey:ACCT_USER_ID] == nil || [[acctResult valueForKey:ACCT_USER_ID] intValue] == -1) {
                acct.errorCode = [acctResult valueForKey:ACCT_REGISTER_FAIL_REASON];
            } else {
                acct = [[Account alloc] initWithData:acctResult];
            }
            
        } else {
            acct.errorCode = [result valueForKey:NP_RESPONSE_CODE];
        }
        
        return acct;
        
    } else {
        return nil;
    }
}

- (void)resetPassword:(NSString*)email {
    NSString *urlAsString = [NSString stringWithFormat:@"%@/resetpassword", [self accountBaseUrl]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:email, nil]
                                                       forKeys:[NSArray arrayWithObjects:ACCT_USER_EMAIL, nil]];
    
    [self postForm:urlAsString parameters:params];
}

// Use sendSynchronousRequest to post the login information
// This is used in posting login form and create account form
- (NSData*)postForm:(NSString *)urlAsString parameters:(NSDictionary*)parameters
{    
    NSURL *url = [NSURL URLWithString:urlAsString];
    
    DLog(@"AcctService post to URL: %@", url);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:8.0f];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSArray *params = [NPWebApiService toUrlParamArr:parameters];
    NSString *body = [params componentsJoinedByString:@"&"];
    
    [urlRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:&error];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (error != nil) {
        DLog(@"Error happened = %@", error);
        return nil;
    }
    
    return data;
}

- (void)getSettingsAndUsageInfo:(Account*)acct
{
    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@/account/preferences", [self accountBaseUrl]];
    
    [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        NSError *error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&error];
        
        if ([[result valueForKey:NP_RESPONSE_CODE] intValue] == NP_SERVICE_200) {
            
            // Get the message body
            NSDictionary *acctInfoResult = [result objectForKey:NP_RESPONSE_DATA];
            DLog(@"%@", acctInfoResult);
            
            if ([acctInfoResult objectForKey:NP_DATA_ERROR] == nil) {
                if ([acctInfoResult valueForKey:ACCT_SPACE_ALLOCATION] != nil) {
                    acct.spaceAllocation = [[acctInfoResult valueForKey:ACCT_SPACE_ALLOCATION] doubleValue];
                }
                
                if ([acctInfoResult valueForKey:ACCT_SPACE_USAGE] != nil) {
                    acct.spaceUsage = [[acctInfoResult valueForKey:ACCT_SPACE_USAGE] doubleValue];
                }
                
                if ([acctInfoResult objectForKey:ACCT_EXTERNAL_SERVICE] != nil) {
                    acct.externalService = [[UserExtService alloc] initWithServiceData:[acctInfoResult objectForKey:ACCT_EXTERNAL_SERVICE]];
                } else {
                    acct.externalService = [[UserExtService alloc] init];
                }
                
                if ([acctInfoResult objectForKey:ACCT_PROFILE_PHOTO_URL] != nil) {
                    acct.profileImageUrl = [acctInfoResult objectForKey:ACCT_PROFILE_PHOTO_URL];
                }
                
                [self.serviceDelegate updateServiceResult:acct];
                
            } else {
                
                // There is error
                NSString *errorMessage = [acctInfoResult objectForKey:NP_DATA_ERROR];
                NSArray *pieces = [errorMessage componentsSeparatedByString:@":"];
                
                NSString *code = [pieces objectAtIndex:0];
                NSString *message = nil;
                if ([pieces count] == 2) {
                    message = [pieces objectAtIndex:1];
                }
                
                ServiceResult *result = [[ServiceResult alloc] initWithCodeAndMessage:[code intValue] message:message];
                [self.serviceDelegate serviceError:result];
            }
        }
    }];
}

- (void)checkSpaceUsage:(NPUser*)user completion:(void (^)(BOOL spaceLeft))completion {
    NSString *urlStr = [NSString stringWithFormat:@"%@/servicecheck", [self accountBaseUrl]];
    
    urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:user.userId];

    [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            completion(result.success);
        }
    }];
}

- (void)turnOffExternalService:(NSString*)provider {
    NSString *urlStr;
    
    if ([provider isEqualToString:@"google"]) {
        urlStr = [NSString stringWithFormat:@"%@/account/external/google/service", [self accountBaseUrl]];
    }
    
    if ([NPService isServiceAvailable] && urlStr != nil) {
        self.responseData = [[NSMutableData alloc] init];

        [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success == YES) {
                // Do nothing here. The data store record is deleted in EntryService action response.
            }
        }];
    }
}


- (NSString*)accountBaseUrl {
    return [NSString stringWithFormat:@"%@/user", [[HostInfo current] getApiUrl]];
}

@end
