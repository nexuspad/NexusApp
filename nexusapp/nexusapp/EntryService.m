//
//  EntryService.m
//  nexuspad
//
//  Created by Ren Liu on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h> 

#import "EntryService.h"
#import "EntryActionResult.h"
#import "NSDictionary+NPUtil.h"

@interface EntryService()
@end

@implementation EntryService

@synthesize accessInfo = _accessInfo;
@synthesize serviceDelegate = _serviceDelegate;

- (id)init {
    self = [super init];
    return self;
}

- (void)getEntryDetail:(NPEntry *)entry {
    if ([NPService isServiceAvailable]) {

        NSString *entryUrl = [EntryUriHelper entryBaseUrl:entry];
        entryUrl = [NPWebApiService appendOwnerParam:entryUrl ownerId:entry.accessInfo.owner.userId];

        [self doGet:entryUrl completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];

                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    /*
                     * Entry detail query from Web API.
                     */
                    NSDictionary *entryDict = [result.body objectForKey:ENTRY];
                    NPEntry *e = [NPEntry entryFromDictionary:entryDict defaultAccessInfo:_accessInfo];
                    
                    if (![NSString isBlank:e.entryId]) {
                        // Update the data store
                        e.synced = YES;
                        [[EntryStore instance:nil] storeEntry:e];
                    }
                    
                    [self.serviceDelegate updateServiceResult:e];

                } else {
                    /*
                     * Handles entry not found
                     */
                    if (result.code == NP_ENTRY_NOT_FOUND) {
                        NSDictionary *entryDict = [result.body objectForKey:ENTRY];
                        NPEntry *nonExistEntry = [NPEntry entryFromDictionary:entryDict defaultAccessInfo:_accessInfo];
                        [[EntryStore instance:nil] deleteEntry:nonExistEntry];
                    }
                    
                    [self.serviceDelegate serviceError:result];
                }

            } else {
                [[EntryStore instance:self] getEntry:entry];
            }
        }];

    } else {
        [[EntryStore instance:self] getEntry:entry];
    }
}


// Add a new entry or update entry
- (void)addOrUpdateEntry:(NPEntry*)entry {
    entry.modifiedTime = [[NSDate alloc] init];

    // Create a tmp entry Id for datastore, also it will be used as syncId
    if (entry.entryId.length == 0) {
        entry.entryId = [NSString stringWithFormat:@"_%@", [NSString genRandString:6]];
    }
    
    if ([entry.accessInfo iAmOwner]) {
        // Save to data store
        entry.synced = NO;
        
        // Notice we don't use event copy here to make sure the tmp Id (if created can be passed back).
        [[EntryStore instance:nil] storeEntry:entry];
    }

    // Save to Web API
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [EntryUriHelper entryBaseUrl:entry];
        urlStr = [NPWebApiService appendParamToUrlString:urlStr
                                               paramName:@"folder_id"
                                              paramValue:[NSString stringWithFormat:@"%d", entry.folder.folderId]];
        
        [self doPost:urlStr parameters:[entry buildParamMap] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    
                    DLog(@"Entry add/update action response:\n%@", entryActionResult);

                    if (entryActionResult.success) {
                        if ([entryActionResult.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                            NPEntry *e = [entryActionResult.entries firstObject];
                            if ([e.accessInfo iAmOwner]) {
                                DLog(@"Update data store record upon successful refresh action response.");
                                
                                dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                                dispatch_async(entryStoreQ, ^{
                                    [[EntryStore instance:nil] refreshEntries:entryActionResult.entries];
                                });
                            }

                        } else {
                            entryActionResult.entry.synced = YES;
                            
                            // Only needs to sync with local database when I am the owner of the entry.
                            if ([entryActionResult.entry.accessInfo iAmOwner]) {
                                dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                                dispatch_async(entryStoreQ, ^{
                                    // Note that syncEntry is called here
                                    [[EntryStore instance:nil] syncEntry:entryActionResult.entry];
                                });
                            }
                        }
                        
                        [self.serviceDelegate updateServiceResult:entryActionResult];

                    } else {
                        [self.serviceDelegate updateServiceResult:entryActionResult];
                    }

                } else {
                    if (result.code == NP_ENTRY_NOT_FOUND) {
                        EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                        DLog(@"Try to update entry but it's not found remotely: %@", [entryActionResult.entry description]);
                        if (entryActionResult.entry != nil) {
                            [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                        }
                    }
                }

            } else {
                // API call is not successful, update the service result delegate with the entry data in local store.
                //
                // TODO - for shared entry, need to report the error.
                //
                EntryActionResult *actionResult = [[EntryActionResult alloc] init];

                actionResult.name = ACTION_UPDATE_ENTRY;
                actionResult.success = YES;
                actionResult.entry = entry;
                [self.serviceDelegate updateServiceResult:actionResult];
            }
        }];

    } else {
        EntryActionResult *actionResult = [[EntryActionResult alloc] init];
        actionResult.name = ACTION_UPDATE_ENTRY;
        actionResult.success = YES;
        actionResult.entry = entry;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}


- (void)updateRemoteEntryCopy:(NPEntry*)entry {
    NSString *urlStr = [NSString stringWithFormat:@"%@?folder_id=%i",
                        [EntryUriHelper entryBaseUrl:entry],
                        entry.folder.folderId];
    
    [self doPost:urlStr parameters:[entry buildParamMap] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success && responseData != nil) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            
            if (result.success) {
                // Always check if it's an action response first.
                if ([result isEntryActionResponse]) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    
                    DLog(@"Update remote entry copy action response:\n%@", entryActionResult);
                    
                    if (entryActionResult.success) {
                        entryActionResult.entry.synced = YES;
                        
                        // Only needs to sync with local database when I am the owner of the entry.
                        if ([entryActionResult.entry.accessInfo iAmOwner]) {
                            // Note that syncEntry is called here
                            [[EntryStore instance:nil] syncEntry:entryActionResult.entry];
                        }
                    }
                }
            } else {
                if (result.code == NP_ENTRY_NOT_FOUND) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    if (entryActionResult.entry != nil) {
                        [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                    }
                }
            }
            
        } else {
        }
    }];
}


// Move entry to a different folder
- (void)moveEntry:(NPEntry*)entry {
    entry.modifiedTime = [[NSDate alloc] init];
    
    if ([entry.accessInfo iAmOwner]) {
        // Save to data store
        entry.synced = NO;
        [[EntryStore instance:nil] storeEntry:entry];
    }
    
    // Save to Web API
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [NSString stringWithFormat:@"%@", [EntryUriHelper entryBaseUrl:entry]];
        
        NSDictionary *params = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"move", [NSNumber numberWithInt:entry.folder.folderId], nil]
                                                             forKeys:[NSArray arrayWithObjects:@"action", @"folder_id", nil]];

        [self doPost:urlStr parameters:params completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    // Always check if it's an action response first.
                    if ([result isEntryActionResponse]) {
                        EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                        
                        DLog(@"Entry move action response:\n%@", entryActionResult);
                        
                        if (entryActionResult.success && [entryActionResult.entry.accessInfo iAmOwner]) {
                            DLog(@"Update data store record upon successful move action response. entry Id:%@, sync Id:%@",
                                 entryActionResult.entry.entryId, entryActionResult.entry.syncId);
                            entryActionResult.entry.synced = YES;
                            
                            dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                            dispatch_async(entryStoreQ, ^{
                                [[EntryStore instance:nil] storeEntry:entryActionResult.entry];
                            });
                        }
                    }

                } else {
                    if (result.code == NP_ENTRY_NOT_FOUND) {
                        EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                        if (entryActionResult.entry != nil) {
                            [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                        }
                    }
                }

            } else {
                // API call is not successful, update the service result delegate with the entry data in local store.
                EntryActionResult *actionResult = [[EntryActionResult alloc] init];
                actionResult.name = @"move_entry";
                actionResult.success = YES;
                actionResult.entry = entry;
                [self.serviceDelegate updateServiceResult:actionResult];
            }
        }];
        
    } else {
        EntryActionResult *actionResult = [[EntryActionResult alloc] init];
        actionResult.name = @"move_entry";
        actionResult.success = YES;
        actionResult.entry = entry;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}


- (void)updateAttribute:(NPEntry *)entry attributeName:(NSString *)attributeName attributeValue:(NSString *)attributeValue {
    entry.modifiedTime = [[NSDate alloc] init];
    
    [entry setFeatureValue:attributeName featureValue:attributeValue];
    
    if ([entry.accessInfo iAmOwner]) {
        // Save to data store
        entry.synced = NO;
        
        // Notice we don't use event copy here to make sure the tmp Id (if created can be passed back).
        [[EntryStore instance:nil] storeEntry:entry];
    }
    
    // Save to Web API
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [NSString stringWithFormat:@"%@/attribute", [EntryUriHelper entryBaseUrl:entry]];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:1];
        [params setObject:attributeValue forKey:attributeName];
        
        [self doPost:urlStr parameters:params completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                if (result.success) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];

                    DLog(@"Entry update attribute action response:\n%@", entryActionResult);

                    if (entryActionResult.success && [entryActionResult.entry.accessInfo iAmOwner]) {
                        entryActionResult.entry.synced = YES;
                        
                        // Only needs to sync with local database when I am the owner of the entry.
                        dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                        dispatch_async(entryStoreQ, ^{
                            [[EntryStore instance:nil] storeEntry:entryActionResult.entry];
                        });
                    }

                    [self.serviceDelegate updateServiceResult:entryActionResult];

                } else {
                    if (result.code == NP_ENTRY_NOT_FOUND) {
                        EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                        if (entryActionResult.entry != nil) {
                            [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                        }
                    }
                }
                
            }
        }];
        
    } else {
        EntryActionResult *actionResult = [[EntryActionResult alloc] init];
        actionResult.name = ACTION_UPDATE_ENTRY;
        actionResult.success = YES;
        actionResult.entry = entry;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}


- (void)deleteEntry:(NPEntry*)entry {
    entry.modifiedTime = [[NSDate alloc] init];
    
    if ([entry isNewEntry]) {                           // For tmp record, just delete it from local storage
        [[EntryStore instance:nil] deleteEntry:entry];
        
    } else {
        if ([entry.accessInfo iAmOwner]) {
            // Save to data store, with "deleted" status. In case the device is offline, we can sync up to server again.
            entry.status = ENTRY_STATUS_DELETED;
            entry.synced = NO;
            [[EntryStore instance:nil] storeEntry:entry];
        }
        
        if ([NPService isServiceAvailable]) {
            NSString *urlStr = [EntryUriHelper entryBaseUrl:entry];

            [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
                if (success && responseData != nil) {
                    NSError *error = nil;
                    NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                                 options:NSJSONReadingMutableLeaves
                                                                                   error:&error];
                    
                    ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                    
                    if (result.success) {
                        EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                        
                        DLog(@"Entry delete action response:\n%@", result);
                        
                        /*
                         * Update the data store.
                         * Server response is the truth of the data.
                         *
                         * When the API call is successful, updateServiceResult here.
                         *
                         */
                        if (entryActionResult.success &&
                            [entryActionResult.name isEqualToString:ACTION_DELETE_ENTRY] &&
                            [entryActionResult.entry.accessInfo iAmOwner])
                        {
                            DLog(@"Delete data store record upon successful delete action response. entry Id:%@", entryActionResult.entry.entryId);
                            
                            dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                            dispatch_async(entryStoreQ, ^{
                                [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                            });
                        }
                        
                        [self.serviceDelegate updateServiceResult:entryActionResult];
                        
                    } else {
                        if (result.code == NP_ENTRY_NOT_FOUND) {
                            EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                            if (entryActionResult.entry != nil) {
                                [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                            }
                        }
                        [self.serviceDelegate serviceError:result];
                    }
                    
                } else {
                }
            }];        
        }
    }
}


- (void)deleteAttachment:(NPUpload*)attachment {
    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@/upload/%@?parent_entry_module=%i&owner_id=%i",
                        [[HostInfo current] getApiUrl],
                        attachment.entryId,
                        attachment.parentEntryModule,
                        attachment.accessInfo.owner.userId];

    [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success && responseData != nil) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            
            if (result.success) {
                EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                
                DLog(@"Entry delete attachment action response:\n%@", result);
                
                if (entryActionResult.success && [entryActionResult.entry.accessInfo iAmOwner]) {
                    entryActionResult.entry.synced = YES;
                    
                    // Only needs to sync with local database when I am the owner of the entry.
                    dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryService", NULL);
                    dispatch_async(entryStoreQ, ^{
                        [[EntryStore instance:nil] storeEntry:entryActionResult.entry];
                    });
                }
                
                [self.serviceDelegate updateServiceResult:entryActionResult];
            }
            
        } else {
        }
    }];
}


- (void)emailEntry:(NPEntry*)entry message:(NPMessage*)message {
    if (message.emailAddresses == nil || [message.emailAddresses count] == 0) {
        return;
    }

    NSString *multiEmailStr = [message.emailAddresses componentsJoinedByString:@";"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjects:
                                   [NSArray arrayWithObjects:multiEmailStr, message.subject, message.messageBody, nil]
                                                                     forKeys:[NSArray arrayWithObjects:@"email_to", @"email_subject", @"email_message", nil]];
    
    [params setObject:@"email_entry" forKey:@"action"];

    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@?action=Share",
                                                    [EntryUriHelper entryBaseUrl:entry]];

    [self doPost:urlStr parameters:params completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success && responseData != nil) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            
            if (result.success) {
                // Always check if it's an action response first.
                if ([result isEntryActionResponse]) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    DLog(@"Entry email action response:\n%@", entryActionResult);
                }
                
            } else {
                if (result.code == NP_ENTRY_NOT_FOUND) {
                    EntryActionResult *entryActionResult = [[EntryActionResult alloc] initWithData:result.body];
                    if (entryActionResult.entry != nil) {
                        [[EntryStore instance:nil] deleteEntry:entryActionResult.entry];
                    }
                }
            }
            
            // Just make a delegate call back
            [self.serviceDelegate updateServiceResult:result];
        }
    }];
}

#pragma mark - entry store delegate
- (void)entryDetailPulledFromStore:(NPEntry *)storedEntry {
    if (storedEntry != nil) {
        DLog(@"Retrieved entry detail from store: %@", [storedEntry description]);
        // The service delegate is a view controller.
        [self.serviceDelegate updateServiceResult:storedEntry];
        
    } else {
        DLog(@"Entry is not found in data store.");
        // This is not really an error. Just so frontend can clean up the load indicator.
        if ([self.serviceDelegate respondsToSelector:@selector(serviceError:)]) {
            ServiceResult *result = [[ServiceResult alloc] initWithCodeAndMessage:NP_ENTRY_NOT_FOUND message:@""];
            [self.serviceDelegate serviceError:result];
        }
    }
}

@end
