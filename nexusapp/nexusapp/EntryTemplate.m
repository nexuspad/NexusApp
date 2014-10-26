
//
//  EntryTemplate.m
//  NexusAppCore
//
//  Created by Ren Liu on 7/21/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryTemplate.h"

@implementation EntryTemplate

+ (NSString*)convertToCode:(TemplateId)id {
    NSString *code = nil;

    switch (id) {
        case contact:
            code = @"contact";
            break;
        case event:
            code = @"event";
            break;
        case task:
            code = @"task";
            break;
        case note:
        case doc:
            code = @"doc";
            break;
        case journal:
            code = @"journal";
            break;
        case photo:
            code = @"photo";
            break;
        case album:
            code = @"album";
            break;
        case bookmark:
            code = @"bookmark";
            break;
        case upload:
            code = @"upload";
            break;
        case sticky:
        case not_assigned:
            break;
    }
    
    return code;
}

@end
