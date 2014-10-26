//
//  DSEventUtil.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/26/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEvent.h"
#import "DSEntryUtil.h"

@interface DSEventUtil : DSEntryUtil

+ (void)dbSaveEvent:(NPEvent*)event inContext:(NSManagedObjectContext*)inContext;

@end
