//
//  EntryFactory.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "NPPerson.h"
#import "NPEvent.h"
#import "NPTask.h"
#import "NPDoc.h"
#import "NPJournal.h"
#import "NPBookmark.h"
#import "NPPhoto.h"
#import "NPAlbum.h"

@interface EntryFactory : NSObject

+ (NPEntry*)moduleObject:(NPEntry*)entry;

@end
