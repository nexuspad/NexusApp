//
//  Journal.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/11/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPEntry.h"

@interface NPJournal : NPEntry

@property (nonatomic, strong) NSString *ymd;

- (id)initJournal:(NSDate*)forDate;

+ (NPJournal*)journalFromEntry:(NPEntry*)entry;

@end
