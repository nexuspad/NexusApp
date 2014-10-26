//
//  ShareToUser.h
//  NexusAppCore
//
//  Created by Ren Liu on 11/27/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPUser.h"

@interface AccessPermission : NSObject

@property (nonatomic, strong) NPUser *accessor;

@property BOOL read;
@property BOOL write;

- (void)setAccessor:(int)userId email:(NSString*)email;
- (NSDictionary*)toDictionary;

- (NSString*)permissionCode;

- (BOOL)hasSameAccessor:(AccessPermission*)otherAccessPermission;

- (NSString*)getSortKey;

@end
