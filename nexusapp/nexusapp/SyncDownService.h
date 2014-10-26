//
//  SyncDownService.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/26/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"

@interface SyncDownService : NPWebApiService

+ (SyncDownService*)instance;

- (void)start;
- (void)stop;

- (double)getLastSyncTime;
- (void)resetLastSyncTime;

@end
