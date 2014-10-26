//
//  EntryStore.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryStore.h"
#import "EntryFactory.h"
#import "DateUtil.h"
#import "FolderStore.h"
#import "DSEntryUtil.h"

@interface EntryStore()
@property (nonatomic, strong) NSManagedObjectContext *localContext;
@end

@implementation EntryStore

@synthesize localContext = _localContext;

static EntryStore *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (EntryStore *)instance:(id)storeDelegate {
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    
    sharedInstance.storeDelegate = storeDelegate;
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    return self;
}

- (NSManagedObjectContext*)getLocalContext {
    if (_localContext == nil) {
        NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
        
        _localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _localContext.parentContext = managedDoc.managedObjectContext;
    }
    
    return _localContext;
}

/*
 * Get the entry list from offline store
 */
- (void)getEntries:(EntryList*)entryList {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    NSInteger startIndex = 0;
    if (entryList.pageId > 0) {
        startIndex = (entryList.pageId-1) * entryList.countPerPage;
    }

    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Select entry list in data store with key: %@", [self listStoreKeyForLogging:entryList]);
        
        EntryList *dbEntriesList = [DSEntryUtil dbSelectEntries:[self getNPManagedDocInstance]
                                                       moduleId:entryList.folder.moduleId
                                                     templateId:entryList.templateId
                                                       folderId:entryList.folder.folderId
                                                     startIndex:startIndex
                                                          count:entryList.countPerPage];
        
        entryList.entries = [NSMutableArray arrayWithArray:dbEntriesList.entries];
        entryList.totalCount = dbEntriesList.totalCount;
        
        FolderStore *folderStore = [FolderStore instance:nil];
        entryList.folder.subFolders = [folderStore dbSelectFolders:entryList.folder.moduleId parentId:entryList.folder.folderId];
        
        [self.storeDelegate entryListPulledFromStore:entryList];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Select entry list from data store with key: %@", [self listStoreKeyForLogging:entryList]);

                EntryList *dbEntriesList = [DSEntryUtil dbSelectEntries:[self getNPManagedDocInstance]
                                                               moduleId:entryList.folder.moduleId
                                                             templateId:entryList.templateId
                                                               folderId:entryList.folder.folderId
                                                             startIndex:startIndex
                                                                  count:entryList.countPerPage];

                entryList.entries = [NSMutableArray arrayWithArray:dbEntriesList.entries];
                entryList.totalCount = dbEntriesList.totalCount;

                FolderStore *folderStore = [FolderStore instance:nil];
                entryList.folder.subFolders = [folderStore dbSelectFolders:entryList.folder.moduleId parentId:entryList.folder.folderId];
                
                [self.storeDelegate entryListPulledFromStore:entryList];
            }];
        }
    }
}

- (void)getEntriesWithDateFilter:(EntryList*)entryList {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Select entry list in data store with key: %@", [self listStoreKeyForLogging:entryList]);
        entryList.entries = [DSEntryUtil dbSelectEntriesBetweenDates:[self getNPManagedDocInstance]
                                                            moduleId:entryList.folder.moduleId
                                                          templateId:entryList.templateId
                                                            folderId:entryList.folder.folderId
                                                            fromDate:entryList.startDate
                                                              toDate:entryList.endDate];

        [self.storeDelegate entryListPulledFromStore:entryList];

    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Select entry list in data store with key: %@", [self listStoreKeyForLogging:entryList]);
                entryList.entries = [DSEntryUtil dbSelectEntriesBetweenDates:[self getNPManagedDocInstance]
                                                                    moduleId:entryList.folder.moduleId
                                                                  templateId:entryList.templateId
                                                                    folderId:entryList.folder.folderId
                                                                    fromDate:entryList.startDate
                                                                      toDate:entryList.endDate];
                
                [self.storeDelegate entryListPulledFromStore:entryList];
            }];
        }
    }
}

- (void)getUnsyncedEntries {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    EntryList *entryList = [[EntryList alloc] init];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Select unsynced entries in data store");
        entryList.entries = [DSEntryUtil dbSelectUnsyncedEntries:[self getNPManagedDocInstance]];
        [self.storeDelegate entryListPulledFromStore:entryList];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Select unsynced entries in data store");
                entryList.entries = [DSEntryUtil dbSelectUnsyncedEntries:[self getNPManagedDocInstance]];
                [self.storeDelegate entryListPulledFromStore:entryList];
            }];
            
        }
    }

}

/**
 * Get the entry detail from offline store.
 */
- (NPEntry*)getEntry:(NPEntry*)entry {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Check entry detail in persistance store with key: %@", [entry description]);
        NPEntry *storedEntry = [DSEntryUtil dbSelectEntry:entry inContext:managedDoc.managedObjectContext];
        if (storedEntry != nil) {
            storedEntry.accessInfo = [entry.accessInfo copy];
        }

        [self.storeDelegate entryDetailPulledFromStore:storedEntry];
        
        return storedEntry;
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Check entry detail in persistance store with key: %@", [entry description]);
                NPEntry *storedEntry = [DSEntryUtil dbSelectEntry:entry inContext:managedDoc.managedObjectContext];
                if (storedEntry != nil) {
                    storedEntry.accessInfo = [entry.accessInfo copy];
                }
                [self.storeDelegate entryDetailPulledFromStore:storedEntry];
            }];
            
        }
    }
    
    return nil;
}


- (NPJournal*)getJournal:(NSString*)createDateYmd {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Get journal in date store for: %@", createDateYmd);
        NPEntry *storedEntry = [DSEntryUtil dbSelectJournalByKeyFilter:[self getNPManagedDocInstance] keyFilter:createDateYmd];
        return [NPJournal journalFromEntry:storedEntry];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Get journal in date store for: %@", createDateYmd);
                NPEntry *storedEntry = [DSEntryUtil dbSelectJournalByKeyFilter:[self getNPManagedDocInstance] keyFilter:createDateYmd];
                [self.storeDelegate entryDetailPulledFromStore:storedEntry];
            }];
            
        }
    }
    
    return nil;
}

/**
 * Store the list in offline store.
 * This handles both updated entry and deleted entry.
 * It also handles folders.
 *
 * It is used in:
 *
 * - entry list service response
 * - sync down response
 * - sync up response
 *
 */
- (void)storeEntriesAndFolders:(EntryList*)entryList {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    DLog(@"Save entries to data store.");
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        // offline entries
        [DSEntryUtil dbUpdateEntries:[self getLocalContext] entries:entryList.entries];
        // offline folders
        if ([entryList.folder.subFolders count] > 0) {
            FolderStore *folderStore = [FolderStore instance:nil];
            [folderStore dbUpdateFolders:[NSArray arrayWithArray:entryList.folder.subFolders]];
        }
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                // offline entries
                [DSEntryUtil dbUpdateEntries:[self getLocalContext] entries:entryList.entries];
                // offline folders
                if ([entryList.folder.subFolders count] > 0) {
                    FolderStore *folderStore = [FolderStore instance:nil];
                    [folderStore dbUpdateFolders:[NSArray arrayWithArray:entryList.folder.subFolders]];
                }
            }];
        }
    }
}


/**
 * This is ONLY called for individual entry update. NOT to be used to process a list of entries.
 */
- (void)storeEntry:(NPEntry *)entry {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    /*
     * This is probably unnecessary.
     * Make sure to have module specific object so buildParamMap produce correct data.
     */
    entry = [EntryFactory moduleObject:entry];
    
    if (entry != nil) {
        if (entry.entryId != nil) {
            DLog(@"Store entry to data store: %@", [entry description]);
        } else {
            DLog(@"Store entry to data store: no entry id.");
        }
        
        if (managedDoc.documentState == UIDocumentStateNormal) {
            [DSEntryUtil dbSaveEntry:entry inContext:managedDoc.managedObjectContext];

        } else if ([DataStore storeIsBeingOpened] == NO) {
            if (managedDoc.documentState == UIDocumentStateClosed) {
                [managedDoc openWithCompletionHandler:^(BOOL success) {
                    [DSEntryUtil dbSaveEntry:entry inContext:managedDoc.managedObjectContext];
                }];
            }
        }
    }
}


- (void)syncEntry:(NPEntry *)entry {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    /*
     * This is probably unnecessary.
     * Make sure to have module specific object so buildParamMap produce correct data.
     */
    entry = [EntryFactory moduleObject:entry];
    
    if (entry != nil) {
        if (entry.entryId != nil) {
            DLog(@"Store entry to data store: %@", [entry description]);
        } else {
            DLog(@"Store entry to data store: no entry id.");
        }
        
        if (managedDoc.documentState == UIDocumentStateNormal) {
            [DSEntryUtil dbSaveEntry:entry inContext:managedDoc.managedObjectContext];
            
            //
            // Make sure the tmp record is cleaned up
            // This is needed when storing an entry copy returned from webservice action result.
            // Workflow:
            // 1. store tmp entry (with tmp id) locally
            // 2. call webservice to update entry remotely
            // 3. webservice returns action result with entry copy (with "official" entry id)
            // 4. store returned copy locally
            // 5. delete tmp entry (with tmp id)
            //
            if (entry.syncId.length != 0) {
                NPEntry *tmpEntry = [entry copy];
                tmpEntry.entryId = entry.syncId;
                [DSEntryUtil dbDeleteEntry:tmpEntry inContext:managedDoc.managedObjectContext];
            }
            
        } else if ([DataStore storeIsBeingOpened] == NO) {
            if (managedDoc.documentState == UIDocumentStateClosed) {
                [managedDoc openWithCompletionHandler:^(BOOL success) {
                    [DSEntryUtil dbSaveEntry:entry inContext:managedDoc.managedObjectContext];
                    
                    // Make sure the tmp record is cleaned up
                    if (entry.syncId.length != 0) {
                        NPEntry *tmpEntry = [entry copy];
                        tmpEntry.entryId = entry.syncId;
                        [DSEntryUtil dbDeleteEntry:tmpEntry inContext:managedDoc.managedObjectContext];
                    }
                }];
            }
        }
    }
}


// Refresh a list of entries.
// First delete the existing ones, then add the updated entries.
- (void)refreshEntries:(NSArray*)entries {
    if (entries == nil || entries.count == 0) {
        DLog(@"Nothing to refresh...");
        return;
    }

    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    DLog(@"Refresh entries: save entries to data store.");
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        [DSEntryUtil dbRefreshEntries:[self getLocalContext] entries:entries];
        
        // Clean up - refer to storeEntry for more explanation
        for (NPEntry *entry in entries) {
            if (entry.syncId.length != 0) {
                NPEntry *tmpEntry = [entry copy];
                tmpEntry.entryId = entry.syncId;
                [DSEntryUtil dbDeleteEntry:tmpEntry inContext:managedDoc.managedObjectContext];
            }
        }
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                [DSEntryUtil dbRefreshEntries:[self getLocalContext] entries:entries];
                
                // Clean up
                for (NPEntry *entry in entries) {
                    if (entry.syncId.length != 0) {
                        NPEntry *tmpEntry = [entry copy];
                        tmpEntry.entryId = entry.syncId;
                        [DSEntryUtil dbDeleteEntry:tmpEntry inContext:managedDoc.managedObjectContext];
                    }
                }
            }];
        }
    }

}


- (void)deleteEntry:(NPEntry *)entry {
    NSLog(@"Delete entry from data store: %@", entry.entryId);
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        [DSEntryUtil dbDeleteEntry:managedDoc entry:entry];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        [managedDoc openWithCompletionHandler:^(BOOL success) {
            [DSEntryUtil dbDeleteEntry:managedDoc entry:entry];
        }];
    }
}

- (void)deleteTmpItems {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    [managedDoc.managedObjectContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
        
        DLog(@"Delete all tmp entries.");
        request.predicate = [NSPredicate predicateWithFormat:@"entryId beginswith[c] %@", @"_"];
        
        NSError *error = nil;
        NSArray *matches = [managedDoc.managedObjectContext executeFetchRequest:request error:&error];
        
        // Delete matches.
        for (DSEntry *item in matches) {
            [managedDoc.managedObjectContext deleteObject:item];
            DLog(@"Tmp entry deleted...");
        }
    }];
}

- (NSString*)listStoreKeyForLogging:(EntryList*)entryList {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    [keys addObject:[NSNumber numberWithInt:entryList.accessInfo.owner.userId]];
    [keys addObject:[NSNumber numberWithInt:entryList.folder.moduleId]];
    [keys addObject:[NSNumber numberWithInt:entryList.folder.folderId]];
    [keys addObject:[NSNumber numberWithInt:entryList.templateId]];
    [keys addObject:[NSNumber numberWithInteger:entryList.pageId]];
    
    if (![NSString isBlank:entryList.keyword]) {
        [keys addObject:entryList.keyword];
    }
    
    if (entryList.startDate != nil) {
        [keys addObject:[DateUtil convertToYYYYMMDD:entryList.startDate]];
    }
    if (entryList.endDate != nil) {
        [keys addObject:[DateUtil convertToYYYYMMDD:entryList.endDate]];
    }
    return [keys componentsJoinedByString:@"-"];
}

@end
