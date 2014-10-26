//
//  FolderActionResult.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/10/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "ActionResult.h"

@interface FolderActionResult : ActionResult

@property (nonatomic, strong) NPFolder *folder;

- (id)initWithData:(NSDictionary*)dict;

@end
