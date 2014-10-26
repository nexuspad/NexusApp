//
//  Journal.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/11/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPJournal.h"
#import "DateUtil.h"

@implementation NPJournal

@synthesize ymd = _ymd;

- (id)init {
    self = [super init];
    self.folder.moduleId = PLANNER_MODULE;
    self.folder.folderId = 0;
    self.templateId = journal;
    self.ymd = [DateUtil convertToYYYYMMDD:[NSDate date]];
    return self;
}

- (id)initJournal:(NSDate*)forDate {
    self = [self init];
    self.folder.moduleId = PLANNER_MODULE;
    self.folder.folderId = 0;
    self.templateId = journal;
    self.createTime = forDate;
    self.ymd = [DateUtil convertToYYYYMMDD:forDate];
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    NPJournal *j = [[NPJournal alloc] init];
    [j copyBasic:self];
    j.ymd = [NSString stringWithString:self.ymd];
    return j;
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[super buildParamMap]];
    
    [params setValue:_ymd forKey:@"journal_date"];
    
    return params;
}

+ (NPJournal*)journalFromEntry:(NPEntry*)entry {
    if ([entry isKindOfClass:[NPJournal class]]) {
        return (NPJournal*)entry;
    }
    
    if (entry == nil) {
        return nil;
    }
    
    NPJournal *j = [[NPJournal alloc] initWithNPEntry:entry];
    j.templateId = journal;
    
    if ([j getFeatureValue:@"journal_date"] != nil) {
        j.ymd = [j getFeatureValue:@"journal_date"];
    }

    return j;
}

@end
