//
//  EntryStore.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "DataStore.h"
#import "DSEntry.h"
#import "EntryList.h"
#import "NPEntry.h"
#import "NPJournal.h"

@protocol EntryStoreDelegate <NSObject>
@optional
- (void)entryListPulledFromStore:(EntryList*)entryList;
- (void)entryDetailPulledFromStore:(NPEntry*)storedEntry;
@end

@interface EntryStore : DataStore

@property (nonatomic, weak) id<EntryStoreDelegate> storeDelegate;

+ (id)instance:(id)storeDelegate;

// public interfaces
- (void)storeEntriesAndFolders:(EntryList*)entryList;
- (void)storeEntry:(NPEntry *)entry;                        // Store an entry to data store
- (void)syncEntry:(NPEntry *)entry;                         // Store an entry AND clean up the tmp record. This is called when an update
                                                            // Web service call returns successful
- (void)deleteEntry:(NPEntry *)entry;

- (void)refreshEntries:(NSArray*)entries;                   // Refresh a bunch of entries in data store. This is called when update web service
                                                            // call returns a bunch of entries (such as updating recurring event).

- (void)getEntries:(EntryList*)entryList;
- (void)getEntriesWithDateFilter:(EntryList*)entryList;

- (void)getUnsyncedEntries;

- (NPEntry*)getEntry:(NPEntry*)entry;
- (NPJournal*)getJournal:(NSString*)createDateYmd;

- (NSString*)listStoreKeyForLogging:(EntryList*)entryList;

- (void)deleteTmpItems;

@end
