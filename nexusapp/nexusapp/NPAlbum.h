//
//  Album.h
//  NexusAppCore
//
//  Created by Ren Liu on 1/16/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPEntry.h"

@interface NPAlbum : NPEntry

- (NSString*)tnUrl;

+ (NPAlbum*)albumFromEntry:(NPEntry*)entry;

@end
