//
//  EntryListService.m
//  NexusAppCore
//
//  Created by Ren Liu on 12/24/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "EntryListService.h"
#import "EntryStore.h"
#import "NPModule.h"
#import "ActionResult.h"
#import "NSDictionary+NPUtil.h"
#import "AccountManager.h"
#import "DateUtil.h"

@implementation EntryListService

@synthesize currentFolder = _currentFolder;
@synthesize serviceDelegate = _serviceDelegate;


- (id)init {
    self = [super init];
    return self;
}


/*
 * Get entries in folder.
 */
- (void)getEntries:(TemplateId)templateId inFolder:(NPFolder*)inFolder pageId:(NSInteger)pageId countPerPage:(NSInteger)countPerPage {
    self.currentFolder = [inFolder copy];

    // Build EntryList object
    EntryList *entryList = [[EntryList alloc] init];
    entryList.accessInfo = [inFolder.accessInfo copy];
    entryList.folder = [inFolder copy];
    entryList.templateId = templateId;
    entryList.pageId = pageId;
    entryList.countPerPage = countPerPage;

    if ([NPService isServiceAvailable] == YES) {
        self.responseData = [[NSMutableData alloc] init];
        
        [self doGet:[self entryListUrl:inFolder type:templateId owner:entryList.accessInfo.owner pageId:pageId count:countPerPage]
         completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
             if (success) {
                 NSError *error = nil;
                 NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                              options:NSJSONReadingMutableLeaves
                                                                                error:&error];
                 
                 ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];

                 EntryList *entryList = [EntryList parseEntryDataResult:result.body defaultAccessInfo:self.currentFolder.accessInfo];
                 [self.serviceDelegate updateServiceResult:entryList];
                 
                 if ([entryList.accessInfo iAmOwner]) {
                     dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryListService", NULL);
                     dispatch_async(entryStoreQ, ^{
                        [[EntryStore instance:nil] storeEntriesAndFolders:entryList];
                     });
                 }

             } else {
                 // Fall back to local store
                 [[EntryStore instance:self] getEntries:entryList];
             }
        }];
        
    } else {
        [[EntryStore instance:self] getEntries:entryList];
    }
}


/*
 * Get entries by date range
 */
- (void)getEntriesByDateRange:(TemplateId)templateId inFolder:(NPFolder*)inFolder startDate:(NSDate*)startDate endDate:(NSDate*)endDate {
    // Build EntryList object
    EntryList *entryList = [[EntryList alloc] init];
    
    entryList.accessInfo = [inFolder.accessInfo copy];
    entryList.folder = [inFolder copy];
    entryList.templateId = templateId;
    entryList.startDate = startDate;
    entryList.endDate = endDate;
    
    if ([NPService isServiceAvailable] == YES) {
        self.currentFolder = [inFolder copy];

        self.responseData = [[NSMutableData alloc] init];
        NSString *urlStr = [NSString stringWithFormat:@"%@/%@?folder_id=%i&type=%i&start_date=%@&end_date=%@&owner_id=%d",
                            [[HostInfo current] getApiUrl],
                            [self moduleListHome:inFolder.moduleId templateId:templateId],
                            inFolder.folderId,
                            templateId,
                            [DateUtil convertToYYYYMMDD:startDate],
                            [DateUtil convertToYYYYMMDD:endDate],
                            entryList.accessInfo.owner.userId];
        
        [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                EntryList *entryList = [EntryList parseEntryDataResult:result.body defaultAccessInfo:self.currentFolder.accessInfo];
                [self.serviceDelegate updateServiceResult:entryList];
                
                if ([entryList.accessInfo iAmOwner]) {
                    dispatch_queue_t entryStoreQ = dispatch_queue_create("com.nexusapp.EntryListService", NULL);
                    dispatch_async(entryStoreQ, ^{
                        [[EntryStore instance:nil] storeEntriesAndFolders:entryList];
                    });
                }

            } else {
                // Fall back to local store
                [[EntryStore instance:self] getEntriesWithDateFilter:entryList];
            }
        }];
        
    } else {
        [[EntryStore instance:self] getEntriesWithDateFilter:entryList];
    }
}


- (void)searchEntries:(NSString*)searchStr templateId:(TemplateId)templateId inFolder:(NPFolder*)inFolder pageId:(NSInteger)pageId countPerPage:(NSInteger)countPerPage {
    self.responseData = [[NSMutableData alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@?folder_id=%i&owner_id=%d&Keyword=%@&page=%li&count=%li",
                                                    [[HostInfo current] getApiUrl],
                                                    [self moduleListHome:inFolder.moduleId templateId:templateId],
                                                    inFolder.folderId,
                                                    inFolder.accessInfo.owner.userId,
                                                    searchStr,
                                                    (long)pageId,
                                                    (long)countPerPage];
    [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
            
            EntryList *entryList = [EntryList parseEntryDataResult:result.body defaultAccessInfo:self.currentFolder.accessInfo];
            [self.serviceDelegate updateServiceResult:entryList];

        } else {
            // TODO: local core data search
        }
    }];
}


#pragma mark - entry store delegate

- (void)entryListPulledFromStore:(EntryList *)entryList {
    if (entryList != nil) {
        DLog(@"Found persisted entry list result for: %@", [entryList description]);
        for (NPEntry *e in entryList.entries) {
            e.accessInfo = [entryList.accessInfo copy];
        }
        [self.serviceDelegate updateServiceResult:entryList];
        
    } else {
        DLog(@"Persistent data not available for: %@", [entryList description]);
        if ([self.serviceDelegate respondsToSelector:@selector(serviceError:)]) {
            ServiceResult *result = [[ServiceResult alloc] initWithCodeAndMessage:NP_DATA_STORE_NOT_AVAILABLE
                                                                          message:NSLocalizedString(@"Data store service not available.",)];
            [self.serviceDelegate serviceError:result];
        }
    }
}


// Create entry list URL
- (NSString*)entryListUrl:(NPFolder*)inFolder type:(NSInteger)type owner:(NPUser*)owner pageId:(NSInteger)pageId count:(NSInteger)count {
    NSString *urlStr;

    urlStr = [NSString stringWithFormat:@"%@/%@?type=%li&page=%li&count=%li&owner_id=%d",
              [[HostInfo current] getApiUrl],
              [self moduleListHome:inFolder.moduleId templateId:type],
              (long)type,
              (long)pageId,
              (long)count,
              owner.userId];

    if ((inFolder.moduleId == CONTACT_MODULE || inFolder.moduleId == PHOTO_MODULE) && inFolder.folderId == ROOT_FOLDER) {
        urlStr = [NPWebApiService appendParamToUrlString:urlStr
                                               paramName:@"folder_id" paramValue:@"all"];

    } else {
        urlStr = [NPWebApiService appendParamToUrlString:urlStr
                                               paramName:@"folder_id" paramValue:[NSString stringWithFormat:@"%d", inFolder.folderId]];
    }
    
    return urlStr;
}


- (NSString*)moduleListHome:(NSInteger)moduleId templateId:(NSInteger)templateId {
    switch (moduleId) {
        case 1:
            return @"contacts";
            
        case 2:
            if (templateId == event) {
                return @"events";
            } else if (templateId == task) {
                return @"tasks";
            }
    
        case 3:
            return @"bookmarks";
        
        case 4:
            return @"docs";
            
        case 5:
            return @"uploads";
            
        case 6:
            if (templateId == photo) {
                return @"photos";
            } else if (templateId == album) {
                return @"albums";
            }
            return @"photos";
        
        case 7:
            return @"journals";

        default:
            break;
    }
    
    return @"";
}

@end
