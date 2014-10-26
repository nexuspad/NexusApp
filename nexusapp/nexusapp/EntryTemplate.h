//
//  EntryTemplate.h
//  NexusAppCore
//
//  Created by Ren Liu on 7/21/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    not_assigned = 0,
    contact = 101,
    event = 201,
    task = 204,
    bookmark = 301,
    note = 401,
    doc = 403,
    upload = 501,
    photo = 601,
    album = 602,
    journal = 701,
    sticky = 702
} TemplateId;

@interface EntryTemplate : NSObject

+ (NSString*)convertToCode:(TemplateId)id;

@end
