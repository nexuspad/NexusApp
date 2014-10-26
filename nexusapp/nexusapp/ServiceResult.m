//
//  ServiceResult.m
//  NexusAppCore
//
//  Created by Ren Liu on 12/26/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import "ServiceResult.h"
#import "NSDictionary+NPUtil.h"

@interface ServiceResult()
@property (nonatomic, strong) NSString *status;
@end

@implementation ServiceResult

@synthesize success = _success, code = _code, body = _body, status = _status, message = _message;

- (id)initWithData:(NSDictionary*)data {
    self = [super init];
    
    if (self) {
        _status = [data valueForKey:NP_RESPONSE_STATUS];
        _code = [[data valueForKey:NP_RESPONSE_CODE] intValue];
        _body = [data objectForKey:NP_RESPONSE_DATA];
        
        if ([data objectForKeyNotNull:NP_RESPONSE_MESSAGE]) {
            _message = [data valueForKey:NP_RESPONSE_MESSAGE];
        }
        
        if (_code == 200 || [_status isEqualToString:@"success"]) {
            _success = YES;

        } else {
            _success = NO;
        }
    }
    
    return self;
}

- (id)initWithCodeAndMessage:(int)code message:(NSString*)message {
    self = [super init];
    
    if (self) {
        _code = code;
        _message = [NSString stringWithString:message];
    }
    
    return self;
}

- (BOOL)isEntryListResponse {
    if ([_body objectForKey:LIST_ENTRIES] != nil) {
        return YES;
    }

    return NO;
}

- (BOOL)isFolderDetailResponse {
    if ([_body objectForKey:FOLDER] != nil) {
        return YES;
    }
    return NO;
}

- (BOOL)isFolderListResponse {
    if ([_body objectForKey:FOLDER_LIST] != nil) {
        return YES;
    }
    return NO;
}

- (BOOL)isEntryDetailResponse {
    if ([_body objectForKey:ENTRY] != nil) {
        return YES;
    }
    return NO;
}

- (BOOL)isEntryActionResponse {
    if (([_body objectForKey:ENTRY] != nil || [_body objectForKey:LIST_ENTRIES] != nil) && [_body objectForKey:ACTION_NAME] != nil) {
        return YES;
    }
    return NO;
}

- (BOOL)isFolderActionResponse {
    if ([_body objectForKey:FOLDER] != nil && [_body objectForKey:ACTION_NAME] != nil) {
        return YES;
    }
    return NO;    
}

- (NSString*)description
{
    if (self.success) {
        return [NSString stringWithFormat:@"Success. Code:%d Body:\n%@", self.code, self.body];
    } else {
        return [NSString stringWithFormat:@"Error. Code:%d Body:\n%@", self.code, self.body];
    }
}

@end
