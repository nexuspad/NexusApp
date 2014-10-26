//
//  Media.h
//  nexuspad
//
//  Created by Ren Liu on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPEntry.h"
#import "NPUpload.h"

@interface NPPhoto : NPEntry

@property NSInteger displayIndex;     // This is for displaying image in lightbox.

@property (nonatomic, strong) NSString *tnUrl;
@property (nonatomic, strong) NSString *photoUrl;

@property (nonatomic, strong) NPUpload *uploadImage;

+ (NPPhoto*)photoFromEntry:(NPEntry*)entry;

@end
