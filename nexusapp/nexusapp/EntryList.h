//
//  Listing.h
//  nexuspad
//
//  Created by Ren Liu on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessEntitlement.h"
#import "NPFolder.h"
#import "EntryTemplate.h"
#import "NPEntry.h"

@interface EntryList : NSObject

@property (nonatomic, strong) AccessEntitlement *accessInfo;

@property (nonatomic, strong) NPFolder *folder;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property TemplateId templateId;
@property NSInteger totalCount;
@property NSInteger pageId;
@property NSInteger countPerPage;

@property (nonatomic, strong) NSMutableArray *entries;

@property (nonatomic, strong) NSString *keyword;

- (id)initList:(NPFolder*)folder entryTemplateId:(int)entryTemplateId;

- (void)addToTopOfList:(NPEntry*)entryToAdd;
- (BOOL)deleteFromList:(NPEntry*)entryToDelete;
- (void)updateEntryInList:(NPEntry*)updatedEntry;

- (BOOL)isEmpty;
- (BOOL)isNotEmpty;
- (BOOL)hasMore;
- (NSInteger)currentPageId;

- (BOOL)isFolderListResult;
- (BOOL)isSearchResult;

+ (EntryList*)parseEntryDataResult:(NSDictionary*)dataResultDict defaultAccessInfo:(AccessEntitlement*)defaultAccessInfo;

@end
