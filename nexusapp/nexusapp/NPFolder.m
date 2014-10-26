//
//  Folder.m
//  nexuspad
//
//  Created by Ren Liu on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPFolder.h"
#import "Constants.h"
#import "NSString+NPStringUtil.h"
#import "NSDictionary+NPUtil.h"
#import "AccessPermission.h"

@implementation NPFolder

@synthesize accessInfo = _accessInfo, sharings = _sharings;
@synthesize moduleId = _moduleId;
@synthesize folderId = _folderId;
@synthesize folderCode = _folderCode;
@synthesize folderName = _folderName;
@synthesize parentId = _parentId, previousParentId = _previousParentId;
@synthesize subFolders = _subFolders;
@synthesize colorLabel = _colorLabel;
@synthesize modifiedTime = _modifiedTime;

- (id)init
{
    self = [super init];
    if (self) {
        self.folderId = ROOT_FOLDER;
        self.folderName = @"";
        self.folderCode = @"home";
        self.parentId = -1;
        self.previousParentId = -1;
        
        self.accessInfo = [[AccessEntitlement alloc] init];
        
        self.status = 0;

        // By default, not hidden;
        self.isCalendarHidden = NO;
        
        return self;
    }

    return self;
}

- (id)initWithModuleAndFolderId:(int)moduleId folderId:(int)folderId accessInfo:(AccessEntitlement *)accessInfo
{
    self = [super init];
    if (self) {
        self.moduleId = moduleId;
        self.folderId = folderId;
        self.parentId = -1;
        self.previousParentId = -1;
        self.accessInfo = [accessInfo copy];
    }
    
    return self;
}

// This is for folder array operation like delete object from array.
- (BOOL)isEqual:(NPFolder*)other {
    if (other == self)
        return YES;
    
    if ([super isEqual:other])
        return YES;
    
    if (self.moduleId == other.moduleId && self.folderId == other.folderId && [self getOwnerId] == [other getOwnerId]) {
        return YES;
    }
    
    return NO;
}


- (NSUInteger)hash {
    return self.moduleId ^ self.folderId ^ [self getOwnerId];
}


// Make sure the folder name is cleaned up using the same logic on the server side
- (void)setFolderName:(NSString *)folderName {
    // The search list should be identical to that in server API
    NSMutableArray* searchList = [[NSMutableArray alloc] initWithObjects:
                             @"\"", @"`", @"~", @"!", @"@", @"#", @"$", @"%", @"^", @"&", @"*", @"+", @"=", @"<", @">", @"?", @"/", @"\\", @"|"
                             ,nil];

    for (int i=0; i<[searchList count];i++) {
        folderName = [folderName stringByReplacingOccurrencesOfString:searchList[i] withString:@" "];
    }

    _folderName = [NSString compressWhitespaces:folderName];
}

- (NSString*)displayName {
    if (self.folderId == 0) {
        if ([self.accessInfo iAmOwner]) {
            
            if (self.moduleId == CONTACT_MODULE) {
                return NSLocalizedString(@"My contacts",);
                
            } else if (self.moduleId == CALENDAR_MODULE) {
                return NSLocalizedString(@"All events",);
                
            } else if (self.moduleId == DOC_MODULE) {
                return NSLocalizedString(@"My docs",);
                
            } else if (self.moduleId == PHOTO_MODULE) {
                return NSLocalizedString(@"My photos",);
                
            } else if (self.moduleId == BOOKMARK_MODULE) {
                return NSLocalizedString(@"My bookmarks",);
            }
        } else {
            return [self.accessInfo.owner getDisplayName];
        }
        
    }
    
    return self.folderName;
}

- (int)getOwnerId {
    if (self.accessInfo != nil && self.accessInfo.owner != nil) {
        return self.accessInfo.owner.userId;
    }
    return 0;
}

- (NSString*)colorLabel {
    if (_colorLabel == nil) {
        return @"#336699";
    }
    return _colorLabel;
}

- (id)copyWithZone:(NSZone *)zone
{
    NPFolder *newFolder = [[NPFolder allocWithZone:zone] init];
    newFolder.moduleId = self.moduleId;
    newFolder.folderId = self.folderId;

    if (self.folderCode != nil) {
        newFolder.folderCode = [NSString stringWithFormat:@"%@", self.folderCode];
    }
    
    if (self.folderName != nil) {
        newFolder.folderName = [NSString stringWithFormat:@"%@", self.folderName];
    }
    
    if (self.colorLabel != nil) {
        newFolder.colorLabel = [NSString stringWithFormat:@"%@", self.colorLabel];
    }

    newFolder.parentId = self.parentId;
    newFolder.previousParentId = self.previousParentId;
    newFolder.subFolders = [NSArray arrayWithArray:self.subFolders];
    
    if (self.accessInfo != nil) {
        newFolder.accessInfo = [self.accessInfo copy];
    } else {
        newFolder.accessInfo = [[AccessEntitlement alloc] init];
    }
    
    return newFolder;
}

- (void)addSubFolder:(NPFolder*)subFolder {
    if (subFolder.parentId == self.folderId) {
        NSMutableArray *tmpFolders = [NSMutableArray arrayWithArray:self.subFolders];
        [tmpFolders addObject:[subFolder copy]];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folderName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];

        self.subFolders = [tmpFolders sortedArrayUsingDescriptors:sortDescriptors];
    }
}

- (void)deleteSubFolder:(NPFolder*)folderToDelete {
    NSMutableArray *newSubFolders = [[NSMutableArray alloc] init];
    for (NPFolder *aFolder in self.subFolders) {
        if (aFolder.folderId != folderToDelete.folderId) {
            [newSubFolders addObject:[aFolder copy]];
        }
    }
    self.subFolders = [NSArray arrayWithArray:newSubFolders];
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:4];
    [params setObject:[NSString stringWithFormat:@"%i", self.moduleId] forKey:MODULE_ID];
    
    if (self.folderId > 0) {
        [params setObject:[NSString stringWithFormat:@"%i", self.folderId] forKey:FOLDER_ID];
    }
    
    [params setObject:[NSString stringWithFormat:@"%i", self.parentId] forKey:FOLDER_PARENT_ID];
    [params setObject:self.folderName forKey:FOLDER_NAME];
    
    if (self.sharings.count > 0) {
        NSMutableArray *sharingsArr = [[NSMutableArray alloc] initWithCapacity:[self.sharings count]];
        for (AccessPermission *access in self.sharings) {
            NSDictionary *shareToInfo = [access toDictionary];
            if (shareToInfo != nil) {
                [sharingsArr addObject:[access toDictionary]];
            }
        }
        [params setValue:[NSString convertDataToJsonString:sharingsArr] forKey:SHARINGS_DETAIL];
    }
    
    return params;
}

+ (id)initRootFolder:(int)forModule  accessInfo:(AccessEntitlement*)accessInfo {
    NPFolder *newFolder = [[NPFolder alloc] init];
    newFolder.accessInfo = [accessInfo copy];
    newFolder.moduleId = forModule;
    newFolder.folderId = ROOT_FOLDER;
    newFolder.parentId = -1;
    newFolder.folderCode = @"home";
    switch (forModule) {
        case 1:
            newFolder.folderName = NSLocalizedString(@"My contacts",);
            break;
        case 2:
            newFolder.folderName = NSLocalizedString(@"All my events",);
            break;
        case 3:
            newFolder.folderName = NSLocalizedString(@"My bookmarks",);
            break;
        case 4:
            newFolder.folderName = NSLocalizedString(@"My docs",);
            break;
        case 6:
            newFolder.folderName = NSLocalizedString(@"My photos",);
            break;
        default:
            break;
    }
    return newFolder;
}

+ (NPFolder*)folderFromDictionary:(NSDictionary*)folderDict {
    NPFolder *f = [[NPFolder alloc] init];
    f.moduleId = [[folderDict valueForKey:MODULE_ID] intValue];
    f.folderId = [[folderDict objectForKey:FOLDER_ID] intValue];
    f.folderName = [[folderDict valueForKey:FOLDER_NAME] copy];
    f.folderCode = [[folderDict valueForKey:FOLDER_CODE] copy];
    f.parentId = [[folderDict valueForKey:FOLDER_PARENT_ID] intValue];
    
    if ([folderDict objectForKeyNotNull:ENTRY_STATUS]) {
        f.status = [[folderDict valueForKey:ENTRY_STATUS] intValue];
    }
    
    if ([folderDict objectForKeyNotNull:ENTRY_COLOR_LABEL]) {
        f.colorLabel = [folderDict valueForKey:ENTRY_COLOR_LABEL];
    }

    // Build access info
    if ([folderDict objectForKey:ACCESS_INFO] != nil) {
        f.accessInfo = [[AccessEntitlement alloc] initWithDictInfo:[folderDict objectForKey:ACCESS_INFO]];
    }
    
    // Get the sharing information
    if ([folderDict objectForKey:SHARINGS_DETAIL] != nil) {
        NSArray *sharersArr = [folderDict objectForKey:SHARINGS_DETAIL];
        
        NSMutableArray *accessPermissions = [[NSMutableArray alloc] init];

        for (NSDictionary *sharerInfo in sharersArr) {
            NSString *receiverKey = [sharerInfo valueForKey:SHARING_ACCESSOR_KEY];
            if (receiverKey.length > 0 && ![receiverKey isEqualToString:@"public"]) {
                AccessPermission *accessPermission = [[AccessPermission alloc] init];
                
                NPUser *accessor = [[NPUser alloc] init];
                accessor.userId = [[sharerInfo valueForKey:SHARING_ACCESSOR_ID] intValue];
                accessor.email = [NSString stringWithFormat:@"%@", receiverKey];
                
                if ([sharerInfo valueForKey:CONTACT_FIRST_NAME] != nil) {
                    accessor.firstName = [sharerInfo valueForKey:CONTACT_FIRST_NAME];
                }

                if ([sharerInfo valueForKey:CONTACT_LAST_NAME] != nil) {
                    accessor.lastName = [sharerInfo valueForKey:CONTACT_LAST_NAME];
                }

                accessPermission.accessor = accessor;

                if ([sharerInfo objectForKeyNotNull:ACCESS_INFO_WRITE] && [[sharerInfo valueForKey:ACCESS_INFO_WRITE] isEqualToString:@"1"]) {
                    accessPermission.write = YES;
                }

                accessPermission.read = YES;
                [accessPermissions addObject:accessPermission];
            }
        }

        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"getSortKey" ascending:YES];
        NSArray *sortedArr = [accessPermissions sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        
        f.sharings = [NSMutableArray arrayWithArray:sortedArr];
    }
    
    return f;
}

- (NSString *)uniqueKey {
    return [NSString stringWithFormat:@"%d-%d", self.accessInfo.owner.userId, self.folderId];;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"module:%d, folder:%d, name:%@, parent:%i, subfolders:[%@], sharers:[%@]",
            self.moduleId, self.folderId, self.folderName, self.parentId, [self.subFolders description], self.sharings];
}

@end
