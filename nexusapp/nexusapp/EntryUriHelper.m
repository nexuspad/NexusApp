//
//  EntryUriHelper.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/24/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryUriHelper.h"
#import "NPWebApiService.h"

@implementation EntryUriHelper

+ (NSString*)entryBaseUrl:(NPEntry*)entry {
    NSString *urlStr = nil;
    
    if ([entry isKindOfClass:[NPJournal class]]) {
        return [self journalUrl:entry];

    } else if ([entry isKindOfClass:[NPEvent class]]) {
        NPEvent *event = (NPEvent*)entry;
        if ([event isNewEntry]) {
            urlStr = [NSString stringWithFormat:@"%@/event",
                      [[HostInfo current] getApiUrl]];
        } else {
            urlStr = [NSString stringWithFormat:@"%@/event/%@/%d",
                      [[HostInfo current] getApiUrl],
                      event.entryId,
                      event.recurId];
        }
        
    } else {
        if ([entry isNewEntry]) {
            urlStr = [NSString stringWithFormat:@"%@/%@", [[HostInfo current] getApiUrl], [EntryTemplate convertToCode:entry.templateId]];
        } else {
            urlStr = [NSString stringWithFormat:@"%@/%@/%@",
                      [[HostInfo current] getApiUrl],
                      [EntryTemplate convertToCode:entry.templateId],
                      entry.entryId];
        }
        
    }
    
    if (![entry.accessInfo iAmOwner]) {
        urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:entry.accessInfo.owner.userId];
    }
    
    return urlStr;
}


+ (NSString*)journalUrl:(NPEntry*)entry {
    NPJournal *j = (NPJournal*)entry;
    return [NSString stringWithFormat:@"%@/journal/%@", [[HostInfo current] getApiUrl], j.ymd];
}

@end
