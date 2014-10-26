//
//  Listing.m
//  nexuspad
//
//  Created by Ren Liu on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryList.h"
#import "Constants.h"
#import "NSDictionary+NPUtil.h"
#import "NSDate+NPUtil.h"
#import "NPEntry.h"
#import "NPPerson.h"
#import "NPEvent.h"
#import "NPDoc.h"
#import "NPAlbum.h"
#import "DateUtil.h"
#import "EntryFactory.h"


@implementation EntryList

@synthesize accessInfo, folder = _folder, templateId, startDate, endDate, totalCount, countPerPage, pageId, entries, keyword;

- (id)init
{
    self = [super init];
    self.accessInfo = [[AccessEntitlement alloc] init];
    self.entries = [[NSMutableArray alloc] init];
    self.countPerPage = 0;
    self.pageId = 0;
    self.totalCount = 0;
    return self;
}

- (id)initList:(NPFolder*)folder entryTemplateId:(int)entryTemplateId
{
    self = [self init];
    if (self) {
        _folder = [folder copy];

        self.templateId = entryTemplateId;
        
        self.countPerPage = ENTRY_LIST_COUNT;
        
        if (self.folder.moduleId == PHOTO_MODULE) {
            if (self.templateId == photo) {
                self.countPerPage = PHOTO_LIST_COUNT;
            } else {
                self.countPerPage = ENTRY_LIST_COUNT;
            }
            
        } else if (self.folder.moduleId == CONTACT_MODULE || self.folder.moduleId == CALENDAR_MODULE) {
            self.countPerPage = 0;
        }

        self.totalCount = 0;
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    EntryList *newList = [[EntryList alloc] init];
    
    newList.accessInfo = [self.accessInfo copy];
    
    newList.folder = [self.folder copy];
    newList.templateId = self.templateId;
    newList.startDate = [self.startDate copy];
    newList.endDate = [self.endDate copy];
    
    newList.totalCount = self.totalCount;
    newList.countPerPage = self.countPerPage;
    newList.pageId = self.pageId;

    newList.entries = [NSMutableArray arrayWithArray:self.entries];

    newList.keyword = [self.keyword copy];
    
    return newList;
}


- (BOOL)isEmpty {
    return ![self isNotEmpty];
}

- (BOOL)isNotEmpty {
    if (self.folder.subFolders.count == 0 && self.entries.count == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isFolderListResult {
    return ![self isSearchResult];
}

- (BOOL)isSearchResult {
    if (self.keyword != nil) {
        return YES;
    }
    return NO;
}


- (void)addToTopOfList:(NPEntry*)entryToAdd {
    [self.entries insertObject:[entryToAdd copy] atIndex:0];
    self.totalCount++;
}


- (BOOL)deleteFromList:(NPEntry*)entryToDelete {
    NPEntry *affectedEntryInList = nil;
    
    for (NPEntry *entry in self.entries) {
        if ([entry.entryId isEqualToString:entryToDelete.entryId]) {
            affectedEntryInList = entry;
            break;
        }
    }
    
    if (affectedEntryInList != nil && [self.entries count] > 0) {
        [self.entries removeObject:affectedEntryInList];
        self.totalCount--;                                     // Make sure reduce the total count as well
        return YES;
    }
    
    return NO;
}

- (void)updateEntryInList:(NPEntry*)updatedEntry {
    [self deleteFromList:updatedEntry];
    [self addToTopOfList:updatedEntry];
}

- (BOOL)hasMore {
    if (self.countPerPage != 0) {
        if (self.entries.count < self.totalCount &&
            self.totalCount > self.countPerPage)                // compare total count with countPerPage just to make sure
        {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)currentPageId {
    if (self.countPerPage == 0) {
        return 0;
    }
    return ceil((float)self.entries.count/(float)self.countPerPage);
}

- (NSString*)description {
    return [NSString stringWithFormat:
            @"module:%i, folder:%i, template:%i, date range:[%@,%@], search:%@, total:%li, current page id:%li current count:%li",
            self.folder.moduleId, self.folder.folderId, self.templateId, self.startDate, self.endDate, self.keyword, (long)self.totalCount, (long)[self currentPageId], (long)[self.entries count]];
}


// Parse the JSON entry list response and create EntryList object
+ (EntryList*)parseEntryDataResult:(NSDictionary*)dataResultDict defaultAccessInfo:(AccessEntitlement*)defaultAccessInfo {
    EntryList *listingObj = [[EntryList alloc] init];
    
    // List access info
    if ([dataResultDict objectForKey:ACCESS_INFO] != nil) {
        listingObj.accessInfo = [[AccessEntitlement alloc] initWithDictInfo:[dataResultDict objectForKey:ACCESS_INFO]];
    } else {
        listingObj.accessInfo = [defaultAccessInfo copy];
    }
    
    // Summary information
    if ([dataResultDict objectForKeyNotNull:LIST_SUMMARY]) {
        NSDictionary *summary = [dataResultDict objectForKey:LIST_SUMMARY];
        
        listingObj.folder = [[NPFolder alloc] initWithModuleAndFolderId:[[summary valueForKey:MODULE_ID] intValue]
                                                               folderId:[[summary valueForKey:FOLDER_ID] intValue]
                                                             accessInfo:listingObj.accessInfo];
        
        if ([summary objectForKeyNotNull:TEMPLATE_ID]) {
            listingObj.templateId = [[summary valueForKey:TEMPLATE_ID] intValue];
        }
        
        if ([summary objectForKeyNotNull:LIST_START_YMD]) {
            listingObj.startDate = [DateUtil parseFromYYYYMMDD:[summary valueForKey:LIST_START_YMD]];
        }
        if ([summary objectForKeyNotNull:LIST_END_YMD]) {
            /*
             * This needs to be set to the end of day since it will be used for event start time comparison
             * in calendar month view.
             */
            listingObj.endDate = [[DateUtil parseFromYYYYMMDD:[summary valueForKey:LIST_END_YMD]] endOfDay];
        }
        
        if ([summary valueForKey:LIST_SEARCH_KEYWORD] != nil) {
            listingObj.keyword = [NSString stringWithString:[summary valueForKey:LIST_SEARCH_KEYWORD]];
        }
        
        if ([summary objectForKeyNotNull:LIST_TOTAL_COUNT]) {
            listingObj.totalCount = [[summary valueForKey:LIST_TOTAL_COUNT] intValue];
        } else {
            listingObj.totalCount = [listingObj.entries count];
        }
        
        if ([summary objectForKeyNotNull:COUNT_PER_PAGE]) {
            listingObj.countPerPage = [[summary valueForKey:COUNT_PER_PAGE] intValue];
        } else {
            listingObj.countPerPage = [listingObj.entries count];
        }
        
        if ([summary objectForKeyNotNull:LIST_PAGE_ID]) {
            listingObj.pageId = [[summary valueForKey:LIST_PAGE_ID] intValue];
        } else {
            listingObj.pageId = 0;
        }
    }
    

    // Entry records
    NSMutableArray *entryRecords = [[NSMutableArray alloc] init];
    if ([dataResultDict objectForKey:LIST_ENTRIES] != nil) {
        [entryRecords addObjectsFromArray:[dataResultDict objectForKey:LIST_ENTRIES]];
    }
    
    NSMutableArray *entryList = [[NSMutableArray alloc] init];

    if ([entryRecords count] > 0) {
        for (NSDictionary *entryDict in entryRecords) {
            NPEntry *e = [NPEntry entryFromDictionary:entryDict defaultAccessInfo:listingObj.accessInfo];
            
            // Convert to module object
            id moduleObject = [EntryFactory moduleObject:e];

            if (moduleObject != nil) {
                [entryList addObject:moduleObject];
            }
        }
    }
    
    [listingObj.entries addObjectsFromArray:entryList];

    
    // SubFolder records, if there is any
    NSMutableArray *folderRecords = [[NSMutableArray alloc] init];
    if ([dataResultDict objectForKey:LIST_SUB_FOLDERS] != nil) {
        [folderRecords addObjectsFromArray:[dataResultDict objectForKey:LIST_SUB_FOLDERS]];
    }
    
    NSMutableArray *folderList = [[NSMutableArray alloc] init];
    if ([folderRecords count] > 0) {
        for (NSDictionary *folderDict in folderRecords) {
            NPFolder *f = [NPFolder folderFromDictionary:folderDict];
            [folderList addObject:f];
        }
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folderName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        listingObj.folder.subFolders = [folderList sortedArrayUsingDescriptors:sortDescriptors];
    }
    
    return listingObj;
}

@end
