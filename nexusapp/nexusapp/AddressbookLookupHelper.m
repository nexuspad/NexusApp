//
//  AddressbookLookupUtil.m
//  NexusAppCore
//
//  Created by Ren Liu on 12/7/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "AddressbookLookupHelper.h"
#import "AddressbookService.h"

@interface AddressbookLookupHelper ()
@property (nonatomic, strong) NSMutableDictionary *addressbookKeyMaps;
@end

@implementation AddressbookLookupHelper

- (id)init {
    self = [super init];
    
    self.addressbookKeyMaps = [[NSMutableDictionary alloc] init];
    
    NSArray *personArr = [[AddressbookService instance] getAddressbook];
    
    for (NPPerson *p in personArr) {
        if (p.npUserId > 0) {
            [self.addressbookKeyMaps setObject:p forKey:[@(p.npUserId) stringValue]];
            [self.addressbookKeyMaps setObject:p forKey:[p getEmail]];
        }
    }

    return self;
}

- (NPPerson*)getUser:(NSString*)userIdOrEmail {
    return [self.addressbookKeyMaps objectForKey:userIdOrEmail];
}

@end
