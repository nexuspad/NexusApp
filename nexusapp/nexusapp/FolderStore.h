//
//  FolderStore.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "DataStore.h"
#import "DSFolder.h"
#import "NPFolder.h"

@protocol FolderStoreDelegate <NSObject>
- (void)foldersPulledFromStore:(NSArray*)folders;
@end

@interface FolderStore : DataStore

@property (nonatomic, weak) id<FolderStoreDelegate> storeDelegate;

+ (id)instance:(id)storeDelegate;

- (void)findAllFolders:(int)moduleId;
- (void)findUnsyncedFolders;

- (void)storeFolder:(NPFolder*)folder;
- (void)storeFolders:(NSMutableArray*)folders;

- (void)deleteFolder:(NPFolder*)folder;

// Used in EntryStore
- (NSMutableArray*)dbSelectFolders:(int)moduleId parentId:(int)parentId;
- (void)dbUpdateFolders:(NSArray*)folders;

@end
