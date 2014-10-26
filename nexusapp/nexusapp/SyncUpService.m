//
//  NPSyncService.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/11/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPModule.h"
#import "SyncUpService.h"
#import "EntryActionResult.h"
#import "FolderActionResult.h"
#import "EntryService.h"
#import "FolderService.h"
#import "DateUtil.h"
#import "EntryFactory.h"
#import "EntryUriHelper.h"
#import "DSEntryUtil.h"

@implementation SyncUpService

static SyncUpService* theService = nil;
static NSTimer *syncTimer;

+ (SyncUpService*)instance {
    if (theService == nil) {
        theService = [[SyncUpService alloc] init];
        [syncTimer invalidate];
    }
    return theService;
}

- (id)init {
    self = [super init];
    return self;
}

- (void)start {
    [syncTimer invalidate];
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(processUpstream) userInfo:nil repeats:NO];
}

- (void)processUpstream {
    DLog(@"Start NP Syncing process...Send unsynced entries and folders upstream.");
    
    [syncTimer invalidate];

    /*
     * Both EntryStore and FolderStore need to open NSManagedDocument.
     * To avoid close succession calls on openWithCompletionHandler, we get the document ready here.
     */
    NPManagedDocument *storeDb = [DataStore getNPManagedDocument];
    if (storeDb.documentState == UIDocumentStateNormal) {
        [[EntryStore instance:self] getUnsyncedEntries];
        [[FolderStore instance:self] findUnsyncedFolders];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (storeDb.documentState == UIDocumentStateClosed) {
            [storeDb openWithCompletionHandler:^(BOOL success) {
                [[EntryStore instance:self] getUnsyncedEntries];
                [[FolderStore instance:self] findUnsyncedFolders];
            }];
        }
    }
}


// Send unsynced entries to upstream
- (void)entryListPulledFromStore:(EntryList *)entryList {
    DLog(@"Found %li entries need to be synced upstream.", (long)[entryList.entries count]);

    for (NPEntry *entry in entryList.entries) {
        NPEntry *moduleEntryObj = [EntryFactory moduleObject:entry];
        
        // Some self sanity check
        if (![NPEntry validate:moduleEntryObj]) {
            DLog(@"SyncUpService: invalid record. Delete it. %@", [moduleEntryObj description]);
            [DSEntryUtil dbDeleteEntry:[DataStore getNPManagedDocument] entry:moduleEntryObj];
            continue;
        }

        NSString *urlStr = [EntryUriHelper entryBaseUrl:moduleEntryObj];

        if (moduleEntryObj.status == ENTRY_STATUS_DELETED) {
            if ([entry isNewEntry]) {                           // Just delete the tmp record from local data store
                [[EntryStore instance:nil] deleteEntry:entry];

            } else {
                [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
                    if (success) {
                        NSError *error = nil;
                        
                        NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                                     options:NSJSONReadingMutableLeaves error:&error];
                        
                        ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                        
                        if (result.success) {
                            // Update entry with update action response
                            if ([result isEntryActionResponse]) {
                                EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                                if (entryActionResult.success) {
                                    if ([entryActionResult.name isEqualToString:ACTION_DELETE_ENTRY]) {
                                        if ([entryActionResult.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                                            [[EntryStore instance:nil] refreshEntries:entryActionResult.entries];
                                        } else {
                                            [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                                        }
                                    }
                                }
                            }
                            
                        } else {
                            if ([result isEntryActionResponse]) {
                                EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                                
                                if (result.code == ENTRY_NOT_FOUND) {           // Remove the local copy
                                    DLog(@"Entry not found on the server so delete it: %@", entryActionResult.entry.entryId);
                                    [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                                }
                            }
                        }
                    }
                }];
            }

        } else {
            [self doPost:urlStr parameters:[moduleEntryObj buildParamMap]
              completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData)
            {
                if (success) {
                    NSError *error = nil;
                    
                    NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                                 options:NSJSONReadingMutableLeaves error:&error];
                    
                    ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                    
                    if (result.success) {
                        // Update entry with update action response
                        if ([result isEntryActionResponse]) {
                            EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                            if (entryActionResult.success) {
                                if ([entryActionResult.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                                    [[EntryStore instance:nil] refreshEntries:entryActionResult.entries];
                                } else {
                                    entryActionResult.entry.synced = YES;
                                    // Note that syncEntry is called here.
                                    [[EntryStore instance:nil] syncEntry:entryActionResult.entry];
                                }
                            }
                        }

                    } else {
                        if ([result isEntryActionResponse]) {
                            EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                            
                            if (result.code == ENTRY_NOT_FOUND) {           // Remove the local copy
                                DLog(@"Entry not found on the server so delete it: %@", entryActionResult.entry.entryId);
                                [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                            }
                        }
                    }
                }
            }];
        }
    }
}


// Send unsynced folders to upstream
- (void)foldersPulledFromStore:(NSArray *)folders {
    DLog(@"Found %li folders need to be synced upstream.", (long)[folders count]);
    FolderService *folderService = [[FolderService alloc] init];
    folderService.serviceDelegate = self;

    for (NPFolder *folder in folders) {
        NSString *urlStr = [NPWebApiService appendOwnerParam:[NSString stringWithFormat:@"%@?folder_id=%i",
                                                              [self folderBaseUrl:folder.moduleId],
                                                              folder.folderId]
                                                     ownerId:folder.accessInfo.owner.userId];

        if (folder.status == ENTRY_STATUS_DELETED) {
            [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
                if (success) {
                    NSError *error = nil;
                    
                    NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                                 options:NSJSONReadingMutableLeaves error:&error];
                    
                    ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                    
                    if (result.success) {
                        FolderActionResult *folderActionResult = [[FolderActionResult alloc] initWithData:result.body];
                        if (folderActionResult.success) {
                            if ([folderActionResult.name isEqualToString:ACTION_DELETE_FOLDER]) {
                                [[FolderStore instance:nil] deleteFolder:folderActionResult.folder];
                            }
                        }
                    }
                }
            }];

        } else {
            [self doPost:urlStr parameters:[folder buildParamMap] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
                if (success) {
                    NSError *error = nil;
                    
                    NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                                 options:NSJSONReadingMutableLeaves error:&error];
                    
                    ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                    
                    if (result.success) {
                        FolderActionResult *folderActionResult = [[FolderActionResult alloc] initWithData:result.body];
                        if (folderActionResult.success) {
                            folderActionResult.folder.synced = YES;
                            [[FolderStore instance:nil] storeFolder:folderActionResult.folder];
                        }
                    }
                }
            }];
        }
    }
}

#pragma mark - NPDataServiceDelegate

- (void)updateServiceResult:(id)serviceResult {
}

- (void)serviceError:(id)serviceResult {
}


- (NSString*)folderBaseUrl:(int)moduleId {
    if (moduleId == CALENDAR_MODULE) {
        return [NSString stringWithFormat:@"%@/calendar/calendar", [[HostInfo current] getApiUrl]];
    } else {
        return [NSString stringWithFormat:@"%@/%@/folder", [[HostInfo current] getApiUrl], [NPModule getModuleCode:moduleId]];
    }
}

@end
