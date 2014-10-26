//
//  Bookmark.m
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPBookmark.h"

@implementation NPBookmark

- (id)init
{
    self = [super init];
    if (self) {
        self.folder.moduleId = BOOKMARK_MODULE;
        self.templateId = bookmark;
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    NPBookmark *bookmark = [[NPBookmark alloc] init];
    [bookmark copyBasic:self];
    return bookmark;
}

+ (NPBookmark*)bookmarkFromEntry:(NPEntry*)entry
{
    if ([entry isKindOfClass:[NPBookmark class]]) {
        return (NPBookmark*)entry;
    }
    
    if (entry == nil) {
        return nil;
    }

    NPBookmark *bookmark = [[NPBookmark alloc] initWithNPEntry:entry];
        
    return bookmark;
}

@end
