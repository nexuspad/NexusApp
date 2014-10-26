//
//  Note.h
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPEntry.h"

// Data object for doc or journal

@interface NPDoc : NPEntry

@property BOOL richText;

- (id)initDoc;

+ (NPDoc*)docFromEntry:(NPEntry*)entry;

@end
