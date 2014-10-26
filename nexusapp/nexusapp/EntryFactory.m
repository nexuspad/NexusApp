//
//  EntryFactory.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryFactory.h"

@implementation EntryFactory

+ (NPEntry*)moduleObject:(NPEntry*)entry {
    switch (entry.templateId) {
        case contact:
            if ([entry isKindOfClass:[NPPerson class]]) {
                return entry;
            }
            return [NPPerson personFromEntry:entry];

        case event:
            if ([entry isKindOfClass:[NPEvent class]]) {
                return entry;
            }
            return [NPEvent eventFromEntry:entry];

        case task:
            if ([entry isKindOfClass:[NPTask class]]) {
                return entry;
            }
            break;

        case note:
        case doc:
            if ([entry isKindOfClass:[NPDoc class]]) {
                return entry;
            }
            return [NPDoc docFromEntry:entry];

        case journal:
            if ([entry isKindOfClass:[NPJournal class]]) {
                return entry;
            }
            return [NPJournal journalFromEntry:entry];

        case photo:
            if ([entry isKindOfClass:[NPPhoto class]]) {
                return entry;
            }
            return [NPPhoto photoFromEntry:entry];

        case album:
            if ([entry isKindOfClass:[NPAlbum class]]) {
                return entry;
            }
            return [NPAlbum albumFromEntry:entry];

        case bookmark:
            if ([entry isKindOfClass:[NPBookmark class]]) {
                return entry;
            }
            return [NPBookmark bookmarkFromEntry:entry];

        default:
            break;
    }

    return entry;
}

@end
