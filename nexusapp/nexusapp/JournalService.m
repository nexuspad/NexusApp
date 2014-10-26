//
//  JournalService.m
//  NexusAppCore
//
//  Created by Ren Liu on 1/2/14.
//  Copyright (c) 2014 Ren Liu. All rights reserved.
//

#import "JournalService.h"
#import "UserManager.h"

@implementation JournalService

- (void)getJournal:(int)moduleId forDate:(NSDate*)forDate {
    NSString *ymd = [DateUtil convertToYYYYMMDD:forDate];
    
    NPJournal *localJournal = [[EntryStore instance:self] getJournal:ymd];
    
    __block BOOL aCopyOfJournalIsReturned = NO;
    
    if (localJournal != nil) {
        aCopyOfJournalIsReturned = YES;
        [self.serviceDelegate updateServiceResult:localJournal];
    }
    
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [NSString stringWithFormat:@"%@/journal/%@", [[HostInfo current] getApiUrl], [DateUtil convertToYYYYMMDD:forDate]];
        
        [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success && responseData != nil) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];

                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];

                /*
                 * Entry detail query from Web API.
                 */
                if (result.success) {
                    // Obtain a local copy
                    NPJournal *localCopy = [[EntryStore instance:self] getJournal:ymd];

                    NSDictionary *entryDict = [result.body objectForKey:ENTRY];
                    NPEntry *e = [NPEntry entryFromDictionary:entryDict defaultAccessInfo:[UserManager storeOwnerAccessInfo]];
                    
                    if ([NSString isNotBlank:e.entryId]) {
                        if (localCopy == nil ||
                            [e.modifiedTime compare:localCopy.modifiedTime] == NSOrderedDescending ||
                            [e.modifiedTime compare:localCopy.modifiedTime] == NSOrderedSame)
                        {
                            // Update the local data store if the remote copy has later or the same modification time.
                            e.synced = YES;
                            [[EntryStore instance:nil] storeEntry:e];
                            [self.serviceDelegate updateServiceResult:e];
                            
                            // Remove the local copy if it has a different entry Id, which can be a tmp Id
                            // Usually the tmp Id should have been taken care of during the sync up process. However we want to be on the safe side.
                            if (![e.entryId isEqualToString:localCopy.entryId]) {
                                [[EntryStore instance:nil] deleteEntry:localCopy];
                            }

                        } else {
                            DLog(@"The local copy has later update date. Update the remote copy...");
                            [self updateRemoteEntryCopy:localCopy];
                        }
                        
                    } else {
                        /*
                         * Journal entry returns empty entry id, which means no journal exist in the remote.
                         */
                        if (localCopy != nil) {
                            // Update remote if local copy exists.
                            [self updateRemoteEntryCopy:localCopy];
                            
                        } else {
                            // Go ahead send the empty copy to UI.
                            [self.serviceDelegate updateServiceResult:e];
                        }
                    }
                    
                    aCopyOfJournalIsReturned = YES;

                } else {
                    // Some other errors happened.
                }
            }
        }];
    }
    
    /*
     * No journal is stored locally we have problem with remote service (not even an empty entry is returned)
     */
    if (aCopyOfJournalIsReturned == NO) {
        localJournal = [[NPJournal alloc] initJournal:forDate];
        localJournal.accessInfo = [[UserManager instance] defaultAccessInfo];
        
        [self.serviceDelegate updateServiceResult:localJournal];        
    }
}

@end
