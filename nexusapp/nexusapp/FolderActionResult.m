//
//  FolderActionResult.m
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "FolderActionResult.h"

@implementation FolderActionResult

@synthesize folder = _folder;

- (id)initWithData:(NSDictionary*)data {
    self = [super init];
    
    if (self) {
        self.name = [data valueForKey:ACTION_NAME];
        
        if ([data valueForKey:@"status"] != nil && [[data valueForKey:@"status"] isEqual:@"success"]) {
            self.success = YES;
        } else {
            self.success = NO;
        }

        if ([data objectForKey:FOLDER] != nil) {
            self.detail = [data objectForKey:FOLDER];
            _folder = [NPFolder folderFromDictionary:self.detail];
        }
    }
    
    return self;
}

- (NSString*)description
{
    if (self.success) {
        return [NSString stringWithFormat:@"Success. Action name:%@, Code:%d, Body:\n%@", self.name, self.code, self.detail];
    } else {
        return [NSString stringWithFormat:@"Error. Action name:%@, Code:%d, Body:\n%@", self.name, self.code, self.detail];
    }
}

@end
