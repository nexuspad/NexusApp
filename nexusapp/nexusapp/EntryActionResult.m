//
//  EntryActionResult.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryActionResult.h"
#import "EntryFactory.h"
#import "EntryList.h"

@implementation EntryActionResult

@synthesize entry = _entry, entries = _entries;

- (id)initWithData:(NSDictionary*)data {
    self = [super init];
    
    if (self && data) {
        self.name = [data valueForKey:ACTION_NAME];
        
        if ([data valueForKey:@"status"] != nil && [[data valueForKey:@"status"] isEqual:@"success"]) {
            self.success = YES;
        } else {
            self.success = NO;
        }
        
        if ([data objectForKey:ENTRY] != nil) {
            self.detail = [data objectForKey:ENTRY];
            
            NPEntry *returnedEntry = [NPEntry entryFromDictionary:self.detail defaultAccessInfo:nil];
            
            // Convert to module object
            _entry = [EntryFactory moduleObject:returnedEntry];

            if (_entry != nil) {
                _entries = [NSArray arrayWithObject:_entry];
            }

        } else if ([data objectForKey:LIST_ENTRIES] != nil) {
            EntryList *entryList = [EntryList parseEntryDataResult:data defaultAccessInfo:nil];
            _entries = entryList.entries;
        }
    }
    
    return self;
}

- (NSString*)description
{
    if (self.success) {
        return [NSString stringWithFormat:@"Action successful. Action name:%@, Code:%d, Body:\n%@", self.name, self.code, self.detail];
    } else {
        return [NSString stringWithFormat:@"Action error. Action name:%@, Code:%d, Body:\n%@", self.name, self.code, self.detail];
    }
}

@end
