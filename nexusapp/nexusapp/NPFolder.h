//
//  Folder.h
//  nexuspad
//
//  Created by Ren Liu on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPUser.h"
#import "AccessEntitlement.h"

#define ROOT_FOLDER         0
#define SHARER_ROOT_FOLDER  9999;

@interface NPFolder : NSObject <NSCopying>

@property (nonatomic, strong) AccessEntitlement *accessInfo;

@property (nonatomic, strong) NSMutableArray *sharings;        // Users this folder is shared to

@property int status;
@property int synced;
@property (nonatomic, strong) NSDate *modifiedTime;

@property int moduleId;
@property int folderId;
@property int parentId;

// This is for assisting UI
@property int previousParentId;
@property BOOL isCalendarHidden;

@property (nonatomic, strong) NSString *folderCode;
@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) NSString *colorLabel;

@property (nonatomic, strong) NSArray *subFolders;

- (id)initWithModuleAndFolderId:(int)moduleId folderId:(int)folderId accessInfo:(AccessEntitlement*)accessInfo;

- (NSString*)displayName;
- (int)getOwnerId;

- (id)copyWithZone:(NSZone *)zone;

- (void)addSubFolder:(NPFolder*)subFolder;
- (void)deleteSubFolder:(NPFolder*)subFolder;

- (NSDictionary*)buildParamMap;

+ (id)initRootFolder:(int)forModule accessInfo:(AccessEntitlement*)accessInfo;

+ (NPFolder*)folderFromDictionary:(NSDictionary*)folderDict;


- (NSString *)uniqueKey;

@end
