//
//  EntryActionResult.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "ActionResult.h"

@interface EntryActionResult : ActionResult

@property (nonatomic, strong) NPEntry *entry;
@property (nonatomic, strong) NSArray *entries;

- (id)initWithData:(NSDictionary*)dict;

@end
