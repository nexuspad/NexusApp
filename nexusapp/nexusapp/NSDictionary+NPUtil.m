//
//  NSDictionary+NPUtil.m
//  nexuspad
//
//  Created by Ren Liu on 8/28/12.
//
//

#import "NSDictionary+NPUtil.h"

@implementation NSDictionary (NPUtil)

// in case of [NSNull null] values a nil is returned ...
- (id)objectForKeyNotNull:(id)key {
    id object = [self objectForKey:key];
    
    if (object == [NSNull null])
        return nil;
    
    if ([object isKindOfClass:[NSString class]] && [object caseInsensitiveCompare:@"null"] == NSOrderedSame) {
        return nil;
    }

    return object;
}

@end
