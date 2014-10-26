//
//  DSEventUtil.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/26/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "DSEventUtil.h"
#import "EntryStore.h"

static BOOL LOG_MORE = NO;

@implementation DSEventUtil

+ (void)dbSaveEvent:(NPEvent*)event inContext:(NSManagedObjectContext*)inContext {
    if (![NPEntry validate:event]) {
        DLog(@"! === ! === ! === ! Record rejected: %@", [event description]);
        return;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"DSEntry"];
    
    if (LOG_MORE)
        DLog(@"Save data store event: [%@ - %d] Recur update: %d", event.entryId, event.recurId, event.recurUpdateOption);
    
    if (event.recurUpdateOption == ALL || event.recurId == 0) {
        if (LOG_MORE)
            DLog(@"User entry Id to find the record: %@", event.entryId);
        request.predicate = [NSPredicate predicateWithFormat:@"(ownerId = %d) AND (moduleId = %d) AND (entryId = %@)",
                             event.accessInfo.owner.userId, event.folder.moduleId, event.entryId];
        
    } else if (event.recurUpdateOption == FUTURE) {
        if (LOG_MORE)
            DLog(@"User entry Id to find the record: %@ >= recur id: %d", event.entryId, event.recurId);
        request.predicate = [NSPredicate predicateWithFormat:@"(ownerId = %d) AND (moduleId = %d) AND (entryId = %@) AND (seqId >= %d)",
                             event.accessInfo.owner.userId, event.folder.moduleId, event.entryId, event.recurId];
        
    } else {
        if (LOG_MORE)
            DLog(@"User entry Id and recur Id to find the record: %@ recur id: %d", event.entryId, event.recurId);
        request.predicate = [NSPredicate predicateWithFormat:@"(ownerId = %d) AND (moduleId = %d) AND (entryId = %@) AND (seqId = %d)",
                             event.accessInfo.owner.userId, event.folder.moduleId, event.entryId, event.recurId];
    }
    
    NSError *error = nil;
    
    NSArray *matches = [inContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        DLog(@"Error finding matches from data store: %@", error);
        return;
    }
    
    NSMutableArray *dsEntries = [NSMutableArray arrayWithArray:matches];
    
    if (matches.count == 0) {
        // Nothing found in local database, we need to add event as new entry.
        DSEntry *dsEntry = [NSEntityDescription insertNewObjectForEntityForName:@"DSEntry" inManagedObjectContext:inContext];
        [dsEntries addObject:dsEntry];
        
    } else {
        if (LOG_MORE)
            DLog(@"Found %li matches.", (long) matches.count);
    }
    
    for (DSEntry *dsEntry in dsEntries) {
        dsEntry.status = [NSNumber numberWithInt:event.status];
        dsEntry.synced = [NSNumber numberWithBool:event.synced];
        dsEntry.createTime = [event.createTime copy];
        
        dsEntry.moduleId = [NSNumber numberWithInt:event.folder.moduleId];
        dsEntry.folderId = [NSNumber numberWithInt:event.folder.folderId];
        dsEntry.entryId = [NSString stringWithString:event.entryId];
        
        dsEntry.templateId = [NSNumber numberWithInt:event.templateId];
        
        dsEntry.seqId = [NSNumber numberWithInt:event.recurId];
        
        dsEntry.ownerId = [NSNumber numberWithInt:event.accessInfo.owner.userId];
        dsEntry.content = [self serializeData:[event buildParamMap]];
        
        // Get the correct date filter populated.
        if (event.startTime != nil) {
            dsEntry.dateFilter = event.startTime;
        }
        
        // Save the record
        if (event.modifiedTime == nil) {
            dsEntry.lastModified = [[NSDate alloc] init];
        } else {
            dsEntry.lastModified = [event.modifiedTime copy];
        }
        
        [inContext save:&error];
        
        if (error != nil) {
            DLog(@"Store key %@ to core data error:%@ ", event.entryId, [error description]);
        } else {
            if (LOG_MORE)
                DLog(@"DB Save: %@ %@ create:%@ mod:%@ ", dsEntry.entryId, dsEntry.seqId, dsEntry.createTime, [dsEntry.lastModified description]);
        }
    }
}

@end
