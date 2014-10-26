//
//  FolderService.h
//  nexuspad
//
//  Created by Ren Liu on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPWebApiService.h"
#import "FolderStore.h"
#import "NPFolder.h"
#import "NPUser.h"
#import "AccessPermission.h"
#import "UserManager.h"

@interface FolderService : NPWebApiService <FolderStoreDelegate>

@property int moduleId;
@property (nonatomic, strong) AccessEntitlement *accessInfo;

- (void)getAllFolders:(AccessEntitlement*)accessInfo;
- (void)getFolderDetail:(NPFolder*)folder;

- (void)addOrUpdateFolder:(NPFolder*)folder;
- (void)moveFolder:(NPFolder*)folder parentFolder:(NPFolder*)parentFolder;
- (void)deleteFolder:(NPFolder*)folder;

// Stop sharing request from accessor
- (void)stopSharing:(int)moduleId fromUser:(NPUser*)fromUser;
- (void)stopSharingFolder:(NPFolder*)folder toMe:(NPUser*)toMe;

// Update sharing for an accessor - add, update permission, delete
- (void)updateSharing:(NPFolder*)folder accessPermission:(AccessPermission*)accessPermission;

/*
 * Web service section
 */
@property (nonatomic, weak) id<NPDataServiceDelegate> serviceDelegate;

@end
