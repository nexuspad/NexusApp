//
//  AddressbookLookupUtil.h
//  NexusAppCore
//
//  Created by Ren Liu on 12/7/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPPerson.h"

@interface AddressbookLookupHelper : NSObject

- (NPPerson*)getUser:(NSString*)userIdOrEmail;

@end
