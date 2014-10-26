//
//  EntryListService.h
//  NexusAppCore
//
//  Created by Ren Liu on 12/24/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import "EntryStore.h"
#import "NPWebApiService.h"
#import "EntryList.h"
#import "NPFolder.h"
#import "NPEntry.h"
#import "NPEvent.h"
#import "NPMessage.h"

@interface EntryListService : NPWebApiService <EntryStoreDelegate>

@property (nonatomic, strong) NPFolder *currentFolder;

- (void)getEntries:(TemplateId)templateId inFolder:(NPFolder*)inFolder pageId:(NSInteger)pageId countPerPage:(NSInteger)countPerPage;
- (void)getEntriesByDateRange:(TemplateId)templateId inFolder:(NPFolder*)inFolder startDate:(NSDate*)startDate endDate:(NSDate*)endDate;
- (void)searchEntries:(NSString*)searchStr templateId:(TemplateId)templateId inFolder:(NPFolder*)inFolder pageId:(NSInteger)pageId countPerPage:(NSInteger)countPerPage;

@end
