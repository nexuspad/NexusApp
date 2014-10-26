//
//  EntryUriHelper.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/24/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "NPEvent.h"
#import "HostInfo.h"
#import "NPJournal.h"

@interface EntryUriHelper : NSObject

+ (NSString*)entryBaseUrl:(NPEntry*)entry;

@end
