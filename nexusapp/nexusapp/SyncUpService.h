//
//  NPSyncService.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/11/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"
#import "EntryStore.h"
#import "FolderStore.h"

@interface SyncUpService : NPWebApiService <EntryStoreDelegate, FolderStoreDelegate, NPDataServiceDelegate>

+ (SyncUpService*)instance;

- (void)start;

@end
