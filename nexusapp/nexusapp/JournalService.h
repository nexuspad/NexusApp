//
//  JournalService.h
//  NexusAppCore
//
//  Created by Ren Liu on 1/2/14.
//  Copyright (c) 2014 Ren Liu. All rights reserved.
//

#import "EntryService.h"

@interface JournalService : EntryService

- (void)getJournal:(int)inModule forDate:(NSDate*)forDate;

@end
