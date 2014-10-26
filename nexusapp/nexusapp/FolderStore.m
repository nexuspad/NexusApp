//
//  FolderStore.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/9/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "FolderStore.h"
#import "EntryStore.h"
#import "DSEntryUtil.h"
#import "UserManager.h"

@interface FolderStore()
@property (nonatomic, strong) NSManagedObjectContext *localContext;
@end

@implementation FolderStore

@synthesize localContext = _localContext;

static FolderStore *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (FolderStore *)instance:(id)storeDelegate {
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
    } else {
        //DLog(@"_localContext already initialized. Use it.");
    }
    
    return _localContext;
}

#pragma mark - document layer operations

// This should be used in FolderService to populate FolderViewTree
- (void)findAllFolders:(int)moduleId {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];

    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Retrieve all folders in module %i", moduleId);
        NSArray *folders = [self dbSelectFolders:moduleId parentId:-1];                 // use -1 to get everything
        [self.storeDelegate foldersPulledFromStore:folders];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Retrieve all folders in module %i", moduleId);
                NSArray *folders = [self dbSelectFolders:moduleId parentId:-1];
                [self.storeDelegate foldersPulledFromStore:folders];
            }];
            
        }
    }
}


- (void)findUnsyncedFolders {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
        
    if (managedDoc.documentState == UIDocumentStateNormal) {
        DLog(@"Select unsynced folders in data store");
        NSArray *folders = [self dbSelectUnsyncedFolders];
        [self.storeDelegate foldersPulledFromStore:folders];

    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (managedDoc.documentState == UIDocumentStateClosed) {
            [managedDoc openWithCompletionHandler:^(BOOL success) {
                DLog(@"Select unsynced folders in data store");
                NSArray *folders = [self dbSelectUnsyncedFolders];
                [self.storeDelegate foldersPulledFromStore:folders];
            }];
        }
    }
}


- (void)storeFolder:(NPFolder*)folder {
    DLog(@"Store folder to data store: %@", [folder description]);
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        [managedDoc openWithCompletionHandler:^(BOOL success) {
            [self dbStoreFolder:folder inContext:managedDoc.managedObjectContext];
        }];

    } else if ([DataStore storeIsBeingOpened] == NO) {
        [managedDoc openWithCompletionHandler:^(BOOL success) {
            [self dbStoreFolder:folder inContext:managedDoc.managedObjectContext];
        }];
    }
}

// Called to store folder from entry list
- (void)storeFolders:(NSMutableArray*)folders {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    DLog(@"Save folders to data store.");
    
    if ([folders count] == 0) {
        return;
    }
    
    if (managedDoc.documentState == UIDocumentStateNormal) {
        [self dbUpdateFolders:folders];

    } else if ([DataStore storeIsBeingOpened] == NO) {
        [managedDoc openWithCompletionHandler:^(BOOL success) {
            [self dbUpdateFolders:folders];
        }];
    }
}

- (void)deleteFolder:(NPFolder*)folder {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];

    if (managedDoc.documentState == UIDocumentStateNormal) {
        [self dbDeleteFolder:folder];
        [DSEntryUtil dbDeleteEntriesInFolder:managedDoc moduleId:folder.moduleId folderId:folder.folderId];

    } else if ([DataStore storeIsBeingOpened] == NO) {
        [managedDoc openWithCompletionHandler:^(BOOL success) {
            [self dbDeleteFolder:folder];
            [DSEntryUtil dbDeleteEntriesInFolder:managedDoc moduleId:folder.moduleId folderId:folder.folderId];
        }];
    }
}


# pragma mark - database layer operations

- (void)dbUpdateFolders:(NSArray*)folders {
    [[self getLocalContext] performBlockAndWait:^{
        for (NPFolder *folder in folders) {
            if (folder.status == FOLDER_STATUS_DELETED) {
                [self dbDeleteFolder:folder];
            } else {
                folder.synced = YES;
                [self dbStoreFolder:folder inContext:[self getLocalContext]];
            }
        }
        
        [[self getLocalContext].parentContext performBlock:^{
            NSError *parentError = nil;
            [[self getLocalContext].parentContext save:&parentError];
        }];
    }];
}

- (void)dbUpdateFolder:(NPFolder*)folder {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    [self dbStoreFolder:folder inContext:managedDoc.managedObjectContext];
}

- (void)dbDeleteFolder:(NPFolder*)folder {
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    [managedDoc.managedObjectContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSFolder"];
        
        DLog(@"Delete persisted folder record: [%@]", [folder description]);
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = %d)",
                             folder.moduleId, folder.folderId];
        
        NSError *error = nil;
        NSArray *matches = [managedDoc.managedObjectContext executeFetchRequest:request error:&error];
        
        if (error != nil) {
            DLog(@"Error deleting folder:%@ ", [error description]);
        }
        
        // Delete matches.
        for (DSFolder *item in matches) {
            [managedDoc.managedObjectContext deleteObject:item];
        }
    }];
    
}

- (NSArray*)dbSelectFolders:(int)moduleId parentId:(int)parentId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSFolder"];
    
    DLog(@"Retrieve folders in: module: %d parent: %d", moduleId, parentId);
    
    if (parentId == -1) {       // Get everything.
        request.predicate = [NSPredicate predicateWithFormat:@"moduleId = %d", moduleId];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (parentId = %d) AND (status = 0)", moduleId, parentId];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folderName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error = nil;
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    NSArray *matches = [managedDoc.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *folders = [[NSMutableArray alloc] init];

    for (DSFolder *dsFolder in matches) {
        if (error == nil) {
            NPFolder *folder = [[NPFolder alloc] init];
            folder.moduleId = [dsFolder.moduleId intValue];
            folder.folderId = [dsFolder.folderId intValue];
            folder.parentId = [dsFolder.parentId intValue];
            folder.folderName = dsFolder.folderName;
            
            // Assign default access info to all local store items
            folder.accessInfo = [UserManager storeOwnerAccessInfo];
            
            [folders addObject:folder];
        }
    }
    
    return folders;
}


- (NSArray*)dbSelectUnsyncedFolders {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSFolder"];
    
    DLog(@"Retrieve unsynced folders");
    request.predicate = [NSPredicate predicateWithFormat:@"synced = 0"];
    
    NPManagedDocument *managedDoc = [self getNPManagedDocInstance];
    
    NSError *error = nil;
    NSArray *matches = [managedDoc.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *folders = [[NSMutableArray alloc] init];

    for (DSFolder *dsFolder in matches) {
        if (error == nil) {
            NPFolder *folder = [[NPFolder alloc] init];
            folder.moduleId = [dsFolder.moduleId intValue];
            folder.folderId = [dsFolder.folderId intValue];
            folder.parentId = [dsFolder.parentId intValue];
            folder.status = [dsFolder.status intValue];
            folder.folderName = [NSString stringWithFormat:@"%@", dsFolder.folderName];

            if (dsFolder.colorLabel != nil && dsFolder.colorLabel.length > 0) {
                folder.colorLabel = [NSString stringWithFormat:@"%@", dsFolder.colorLabel];
            }

            folder.accessInfo = [UserManager storeOwnerAccessInfo];

            [folders addObject:folder];
        }
    }
    
    return folders;
}


// Store folder to database. This is a private method.
- (void)dbStoreFolder:(NPFolder*)folder inContext:(NSManagedObjectContext*)inContext {
    DSFolder *dsFolder = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSFolder"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = %d)",
                         folder.moduleId, folder.folderId];
    NSError *error = nil;
    
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DLog(@"Error finding matching folder from data store: %@", error);
    }
    
    /*
     * Try to make sure the tmp folder record is updated by matching the parent id and name.
     */
    if ([matches count] == 0) {
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = -1) AND (parentId = %d) AND (folderName = %@)",
                             folder.moduleId, folder.parentId, folder.folderName];

        matches = [inContext executeFetchRequest:request error:&error];
    }

    if (error != nil) {
        DLog(@"Error finding matching folder from data store: %@", error);
    }

    if (!matches || [matches count] == 0 || [matches count] > 1) {
        if ([matches count] > 1) {                                      // This really shoudn't happen
            for (DSFolder *item in matches) {
                [inContext deleteObject:item];
            }
        }
        dsFolder = [NSEntityDescription insertNewObjectForEntityForName:@"DSFolder" inManagedObjectContext:inContext];
        
    } else if ([matches count] == 1) {
        dsFolder = [matches lastObject];
    }
    
    dsFolder.status = [NSNumber numberWithInt:folder.status];
    dsFolder.synced = [NSNumber numberWithBool:folder.synced];
    
    dsFolder.moduleId = [NSNumber numberWithInt:folder.moduleId];
    dsFolder.folderId = [NSNumber numberWithInt:folder.folderId];
    dsFolder.parentId = [NSNumber numberWithInt:folder.parentId];
    dsFolder.folderName = [folder.folderName copy];
    dsFolder.ownerId = [NSNumber numberWithInt:folder.accessInfo.owner.userId];
    dsFolder.lastModified = [[NSDate alloc] init];
    
    if (folder.colorLabel != nil && folder.colorLabel.length > 0) {
        dsFolder.colorLabel = [NSString stringWithString:folder.colorLabel];
    }
    
    [inContext save:&error];
    
    if (error != nil) {
        DLog(@"Store key %@ to core data error:%@ ", [folder description], [error description]);
    } else {
        //DLog(@"DB save Folder %@ mod time:%@ ", [folder description], [dsFolder.lastModified description]);
    }
}

@end
