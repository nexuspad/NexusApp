//
//  EventService.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/2/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EventService.h"
#import "EntryActionResult.h"

@implementation EventService

- (id)init {
    self = [super init];
    return self;
}

- (void)getEventDetail:(NPEvent*)event {
    if ([NPService isServiceAvailable]) {
        self.responseData = [[NSMutableData alloc] init];

        [self doGet:[EntryUriHelper entryBaseUrl:event] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                /*
                 * Entry detail query from Web API.
                 */
                NSDictionary *entryDict = [result.body objectForKey:ENTRY];
                NPEntry *e = [NPEntry entryFromDictionary:entryDict defaultAccessInfo:self.accessInfo];
                
                if (![NSString isBlank:e.entryId]) {
                    // Update the data store
                    e.synced = YES;
                    [[EntryStore instance:nil] storeEntry:e];
                }
                
                [self.serviceDelegate updateServiceResult:e];
                
            } else {
                [[EntryStore instance:self] getEntry:event];
            }
        }];

    } else {
        [[EntryStore instance:self] getEntry:event];
    }
}


- (void)addOrUpdateEvent:(NPEvent*)event {
    event.modifiedTime = [[NSDate alloc] init];
    
    // Create a tmp entry Id for datastore, also it will be used as syncId
    if (event.entryId.length == 0) {
        event.entryId = [NSString stringWithFormat:@"_%@", [NSString genRandString:6]];
        
        // This is a new event and it's recurring, we need to set the option to ALL
        if ([event isRecurring]) {
            event.recurUpdateOption = ALL;
        }
    }

    // Save to data store
    event.synced = NO;
    
    // Notice we don't use event copy here to make sure the tmp Id (if created can be passed back).
    if ([event.accessInfo iAmOwner]) {
        [[EntryStore instance:nil] storeEntry:event];
    }
    
    // Save to Web API
    if ([NPService isServiceAvailable]) {
        self.responseData = [[NSMutableData alloc] init];
        
        NSString *urlStr = nil;
        
        if (![event isNewEntry]) {                                          // Update an event
            urlStr = [NSString stringWithFormat:@"%@?folder_id=%i",
                      [EntryUriHelper entryBaseUrl:event],
                      event.folder.folderId];
            
        } else {                                                            // New event
            urlStr = [NSString stringWithFormat:@"%@?folder_id=%i",
                      [EntryUriHelper entryBaseUrl:event],
                      event.folder.folderId];
        }
        
        [self doPost:urlStr parameters:[event buildParamMap] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success == YES) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    
                    if ([entryActionResult.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                        DLog(@"Update data store record upon successful action refresh entries response.");
                        
                        dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                        dispatch_async(entryStoreQ, ^{
                            // Make sure only store those owned by user
                            NSMutableArray *entriesStoreToLocal = [[NSMutableArray alloc] init];
                            for (NPEvent *evt in entryActionResult.entries) {
                                if ([evt.accessInfo iAmOwner]) {
                                    [entriesStoreToLocal addObject:evt];
                                }
                            }
                            if (entriesStoreToLocal.count > 0) {
                                [[EntryStore instance:nil] refreshEntries:entriesStoreToLocal];
                            }
                        });

                    } else {
                        // Only needs to sync with local database when I am the owner of the entry.
                        if ([entryActionResult.entry.accessInfo iAmOwner]) {
                            DLog(@"Update data store record upon successful update action response. entry Id:%@, sync Id:%@",
                                 entryActionResult.entry.entryId, entryActionResult.entry.syncId);
                            
                            entryActionResult.entry.synced = YES;

                            dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                            dispatch_async(entryStoreQ, ^{
                                // Note that syncEntry is called here
                                [[EntryStore instance:nil] syncEntry:entryActionResult.entry];
                            });
                        }                            
                    }
                    
                    [self.serviceDelegate updateServiceResult:entryActionResult];
                    
                } else {
                    
                }

            } else {
                // API call is not successful, update the service result delegate with the entry data in local store.
                EntryActionResult *actionResult = [[EntryActionResult alloc] init];
                actionResult.name = ACTION_UPDATE_ENTRY;
                actionResult.success = YES;
                actionResult.entry = event;
                [self.serviceDelegate updateServiceResult:actionResult];
            }
        }];
        
    } else {
        EntryActionResult *actionResult = [[EntryActionResult alloc] init];
        actionResult.name = ACTION_UPDATE_ENTRY;
        actionResult.success = YES;
        actionResult.entry = event;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}


- (void)deleteEvent:(NPEvent*)event {
    event.modifiedTime = [[NSDate alloc] init];
    
    // Save to data store, with "deleted" status. In case the device is offline, we can sync up to server again.
    event.status = ENTRY_STATUS_DELETED;
    event.synced = NO;
    [[EntryStore instance:nil] storeEntry:event];

    if ([NPService isServiceAvailable]) {
        self.responseData = [[NSMutableData alloc] init];
        NSString *urlStr = [NSString stringWithFormat:@"%@", [EntryUriHelper entryBaseUrl:event]];
        
        if (event.recurUpdateOption == ALL) {
            urlStr = [NPWebApiService appendParamToUrlString:urlStr paramName:@"recur_update" paramValue:@"ALL"];
        } else if (event.recurUpdateOption == FUTURE) {
            urlStr = [NPWebApiService appendParamToUrlString:urlStr paramName:@"recur_update" paramValue:@"FUTURE"];
        } else {
            urlStr = [NPWebApiService appendParamToUrlString:urlStr paramName:@"recur_update" paramValue:@"ONE"];
        }

        [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success == YES) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];

                    if ([entryActionResult.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                        DLog(@"Update data store record upon successful action refresh entries response.");
                        
                        dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                        dispatch_async(entryStoreQ, ^{
                            [[EntryStore instance:nil] refreshEntries:entryActionResult.entries];
                        });
                        
                    } else {
                        DLog(@"Delete data store record upon successful delete action response. entry Id:%@", entryActionResult.entry.entryId);
                        
                        dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                        dispatch_async(entryStoreQ, ^{
                            [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                        });
                    }
                    
                    [self.serviceDelegate updateServiceResult:entryActionResult];
                }
            }

        }];

    } else {
        EntryActionResult *actionResult = [[EntryActionResult alloc] init];
        actionResult.name = ACTION_DELETE_ENTRY;
        actionResult.success = YES;
        actionResult.entry = event;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}

@end
