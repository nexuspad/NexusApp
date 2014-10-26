//
//  Bookmark.h
//  nexuspad
//
//  Created by Ren Liu on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"

@interface NPBookmark : NPEntry

+ (NPBookmark*)bookmarkFromEntry:(NPEntry*)entry;

@end
