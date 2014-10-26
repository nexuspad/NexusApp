//
//  FolderList.m
//  NexusAppCore
//
//  Created by Ren Liu on 11/2/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "FolderList.h"

@implementation FolderList

- (void)addUpdateMoveFolder:(NPFolder*)changedFolder {
    // Make sure to reset the previous parent Id before saving the object to data
    NPFolder *copyOfChangedFolder = [changedFolder copy];
    copyOfChangedFolder.previousParentId = -1;
    [self.folderDict setObject:copyOfChangedFolder forKey:[NSNumber numberWithInt:changedFolder.folderId]];
    
    [self setSubFolder:changedFolder];
}

- (void)deleteFolder:(NPFolder*)deletedFolder {
    [self.folderDict removeObjectForKey:[NSNumber numberWithInt:deletedFolder.folderId]];
    
    for (NSNumber *folderIdKey in self.folderDict) {
        NPFolder *f = [self.folderDict objectForKey:folderIdKey];
        if (f.folderId == deletedFolder.parentId) {
            DLog(@"Remove folder %@ from its parent: %@", deletedFolder.folderName, f.folderName);
            NSMutableArray *newSubFolders = [[NSMutableArray alloc] init];
            for (NPFolder *folder in f.subFolders) {
                if (folder.folderId != deletedFolder.folderId) {
                    [newSubFolders addObject:[folder copy]];
                }
            }
            f.subFolders = newSubFolders;
        }
    }
}

- (void)setSubFolder:(NPFolder*)changedFolder {
    for (NSNumber *folderIdKey in self.folderDict) {

        NPFolder *f = [self.folderDict objectForKey:folderIdKey];

        if (f.folderId == changedFolder.parentId) {
            DLog(@"Add folder %@ to its new parent: %@", changedFolder.folderName, f.folderName);
            NSMutableArray *existingSubFolders = [NSMutableArray arrayWithArray:f.subFolders];
            
            if (![existingSubFolders containsObject:changedFolder]) {
                NPFolder *copyOfChangedFolder = [changedFolder copy];
                copyOfChangedFolder.previousParentId = -1;
                [existingSubFolders addObject:copyOfChangedFolder];
                f.subFolders = existingSubFolders;                
            }

        } else if (changedFolder.previousParentId != -1 && f.folderId == changedFolder.previousParentId) {
            DLog(@"Remove folder %@ from its previous parent: %@", changedFolder.folderName, f.folderName);
            NSMutableArray *newSubFolders = [[NSMutableArray alloc] init];
            for (NPFolder *folder in f.subFolders) {
                if (folder.folderId != changedFolder.folderId) {
                    [newSubFolders addObject:[folder copy]];
                }
            }
            f.subFolders = newSubFolders;
        }
    }

}


+ (FolderList*)parseAllFoldersResult:(NSDictionary*)folderSvcResult moduleId:(int)moduleId  {
    NSMutableDictionary *allFolders = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *parentChildrenMapping = [[NSMutableDictionary alloc] init];
    
    NSArray *allFoldersArr = [folderSvcResult objectForKey:FOLDER_LIST];
    
    for (NSDictionary *folderDict in allFoldersArr) {
        NPFolder *f = [NPFolder folderFromDictionary:folderDict];
        
        [allFolders setObject:f forKey:[NSNumber numberWithInt:f.folderId]];
        
        NSMutableArray *subFolders = [parentChildrenMapping objectForKey:[NSNumber numberWithInt:f.parentId]];
        
        if (subFolders == nil) {
            subFolders = [[NSMutableArray alloc] init];
            [parentChildrenMapping setObject:subFolders forKey:[NSNumber numberWithInt:f.parentId]];
        }
        
        [subFolders addObject:f];
    }
    
    // Populate the sub folders for each indidual folder
    for (id folderId in [allFolders allKeys]) {
        NPFolder *f = [allFolders objectForKey:folderId];
        NSArray *subFolders = [parentChildrenMapping objectForKey:folderId];
        if (subFolders != nil) {
            f.subFolders = [NSArray arrayWithArray:subFolders];
        }
    }
    
    FolderList *folderList = [[FolderList alloc] init];
    folderList.moduleId = moduleId;
    folderList.folderDict = allFolders;
    
    return folderList;
}
@end
