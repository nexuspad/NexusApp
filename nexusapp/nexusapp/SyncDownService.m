//
//  SyncDownService.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/26/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "SyncDownService.h"
#import "NPModule.h"
#import "EntryList.h"
#import "EntryStore.h"


#define SYNC_INTERVAL   30

@implementation SyncDownService

static SyncDownService* theService = nil;
static NSTimer *syncTimer;

+ (SyncDownService*)instance {
    if (theService == nil) {
        theService = [[SyncDownService alloc] init];
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
    syncTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(processDownstream) userInfo:nil repeats:NO];
}

- (void)stop {
    DLog(@"Stop the sync downstream timer...");
    [syncTimer invalidate];
}


- (void)processDownstream {
    NSString *urlStr = [NSString stringWithFormat:@"%@/whatsnew", [[HostInfo current] getApiUrl]];
    
    int lastSyncTime = [self getLastSyncTime];

    DLog(@"Start NP downstream syncing process...last syc time: %d", lastSyncTime);

    if (lastSyncTime != 0) {
        urlStr = [NPWebApiService appendParamToUrlString:urlStr
                                               paramName:@"last_sync_time"
                                              paramValue:[NSString stringWithFormat:@"%d", lastSyncTime]];
    }
    
    [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success && responseData != nil) {
            NSError *error = nil;

            DLog(@"Received whatsnew data from service...");
            
            // Stop the timer
            [syncTimer invalidate];
            
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            
            if (result.success) {
                [self setLastSyncTime];

                dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.SyncDownService", NULL);
                dispatch_async(entryStoreQ, ^{
                    for (NSString *key in result.body) {
                        DLog(@"Process module: %@", key);
                        
                        NSDictionary *moduleEntryListData = [result.body objectForKey:key];
                        
                        EntryList *entryList = [EntryList parseEntryDataResult:moduleEntryListData defaultAccessInfo:nil];
                        [[EntryStore instance:nil] storeEntriesAndFolders:entryList];
                    }
                });
            }
        }
    }];
}


- (double)getLastSyncTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double lastSyncDate = [defaults integerForKey:@"LastSyncTime"];
    
    if (!lastSyncDate) {
        lastSyncDate = 0;
    }

    return lastSyncDate;
}

- (void)setLastSyncTime {
    DLog(@"Update the last sync time to now");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    double newSyncDate = [[NSDate date] timeIntervalSince1970];
    [defaults setInteger:newSyncDate forKey:@"LastSyncTime"];
    [defaults synchronize];
}

- (void)resetLastSyncTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0 forKey:@"LastSyncTime"];
    [defaults synchronize];
}

@end
