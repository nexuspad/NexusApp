//
//  Note.m
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPDoc.h"
#import "DateUtil.h"

@implementation NPDoc

@synthesize richText;

- (id)init
{
    self = [super init];
    self.folder.moduleId = DOC_MODULE;
    self.templateId = doc;
    return self;
}

- (id)initDoc {
    self = [self init];
    self.folder.moduleId = DOC_MODULE;
    self.templateId = doc;
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    NPDoc *note = [[NPDoc alloc] init];
    [note copyBasic:self];
    note.attachments = [self.attachments copy];
    return note;
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[super buildParamMap]];
    return params;
}

+ (NPDoc*)docFromEntry:(NPEntry*)entry
{
    if ([entry isKindOfClass:[NPDoc class]]) {
        return (NPDoc*)entry;
    }
    
    if (entry == nil) {
        return nil;
    }
    
    NPDoc *theDoc = [[NPDoc alloc] initWithNPEntry:entry];

    theDoc.richText = NO;
    theDoc.templateId = doc;

    return theDoc;
}

@end
