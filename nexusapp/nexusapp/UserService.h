//
//  UserService.h
//  NexusAppCore
//
//  Created by Ren Liu on 1/6/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"
#import "NPUser.h"

@interface UserService : NPWebApiService

@property (nonatomic, weak) id<NPDataServiceDelegate> serviceDelegate;

- (void)getSharers:(int)moduleId
        completion:(void (^)(NSArray *sharers))completion;

@end
