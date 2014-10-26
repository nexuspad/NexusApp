//
//  ShareToUser.m
//  NexusAppCore
//
//  Created by Ren Liu on 11/27/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "AccessPermission.h"

@implementation AccessPermission

@synthesize accessor = _accessor;

- (id)init {
    self = [super init];
    self.accessor = [[NPUser alloc] init];
    self.accessor.userId = -1;
    
    return self;
}

- (void)setAccessor:(int)userId email:(NSString*)email {
    _accessor = [[NPUser alloc] init];
    _accessor.userId = userId;
    _accessor.email = email;
}

- (NSString*)permissionCode {
    if (self.write) {
        return @"rw";
    } else if (self.read) {
        return @"r";
    } else {
        return @"";
    }
}

- (NSDictionary*)toDictionary {
    NSMutableDictionary *aDict = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    if (self.accessor.email != nil) {
        [aDict setObject:self.accessor.email forKey:SHARE_TO];
        
        if (self.accessor.userId > 0) {
            [aDict setObject:[NSNumber numberWithInt:self.accessor.userId] forKey:SHARE_TO];
        }
        
    } else {
        return nil;
    }
    
    if (!self.read && !self.write) {
        [aDict setObject:@"" forKey:SHARING_PERMISSION];
    } else {
        if (self.read) {
            [aDict setObject:@"1" forKey:SHARING_READ];
        }
        if (self.write) {
            [aDict setObject:@"1" forKey:SHARING_WRITE];
        }
    }
    
    return aDict;
}

- (BOOL)hasSameAccessor:(AccessPermission*)otherAccessPermission {
    if (_accessor.userId == otherAccessPermission.accessor.userId || [_accessor.email isEqualToString:otherAccessPermission.accessor.email]) {
        return YES;
    }
    
    return NO;
}

- (NSString*)getSortKey {
    NSString *sortKey = [_accessor getDisplayName];
    if (sortKey == nil) {
        sortKey = _accessor.email;
    }
    
    return sortKey;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"accessor:%d %@ read:%d, write:%d", self.accessor.userId, self.accessor.email, self.read, self.write];
}

@end
