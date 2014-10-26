//
//  DSEntryDbCall.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/17/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "NPEvent.h"
#import "NPJournal.h"
#import "EntryList.h"
#import "DSEntry.h"
#import "NPManagedDocument.h"
#import "DateUtil.h"

@interface DSEntryUtil : NSObject

+ (EntryList*)dbSelectEntries:(NPManagedDocument*)managedDocument moduleId:(NSInteger)moduleId templateId:(TemplateId)templateId folderId:(NSInteger)folderId startIndex:(NSInteger)startIndex count:(NSInteger)count;

+ (NSMutableArray*)dbSelectEntriesBetweenDates:(NPManagedDocument*)managedDocument moduleId:(NSInteger)moduleId templateId:(TemplateId)templateId folderId:(NSInteger)folderId fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;

+ (NSMutableArray*)dbSelectUnsyncedEntries:(NPManagedDocument*)managedDocument;


+ (NPEntry*)dbSelectEntry:(NPEntry*)entry inContext:(NSManagedObjectContext*)inContext;
+ (NPEntry*)dbSelectEntriesByCreateDate:(NPManagedDocument*)managedDocument moduleId:(NSInteger)moduleId createDate:(NSDate*)createDate;

+ (NPJournal*)dbSelectJournalByKeyFilter:(NPManagedDocument*)managedDocument keyFilter:(NSString*)keyFilter;


+ (void)dbUpdateEntries:(NSManagedObjectContext*)localManagedObjectContext entries:(NSArray*)entries;
+ (void)dbSaveEntry:(NPEntry*)entry inContext:(NSManagedObjectContext*)inContext;
+ (void)dbDeleteEntry:(NPEntry*)entry inContext:(NSManagedObjectContext*)inContext;

+ (void)dbRefreshEntries:(NSManagedObjectContext*)localManagedObjectContext entries:(NSArray*)entries;

+ (void)dbDeleteEntriesInFolder:(NPManagedDocument*)managedDocument moduleId:(NSInteger)moduleId folderId:(NSInteger)folderId;
+ (void)dbDeleteEntry:(NPManagedDocument*)managedDocument entry:(NPEntry*)entry;


+ (NSData*)serializeData:(NSDictionary*)keyData;

@end
