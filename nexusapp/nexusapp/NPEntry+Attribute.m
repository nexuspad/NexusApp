//
//  NPEntry+Attribute.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/5/14.
//  Copyright (c) 2014 Ren Liu. All rights reserved.
//

#import "NPEntry+Attribute.h"

@implementation NPEntry (Attribute)

- (BOOL)isPinned {
    NSString *attrib = [self getFeatureValue:ENTRY_PINNED];
    if (attrib != nil && ![attrib isEqualToString:@"false"] && ![attrib isEqualToString:@"0"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
