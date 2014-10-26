//
//  DSEntryDbCall.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/17/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "DSEntryUtil.h"
#import "DSEventUtil.h"
#import "UserManager.h"
#import "EntryFactory.h"


@implementation DSEntryUtil

// ---------------------------------------------------------------------------------
// Entry selection methods
// ---------------------------------------------------------------------------------

// Retrieve a bunch of entries in module/folder
// This method should only be called by DataStore subclass. PersistenceService should NOT call this method.
+ (EntryList*)dbSelectEntries:(NPManagedDocument*)managedDocument
                     moduleId:(NSInteger)moduleId
                   templateId:(TemplateId)templateId
                     folderId:(NSInteger)folderId
                   startIndex:(NSInteger)startIndex
                        count:(NSInteger)count
{
    EntryList *entryList = [[EntryList alloc] init];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Retrieve entries in: module:%li folder:%li offset:%li count:%li", (long)moduleId, (long)folderId, (long)startIndex, (long)count);

    /*
     * When getting the list at ROOT, we get EVERYTHING for CONTACT.
     * Otherwise, only gets what's in ROOT folder.
     */
    if (moduleId == CONTACT_MODULE && folderId == 0) {
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (templateId = %d) AND (status = 0) AND (entryId != nil)",
                             moduleId, templateId, folderId];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (templateId = %d) AND (folderId = %d) AND (status = 0) AND (entryId != nil)", moduleId, templateId, folderId];
    }
    
    NSError *error = nil;
    
    if (count > 0) {
        entryList.totalCount = [managedDocument.managedObjectContext countForFetchRequest:request error:&error];
    }
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    // Fetch ALL is the count is 0
    if (count > 0) {
        [request setFetchOffset:startIndex];
        [request setFetchLimit:count];
    }
    
    NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *entryDataArray = [[NSMutableArray alloc] init];
    for (DSEntry *dsEntry in matches) {
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error == nil) {
            NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
            
            [entry setEntryId:dsEntry.entryId];
            
            entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:[dsEntry.moduleId intValue]
                                                              folderId:[dsEntry.folderId intValue]
                                                            accessInfo:[UserManager storeOwnerAccessInfo]];
            
            entry.templateId = (TemplateId)[dsEntry.templateId intValue];
            entry.createTime = dsEntry.createTime;
            entry.modifiedTime = dsEntry.lastModified;
            
            entry.status = [dsEntry.status intValue];
            entry.synced = [dsEntry.synced intValue];
            
            [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];

            // Convert generic NPEntry to more specific object type
            id moduleObject = [EntryFactory moduleObject:entry];
            
            if (moduleObject != nil) {
                [entryDataArray addObject:moduleObject];
            }
        }
    }
    
    entryList.entries = entryDataArray;
    
    return entryList;
}


+ (NSMutableArray*)dbSelectEntriesBetweenDates:(NPManagedDocument*)managedDocument
                                      moduleId:(NSInteger)moduleId
                                    templateId:(TemplateId)templateId
                                      folderId:(NSInteger)folderId
                                      fromDate:(NSDate*)fromDate
                                        toDate:(NSDate*)toDate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Retrieve entries in: module: %li folder: %li between %@ and %@", (long)moduleId, (long)folderId, fromDate, toDate);
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (templateId == %d) AND (dateFilter >= %@) AND (dateFilter <= %@) AND (status = 0) AND (entryId != nil)", moduleId, templateId, fromDate, toDate];
    
    NSError *error = nil;
    NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *entryDataArray = [[NSMutableArray alloc] init];
    for (DSEntry *dsEntry in matches) {
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        if (error == nil) {
            NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
            [entry setEntryId:dsEntry.entryId];
            entry.templateId = (TemplateId)[dsEntry.templateId intValue];
            entry.createTime = dsEntry.createTime;
            [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];
            
            // Convert generic NPEntry to more specific object type
            id moduleObject = [EntryFactory moduleObject:entry];
            
            if (moduleObject != nil) {
                [entryDataArray addObject:moduleObject];
            }
        }
    }
    
    return entryDataArray;
}


+ (NSMutableArray*)dbSelectUnsyncedEntries:(NPManagedDocument*)managedDocument  {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Retrieve unsynced entries.");
    request.predicate = [NSPredicate predicateWithFormat:@"synced = 0"];
    
    NSError *error = nil;
    NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
    
    NSMutableArray *entryDataArray = [[NSMutableArray alloc] init];
    for (DSEntry *dsEntry in matches) {
        if (dsEntry.content != nil) {
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
            if (error == nil) {
                NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
                [entry setEntryId:dsEntry.entryId];
                entry.status = [dsEntry.status intValue];
                entry.templateId = (TemplateId)[dsEntry.templateId intValue];
                [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];
                [entryDataArray addObject:entry];
                
            } else {
                // TODO handle data corruption
            }
        }
    }
    
    return entryDataArray;
}


// Retrieve an offline entry using key.
+ (NPEntry*)dbSelectEntry:(NPEntry*)entry
                inContext:(NSManagedObjectContext*)inContext
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Find entry record with key: [%@]", [entry description]);
    
    if ([entry isKindOfClass:[NPEvent class]]) {
        return [DSEntryUtil dbSelectEvent:(NPEvent *)entry inContext:inContext];
    }
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = %d) AND (entryId = %@)",
                         entry.folder.moduleId, entry.folder.folderId, entry.entryId];

    NSError *error = nil;
    
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        DSEntry *dsEntry = [matches lastObject];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
        [entry setEntryId:dsEntry.entryId];

        entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:[dsEntry.moduleId intValue]
                                                          folderId:[dsEntry.folderId intValue]
                                                        accessInfo:[UserManager storeOwnerAccessInfo]];

        entry.templateId = (TemplateId)[dsEntry.templateId intValue];
        entry.createTime = dsEntry.createTime;
        entry.modifiedTime = dsEntry.lastModified;
        
        entry.status = [dsEntry.status intValue];
        entry.synced = [dsEntry.synced intValue];
        
        [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];

        // Convert generic NPEntry to more specific object type
        id moduleObject = [EntryFactory moduleObject:entry];
        
        return moduleObject;
    }
    
    return nil;
}


+ (NPEvent*)dbSelectEvent:(NPEvent*)event
                inContext:(NSManagedObjectContext*)inContext
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Find entry record with key: [%@]", [event description]);
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = %d) AND (entryId = %@) AND (seqId = %d)",
                             event.folder.moduleId, event.folder.folderId, event.entryId, event.recurId];
    
    NSError *error = nil;
    
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        DSEntry *dsEntry = [matches lastObject];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
        [entry setEntryId:dsEntry.entryId];

        entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:[dsEntry.moduleId intValue]
                                                          folderId:[dsEntry.folderId intValue]
                                                        accessInfo:[UserManager storeOwnerAccessInfo]];

        entry.templateId = (TemplateId)[dsEntry.templateId intValue];
        entry.createTime = dsEntry.createTime;
        entry.modifiedTime = dsEntry.lastModified;
        
        entry.status = [dsEntry.status intValue];
        entry.synced = [dsEntry.synced intValue];
        
        event = [NPEvent eventFromEntry:entry];
        event.recurId = [dsEntry.seqId intValue];
        
        [event setOwnerAccessInfo:[dsEntry.ownerId intValue]];

        return event;
    }
    
    return nil;
}


//
// This is only for journal, to select a particular journal by date
//
+ (NPEntry*)dbSelectEntriesByCreateDate:(NPManagedDocument*)managedDocument
                               moduleId:(NSInteger)moduleId
                             createDate:(NSDate*)createDate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Find entry record module: %li create date:%@", (long)moduleId, createDate);
    
    NSDate *beginOfDate = [DateUtil startOfDate:createDate];
    NSDate *endOfDate = [DateUtil endOfDate:createDate];
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (createTime >= %@) AND (createTime < %@)",
                         moduleId, beginOfDate, endOfDate];
    
    NSError *error = nil;

    NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        DSEntry *dsEntry = [matches lastObject];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
        
        [entry setEntryId:dsEntry.entryId];

        entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:[dsEntry.moduleId intValue]
                                                          folderId:[dsEntry.folderId intValue]
                                                        accessInfo:[UserManager storeOwnerAccessInfo]];

        entry.templateId = (TemplateId)[dsEntry.templateId intValue];
        entry.createTime = dsEntry.createTime;
        entry.modifiedTime = dsEntry.lastModified;
        
        entry.status = [dsEntry.status intValue];
        entry.synced = [dsEntry.synced intValue];
        
        [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];
        
        return entry;
    }
    
    return nil;
}


+ (NPJournal*)dbSelectJournalByKeyFilter:(NPManagedDocument*)managedDocument keyFilter:(NSString*)keyFilter {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    DLog(@"Find journal record using key filter:%@", keyFilter);
    
    request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = 7) AND (keyFilter = %@)", keyFilter];
    
    NSError *error = nil;
    
    NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        DSEntry *dsEntry = [matches lastObject];
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:dsEntry.content
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
        
        NPEntry *entry = [NPEntry entryFromDictionary:result defaultAccessInfo:nil];
        
        [entry setEntryId:dsEntry.entryId];
        
        entry.folder = [[NPFolder alloc] initWithModuleAndFolderId:[dsEntry.moduleId intValue]
                                                          folderId:[dsEntry.folderId intValue]
                                                        accessInfo:[UserManager storeOwnerAccessInfo]];
        
        entry.templateId = (TemplateId)[dsEntry.templateId intValue];
        entry.createTime = dsEntry.createTime;
        entry.modifiedTime = dsEntry.lastModified;
        
        entry.status = [dsEntry.status intValue];
        entry.synced = [dsEntry.synced intValue];
        
        [entry setOwnerAccessInfo:[dsEntry.ownerId intValue]];
        
        NPJournal *j = [NPJournal journalFromEntry:entry];
        j.ymd = dsEntry.keyFilter;
        
        return j;
    }
    
    return nil;
}


// ---------------------------------------------------------------------------------
// Entry update methods
// ---------------------------------------------------------------------------------


// Save a bunch of entries. This should be called in a dispatch_async block
+ (void)dbUpdateEntries:(NSManagedObjectContext*)localManagedObjectContext entries:(NSArray*)entries {
    [localManagedObjectContext performBlockAndWait:^{
        for (NPEntry *entry in entries) {
            if (entry.status == ENTRY_STATUS_DELETED) {
                [DSEntryUtil dbDeleteEntry:entry inContext:localManagedObjectContext];
            } else {
                entry.synced = YES;
                [DSEntryUtil dbSaveEntry:entry inContext:localManagedObjectContext];
            }
        }
        
        [localManagedObjectContext.parentContext performBlock:^{
            NSError *parentError = nil;
            [localManagedObjectContext.parentContext save:&parentError];
        }];
    }];
}


//
// This is used to refresh a bunch of entries, with entries have different statuses.
//
// When updating a sequence of entries, such as recurring events,
// We need to update multiple records in local database as well. This is called to handle that kind of operation.
+ (void)dbRefreshEntries:(NSManagedObjectContext*)localManagedObjectContext entries:(NSArray*)entries {
    DLog(@"Received a list of entries to refresh local data store...");

    [localManagedObjectContext performBlockAndWait:^{
        // Delete all occurrences before refreshing with the new ones
        NSMutableArray *entriesToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *entryIdsToDelete = [[NSMutableArray alloc] init];
        for (NPEntry *entry in entries) {
            if (![entryIdsToDelete containsObject:entry.entryId]) {
                [entryIdsToDelete addObject:entry.entryId];
                [entriesToDelete addObject:entry];
            }
        }
        
        // Delete the entries first
        for (NPEntry *deleteThis in entriesToDelete) {
            DLog(@"Delete existing record if it exists: module:%d entryId: %@", deleteThis.folder.moduleId, deleteThis.entryId);
            [self dbDeleteEntry:deleteThis inContext:localManagedObjectContext];
        }
        
        // Save entries one by one
        for (NPEntry *entry in entries) {
            if ([entry isKindOfClass:[NPEvent class]]) {
                NPEvent *event = (NPEvent*)entry;
                event.synced = YES;
                event.recurUpdateOption = ONE;
                [DSEventUtil dbSaveEvent:event inContext:localManagedObjectContext];
            } else {
                entry.synced = YES;
                [DSEntryUtil dbSaveEntry:entry inContext:localManagedObjectContext];
            }
        }
        
        // Propogate to parent context
        [localManagedObjectContext.parentContext performBlock:^{
            NSError *parentError = nil;
            [localManagedObjectContext.parentContext save:&parentError];
        }];
    }];
}


// NOTE that we don't use copy of entry here because a tmp Id might be assigned to entryId, we need to
// make sure it's assigned and passed back before making the web service call.
+ (void)dbSaveEntry:(NPEntry*)entry inContext:(NSManagedObjectContext*)inContext {
    if (![NPEntry validate:entry]) {
        DLog(@"! === ! === ! === ! Record rejected: %@", [entry description]);
        return;
    }

    // Save an event.
    if ([entry isKindOfClass:[NPEvent class]]) {
        [DSEventUtil dbSaveEvent:(NPEvent *)entry inContext:inContext];
        return;
    }

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    request.predicate = [NSPredicate predicateWithFormat:@"(ownerId = %d) AND (moduleId = %d) AND (folderId = %d) AND (entryId = %@)",
                         entry.accessInfo.owner.userId, entry.folder.moduleId, entry.folder.folderId, [entry getEntryId]];
    NSError *error = nil;
    
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DLog(@"Error finding matches from data store: %@", error);
    }
    
    DSEntry *dsEntry = nil;
    
    if (!matches || [matches count] == 0 || [matches count] > 1) {
        if ([matches count] > 1) {                                      // This really shoudn't happen
            for (DSEntry *item in matches) {
                [inContext deleteObject:item];
            }
        }
        dsEntry = [NSEntityDescription insertNewObjectForEntityForName:@"DSEntry" inManagedObjectContext:inContext];
        
    } else if ([matches count] == 1) {
        dsEntry = [matches lastObject];
    }
    
    dsEntry.status = [NSNumber numberWithInt:entry.status];
    dsEntry.synced = [NSNumber numberWithBool:entry.synced];
    
    if (entry.createTime != nil) {
        dsEntry.createTime = [entry.createTime copy];
    } else {
        dsEntry.createTime = [[NSDate alloc] init];
    }
    
    dsEntry.moduleId = [NSNumber numberWithInt:entry.folder.moduleId];
    dsEntry.folderId = [NSNumber numberWithInt:entry.folder.folderId];
    dsEntry.entryId = [NSString stringWithString:entry.entryId];
    
    dsEntry.templateId = [NSNumber numberWithInt:entry.templateId];
    
    dsEntry.ownerId = [NSNumber numberWithInt:entry.accessInfo.owner.userId];
    dsEntry.content = [self serializeData:[entry buildParamMap]];
    
    if (entry.createTime != nil) {
        dsEntry.dateFilter = [entry.createTime copy];
    }
    
    // Save the record
    if (entry.modifiedTime == nil) {
        dsEntry.lastModified = [[NSDate alloc] init];
    } else {
        dsEntry.lastModified = [entry.modifiedTime copy];
    }
    
    // For Journal entry, use the key filter column to store the journal date
    if (entry.templateId == journal) {
        NPJournal *j = (NPJournal*)entry;
        dsEntry.keyFilter = j.ymd;
    }
    
    [inContext save:&error];
    
    if (error != nil) {
        DLog(@"Store key %@ to core data error:%@ ", [entry description], [error description]);
    }
}


// ---------------------------------------------------------------------------------
// Entry deletion methods
// ---------------------------------------------------------------------------------

// Delete entries in module/folder
+ (void)dbDeleteEntriesInFolder:(NPManagedDocument*)managedDocument moduleId:(NSInteger)moduleId folderId:(NSInteger)folderId {
    [managedDocument.managedObjectContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
        
        DLog(@"Delete data store entries in: module: %li folder: %li", (long)moduleId, (long)folderId);
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (folderId = %d)", moduleId, folderId];
        
        NSError *error = nil;
        NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
        
        // Delete matches.
        for (DSEntry *item in matches) {
            [managedDocument.managedObjectContext deleteObject:item];
        }
    }];
}


// Delete entry using the child context. This is used in dbRefreshEntries.
+ (void)dbDeleteEntry:(NPEntry*)entry inContext:(NSManagedObjectContext*)inContext {
    if (![NPEntry validate:entry]) {
        DLog(@"! === ! === ! === ! Record rejected: %@", [entry description]);
        return;
    }

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    //DLog(@"Delete data store entry: [%@]", [entry description]);
    request.predicate = [NSPredicate predicateWithFormat:@"(ownerId = %d) AND  (moduleId = %d) AND (entryId = %@)",
                         entry.accessInfo.owner.userId, entry.folder.moduleId, entry.entryId];
    
    NSError *error = nil;
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DLog(@"Error deleting entry:%@ ", [error description]);
    }
    
    // Delete matches.
    for (DSEntry *item in matches) {
        [inContext deleteObject:item];
    }
}


// Delete an entry directly from the document.
+ (void)dbDeleteEntry:(NPManagedDocument*)managedDocument entry:(NPEntry*)entry {
    if ([entry isKindOfClass:[NPEvent class]]) {
        [DSEntryUtil dbDeleteEvent:managedDocument event:(NPEvent *)entry];
        return;
    }
    
    [managedDocument.managedObjectContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
        
        //DLog(@"Delete data store entry: [%@]", [entry description]);
        request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (entryId = %@)", entry.folder.moduleId, entry.entryId];
        
        NSError *error = nil;
        NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
        
        if (error != nil) {
            DLog(@"Error deleting entry:%@ ", [error description]);
        }
        
        // Delete matches.
        for (DSEntry *item in matches) {
            [managedDocument.managedObjectContext deleteObject:item];
        }
    }];
}


// Delete an event
+ (void)dbDeleteEvent:(NPManagedDocument*)managedDocument event:(NPEvent*)event {
    [managedDocument.managedObjectContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
        
        if (event.recurUpdateOption == ALL) {
            DLog(@"Delete data store event: all %@ ", event.entryId);
            request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (entryId = %@)",
                                 event.folder.moduleId, event.entryId, event.recurId];
            
        } else if (event.recurUpdateOption == FUTURE) {
            DLog(@"Delete data store event: [%@ >= %d]", event.entryId, event.recurId);
            request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (entryId = %@) AND (seqId >= %d)",
                                 event.folder.moduleId, event.entryId, event.recurId];
            
        } else {
            DLog(@"Delete data store event: [%@ - %d]", event.entryId, event.recurId);
            request.predicate = [NSPredicate predicateWithFormat:@"(moduleId = %d) AND (entryId = %@) AND (seqId = %d)",
                                 event.folder.moduleId, event.entryId, event.recurId];
        }
        
        
        NSError *error = nil;
        NSArray *matches = [managedDocument.managedObjectContext executeFetchRequest:request error:&error];
        
        if (error != nil) {
            DLog(@"Error deleting event:%@ ", [error description]);
        }
        
        // Delete matches.
        for (DSEntry *item in matches) {
            [managedDocument.managedObjectContext deleteObject:item];
        }
    }];
}


+ (NSData*)serializeData:(NSDictionary*)keyData {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:keyData
                                                       options:0
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Error serializing dictionary data to json string: %@", error);
    }
    
    return jsonData;
}

@end
