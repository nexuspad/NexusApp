//
//  AccessEntitlement.m
//  nexuspad
//
//  Created by Ren Liu on 9/4/12.
//
//

#import "AccessEntitlement.h"
#import "AccountManager.h"
#import "Constants.h"

@implementation AccessEntitlement

@synthesize owner = _owner;
@synthesize viewer = _viewer;

- (id)init {
    self = [super init];
    _owner = [[NPUser alloc] init];
    _viewer = [[NPUser alloc] init];
    
    return self;
}

- (id)initWithOwnerAndViewer:(NPUser*)theOwner theViewer:(NPUser*)theViewer
{
    self = [self init];
    self.owner = [theOwner copy];
    self.viewer = [theViewer copy];
    
    self.read = NO;
    self.write = NO;
    
    if (self.owner.userId == self.viewer.userId) {
        self.read = YES;
        self.write = YES;
    }
    
    return self;
}

- (id)initWithDictInfo:(NSDictionary*)dictInfo
{
    self = [self init];
    
    if ([dictInfo valueForKey:OWNER_ID]) {
        self.owner = [[NPUser alloc] init];
        self.owner.userId = [[dictInfo valueForKey:OWNER_ID] intValue];
    }
  
    if ([dictInfo valueForKey:VIEWER_ID]) {
        self.viewer = [[NPUser alloc] init];
        self.viewer.userId = [[dictInfo valueForKey:VIEWER_ID] intValue];
    }
    
    if ([dictInfo valueForKey:ACCESS_INFO_READ]) {
        int read = [[dictInfo valueForKey:ACCESS_INFO_READ] intValue];
        if (read) {
            self.read = YES;
        } else {
            self.read = NO;
        }
    }
    
    if ([dictInfo valueForKey:ACCESS_INFO_WRITE]) {
        int write = [[dictInfo valueForKey:ACCESS_INFO_WRITE] intValue];
        if (write) {
            self.write = YES;
        } else {
            self.write = NO;
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AccessEntitlement *newAccessInfo = [[[self class] allocWithZone:zone] init];
    newAccessInfo.owner = [self.owner copy];
    newAccessInfo.viewer = [self.viewer copy];
    newAccessInfo.read = self.read;
    newAccessInfo.write = self.write;
    
    return newAccessInfo;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"Access info: owner:%i viewer:%i read:%d write:%d", self.owner.userId, self.viewer.userId, self.read, self.write];
}

- (BOOL)iAmOwner {
    if (self.owner.userId == [AccessEntitlement accountOwner].userId) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)iCanWrite {
    if ([self iAmOwner]) {
        return YES;
    } else {
        if (self.write) {
            return YES;
        }
    }
    return NO;
}

+ (NPUser*)accountOwner {
    return [[AccountManager instance] currentLoginAcct];
}

@end
