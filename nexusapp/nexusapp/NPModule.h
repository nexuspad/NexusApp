//
//  NameHelper.h
//  NexusAppCore
//
//  Created by Ren Liu on 12/17/12.
//  Copyright (c) 2012 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"

@interface NPModule : NSObject

+ (NSString*)emailModuleEntry:(NPEntry*)entry;

+ (NSString*)getModuleCode:(int)forModuleId;
+ (NSString*)getModuleEntryName:(int)forModuleId templateId:(TemplateId)templateId;

+ (int)defaultTemplate:(int)forModuleId;

@end
