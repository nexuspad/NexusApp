//
//  FolderList.h
//  NexusAppCore
//
//  Created by Ren Liu on 11/2/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPFolder.h"
#import "CoreSettings.h"

@interface FolderList : NSObject

@property int moduleId;
@property (nonatomic, strong) NSMutableDictionary *folderDict;

- (void)addUpdateMoveFolder:(NPFolder*)folder;
- (void)deleteFolder:(NPFolder*)folder;

+ (FolderList*)parseAllFoldersResult:(NSDictionary*)folderSvcResult moduleId:(int)moduleId;

@end
