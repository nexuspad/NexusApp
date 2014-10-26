//
//  FolderService.m
//  nexuspad
//
//  Created by Ren Liu on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h> 

#import "FolderService.h"
#import "NPModule.h"
#import "FolderActionResult.h"
#import "FolderList.h"

@interface FolderService()
@end

@implementation FolderService

@synthesize moduleId = _moduleId;
@synthesize accessInfo = _accessInfo;
@synthesize serviceDelegate = _serviceDelegate;


- (id)init {
    self = [super init];
    if (self) {
        return self;
    }
    
    return self;
}


- (void)getAllFolders:(AccessEntitlement*)accessInfo {
    self.accessInfo = [accessInfo copy];
    
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [NPWebApiService appendOwnerParam:[NSString stringWithFormat:@"%@?AllFolders", [self folderBaseUrl:self.moduleId]]
                                                     ownerId:accessInfo.owner.userId];
        
        [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderList *folderList = [FolderList parseAllFoldersResult:result.body moduleId:self.moduleId];
                
                [self.serviceDelegate updateServiceResult:folderList];
                
                dispatch_queue_t folderStoreQ = dispatch_queue_create("com.nexusapp.FolderService", NULL);
                dispatch_async(folderStoreQ, ^{
                    FolderStore *folderStore = [FolderStore instance:nil];
                    
                    NSMutableArray *folders = [[NSMutableArray alloc] initWithCapacity:folderList.folderDict.count];
                    for (id folderId in [folderList.folderDict allKeys]) {
                        NPFolder *f = [folderList.folderDict objectForKey:folderId];
                        [folders addObject:f];
                    }
                    
                    [folderStore storeFolders:folders];
                });
                
            } else {
                [[FolderStore instance:self] findAllFolders:self.moduleId];
            }
        }];

    } else {
        [[FolderStore instance:self] findAllFolders:self.moduleId];
    }
}


- (void)getFolderDetail:(NPFolder*)folder {
    NSString *urlStr = [NPWebApiService appendOwnerParam:[NSString stringWithFormat:@"%@/%d", [self folderBaseUrl:self.moduleId], folder.folderId]
                                                 ownerId:folder.accessInfo.owner.userId];
    
    [self doGet:urlStr completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
        if (success) {
            NSError *error = nil;
            NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                         options:NSJSONReadingMutableLeaves
                                                                           error:&error];
            
            ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];

            NPFolder *folder = [NPFolder folderFromDictionary:[result.body objectForKey:FOLDER]];
            [self.serviceDelegate updateServiceResult:folder];

        } else {
            
        }
    }];        
}


- (void)addOrUpdateFolder:(NPFolder*)folder {
    folder.synced = NO;
    [[FolderStore instance:nil] storeFolder:folder];
    
    if ([NPService isServiceAvailable]) {
        self.accessInfo = [folder.accessInfo copy];
        
        NSString *urlStr = [NPWebApiService appendOwnerParam:[self folderBaseUrl:folder.moduleId] ownerId:folder.accessInfo.owner.userId];
        
        [self doPost:urlStr parameters:[folder buildParamMap] completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];

                DLog(@"Folder action response:\n%@", actionResult);

                if (actionResult.success) {
                    if ([actionResult.name isEqualToString:ACTION_ADD_FOLDER] || [actionResult.name isEqualToString:ACTION_UPDATE_FOLDER]) {
                        DLog(@"Update data store record upon successful action response");
                        actionResult.folder.synced = YES;
                        [[FolderStore instance:nil] storeFolder:actionResult.folder];
                    }
                    
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];

    } else {
        // No web service available, just return action response.
        FolderActionResult *actionResult = [[FolderActionResult alloc] init];
        actionResult.name = @"update_folder";
        actionResult.success = YES;
        actionResult.folder = folder;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}

- (void)moveFolder:(NPFolder*)folder parentFolder:(NPFolder*)parentFolder {
    folder.synced = NO;
    [[FolderStore instance:nil] storeFolder:folder];
    
    if ([NPService isServiceAvailable]) {
        self.accessInfo = [folder.accessInfo copy];

        NSString *urlStr = [NPWebApiService appendOwnerParam:[NSString stringWithFormat:@"%@", [self folderBaseUrl:folder.moduleId]]
                                                     ownerId:folder.accessInfo.owner.userId];
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:2];
        [params setObject:@"move" forKey:@"action"];
        [params setObject:[NSNumber numberWithInt:folder.folderId] forKey:@"folder_id"];
        [params setObject:[NSNumber numberWithInt:parentFolder.folderId] forKey:@"parent_id"];
        
        [self doPost:urlStr parameters:params completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success == YES) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];

                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];
                
                DLog(@"Folder action response:\n%@", actionResult);

                if (actionResult.success) {
                    DLog(@"Update data store record upon successful action response");
                    actionResult.folder.synced = YES;
                    [[FolderStore instance:nil] storeFolder:actionResult.folder];
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];
        
    } else {
        FolderActionResult *actionResult = [[FolderActionResult alloc] init];
        actionResult.name = @"update_folder";
        actionResult.success = YES;
        actionResult.folder = folder;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}

- (void)deleteFolder:(NPFolder*)folder {
    // Save the folder with "deleted" status
    folder.status = ENTRY_STATUS_DELETED;
    folder.synced = NO;
    [[FolderStore instance:nil] storeFolder:folder];

    if ([NPService isServiceAvailable]) {
        self.accessInfo = [folder.accessInfo copy];

        NSString *urlStr = [NPWebApiService appendOwnerParam:[NSString stringWithFormat:@"%@?folder_id=%i",
                                                              [self folderBaseUrl:folder.moduleId],
                                                              folder.folderId]
                                                            ownerId:folder.accessInfo.owner.userId];
        
        [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];

                DLog(@"Folder action response:\n%@", actionResult);

                if (actionResult.success) {
                    DLog(@"Delete data store record upon successful action response");
                    [[FolderStore instance:nil] deleteFolder:actionResult.folder];
                    
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];

    } else {
        FolderActionResult *actionResult = [[FolderActionResult alloc] init];
        actionResult.name = @"delete_folder";
        actionResult.success = YES;
        actionResult.folder = folder;
        [self.serviceDelegate updateServiceResult:actionResult];
    }
}

// Update the sharing permission (action from sharer)
- (void)updateSharing:(NPFolder*)folder accessPermission:(AccessPermission*)accessPermission {
    if ([NPService isServiceAvailable]) {
        self.accessInfo = [folder.accessInfo copy];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[accessPermission toDictionary]];
        [params setObject:@(folder.folderId) forKey:FOLDER_ID];
        
        NSString *urlStr = [NPWebApiService appendOwnerParam:[self folderSharingUrl:folder.moduleId] ownerId:folder.accessInfo.owner.userId];
        
        [self doPost:urlStr parameters:params completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];
                
                DLog(@"Folder action response:\n%@", actionResult);

                if (actionResult.success) {
                    DLog(@"Update data store record upon successful action response");
                    actionResult.folder.synced = YES;
                    [[FolderStore instance:nil] storeFolder:actionResult.folder];
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];
    }
}


// Stop sharing from accessor
- (void)stopSharing:(int)moduleId fromUser:(NPUser*)fromUser {
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = [NPWebApiService appendOwnerParam:[self folderSharingUrl:moduleId] ownerId:fromUser.userId];
        
        [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];
                
                DLog(@"Folder action response:\n%@", actionResult);
                
                if (actionResult.success) {
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];
    }
}

// Stop sharing a folder
- (void)stopSharingFolder:(NPFolder*)folder toMe:(NPUser*)toMe {
    if ([NPService isServiceAvailable]) {
        NSString *urlStr = nil;
        
        // The urlStr should be something looks like: /doc/folder/234/sharing/2
        if (folder.moduleId == CALENDAR_MODULE) {
            urlStr = [NSString stringWithFormat:@"%@/calendar/calendar/%d/sharing/%d", [[HostInfo current] getApiUrl],
                      folder.folderId, toMe.userId];
        } else {
            urlStr = [NSString stringWithFormat:@"%@/%@/folder/%d/sharing/%d", [[HostInfo current] getApiUrl],
                      [NPModule getModuleCode:folder.moduleId], folder.folderId, toMe.userId];
        }
        
        urlStr = [NPWebApiService appendOwnerParam:urlStr ownerId:folder.accessInfo.owner.userId];
        
        [self doDelete:urlStr parameters:nil completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
            if (success) {
                NSError *error = nil;
                NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:NSJSONReadingMutableLeaves
                                                                               error:&error];
                
                ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
                
                FolderActionResult *actionResult = [[FolderActionResult alloc] initWithData:result.body];
                
                DLog(@"Folder action response:\n%@", actionResult);

                if (actionResult.success) {
                    [self.serviceDelegate updateServiceResult:actionResult];
                }
            }
        }];
    }
}


#pragma mark - folder store delegate
- (void)foldersPulledFromStore:(NSArray *)folders {
    NSMutableDictionary *allFolders = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *parentChildrenMapping = [[NSMutableDictionary alloc] init];
    
    for (NPFolder *f in folders) {
        [allFolders setObject:f forKey:[NSNumber numberWithInt:f.folderId]];
        
        NSMutableArray *subFolderIds = [parentChildrenMapping objectForKey:[NSNumber numberWithInt:f.parentId]];
        if (subFolderIds == nil) {
            subFolderIds = [[NSMutableArray alloc] init];
            [parentChildrenMapping setObject:subFolderIds forKey:[NSNumber numberWithInt:f.parentId]];
        }
        
        [subFolderIds addObject:[NSNumber numberWithInt:f.folderId]];
    }
    
    // Populate the sub folders for each individual folder
    for (id folderId in [allFolders allKeys]) {
        NPFolder *f = [allFolders objectForKey:folderId];
        NSArray *subFolders = [parentChildrenMapping objectForKey:folderId];
        if (subFolders != nil) {
            f.subFolders = [NSArray arrayWithArray:subFolders];
        }
    }
    
    FolderList *folderList = [[FolderList alloc] init];
    folderList.folderDict = allFolders;
    
    // The service delegate is a view controller.
    [self.serviceDelegate updateServiceResult:folderList];
}


// Parse the result and create an array of folders
- (NSMutableArray*)foldersFromResult:(NSDictionary*)folderSvcResult {
    NSMutableArray *folders = [[NSMutableArray alloc] init];          // For data store
    
    NSArray *allFoldersArr = [folderSvcResult objectForKey:FOLDER_LIST];
    
    for (NSDictionary *folderDict in allFoldersArr) {
        NPFolder *f = [NPFolder folderFromDictionary:folderDict];
        
        [folders addObject:f];
    }
    
    return folders;
}

- (NSString*)folderBaseUrl:(int)moduleId {
    if (moduleId == CALENDAR_MODULE) {
        return [NSString stringWithFormat:@"%@/calendar/calendar", [[HostInfo current] getApiUrl]];
    } else {
        return [NSString stringWithFormat:@"%@/%@/folder", [[HostInfo current] getApiUrl], [NPModule getModuleCode:moduleId]];
    }
}


- (NSString*)folderSharingUrl:(int)moduleId {
    if (moduleId == CALENDAR_MODULE) {
        return [NSString stringWithFormat:@"%@/calendar/calendar/sharing", [[HostInfo current] getApiUrl]];
    } else {
        return [NSString stringWithFormat:@"%@/%@/folder/sharing", [[HostInfo current] getApiUrl], [NPModule getModuleCode:moduleId]];
    }
}

@end
