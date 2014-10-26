//
//  DataStoreUtil.m
//  NexusAppCore
//
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "DataStore.h"

#import "Constants.h"
#import "NPManagedDocument.h"
#import "DSEntry.h"
#import "DSFolder.h"
#import "NSString+NPStringUtil.h"

static NPManagedDocument *npManagedDocument;
static BOOL openingDocument;

@implementation DataStore

+ (NPManagedDocument*)getNPManagedDocument {
    if (npManagedDocument == nil) {
        [DataStore initNPManagedDocument];
    }
    return npManagedDocument;
}

+ (BOOL)storeIsBeingOpened {
    return openingDocument;
}

+ (void)initNPManagedDocument {
    if (npManagedDocument == nil) {
        DLog(@"Initializing data store...");
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"NexusPad_Database"];
        
        /*
         * Based on the version number, decide whether to blow up the existing database
         */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *appVersion = [defaults objectForKey:APP_VERSION];
        if (appVersion == nil || ![appVersion isEqualToString:CURRENT_VERSION]) {
            DLog(@"Nuke the existing core data DB because it's dated...");
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            [defaults setValue:CURRENT_VERSION forKey:APP_VERSION];
            
            // Reset the last sync time because we want a full sync of data
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:0 forKey:@"LastSyncTime"];
            [defaults synchronize];

        } else {
            DLog(@"App version is %@. We are fine.", CURRENT_VERSION);
        }
        
        npManagedDocument = [[NPManagedDocument alloc] initWithFileURL:url];

        if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [npManagedDocument saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                if (!success) {
                    DLog(@"Error creating database file at: %@", url);
                }
                DLog(@"Store file does not exist, create it at: %@", url);
            }];

        } else {
             DLog(@"Store file is located at: %@", url);
        }
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                 nil];
        
        npManagedDocument.persistentStoreOptions = options;        
    }
    
    // Try to open the data store here.
    if (npManagedDocument.documentState != UIDocumentStateNormal && openingDocument == NO) {
        DLog(@"NSManagedDocument state: %li, try to open it ", (long)npManagedDocument.documentState);
        openingDocument = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (npManagedDocument.documentState == UIDocumentStateClosed) {
                [npManagedDocument openWithCompletionHandler:^(BOOL success) {
                    openingDocument = NO;
                    DLog(@"NSManagedDocument for core data store is opened.");
                }];
            }
        });
    }
    
}


- (id)init {
    self = [super init];
    if (self) {
        [DataStore initNPManagedDocument];
    }
    
    return self;
}


- (NPManagedDocument*)getNPManagedDocInstance {
    if (npManagedDocument == nil) {
        [DataStore initNPManagedDocument];
    }
    return npManagedDocument;
}


- (void)clearAllOfflineItems {
    [self getNPManagedDocInstance];
    
    DLog(@"---- !!!! ----> Remove core data DSEntry and DSFolder records.");
    
    if (npManagedDocument.documentState == UIDocumentStateNormal) {
        [self removeAllRecords];
        
    } else if ([DataStore storeIsBeingOpened] == NO) {
        if (npManagedDocument.documentState == UIDocumentStateClosed) {
            [npManagedDocument openWithCompletionHandler:^(BOOL success) {
                if (!success) {
                    DLog(@"DataStore: clearAll failed to open data store db");
                }
                [self removeAllRecords];
            }];
            
        }
    }
}

- (void)removeAllRecords {
    [npManagedDocument.managedObjectContext performBlock:^{
        // Remove offline entry
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
        [request setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError *error = nil;
        NSArray *matches = [npManagedDocument.managedObjectContext executeFetchRequest:request error:&error];
        for (DSEntry *item in matches) {
            [npManagedDocument.managedObjectContext deleteObject:item];
            //DLog(@"Remove offline entry record: %@", item);
        }

        [npManagedDocument.managedObjectContext save:&error];
        
        // Remove offline folders
        request = [NSFetchRequest fetchRequestWithEntityName:@"DSFolder"];
        [request setIncludesPropertyValues:NO];

        matches = [npManagedDocument.managedObjectContext executeFetchRequest:request error:&error];
        for (DSFolder *item in matches) {
            [npManagedDocument.managedObjectContext deleteObject:item];
            //DLog(@"Remove offline folder record: %@", item);
        }

        [npManagedDocument.managedObjectContext save:&error];
    }];
}

@end
