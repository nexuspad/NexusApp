//
//  EntryViewPrevNextDelegate.h
//  nexuspad
//
//  Created by Ren Liu on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPScrollIndex.h"

@protocol EntryLightboxViewDelegate <NSObject>

- (id)getEntryAtIndex:(NSInteger)index;

// This is called by LightboxViewController to delete an entry at index, in addition, it returns the next index.
- (NPScrollIndex*)deleteEntryAtIndex:(NSInteger)index;

@end
