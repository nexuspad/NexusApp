//
//  TestViewController.m
//  nexusapp
//
//  Created by Ren Liu on 11/27/13.
//
//

#import "TestViewController.h"
#import "NPModule.h"
#import "NPUser.h"
#import "NPFolder.h"
#import "AccessEntitlement.h"
#import "FolderUpdaterController.h"

@implementation TestViewController

+ (UIViewController*)testFolderUpdateViewController {
    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    
    NPUser *user = [[AccountManager instance] currentLoginAcct];
    AccessEntitlement *accessInfo = [[AccessEntitlement alloc] initWithOwnerAndViewer:user theViewer:user];
    NPFolder *folder = [[NPFolder alloc] initWithModuleAndFolderId:4 folderId:177 accessInfo:accessInfo];
    FolderUpdaterController *folderUpdateController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderUpdateView"];
    folderUpdateController.currentFolder = folder;
    
    return folderUpdateController;
}

+ (UIViewController*)testFolderViewController {
    [NPService setServiceSpeed:wifi];

    UIStoryboard *folderStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_folder" bundle:nil];
    
    FolderViewController *folderViewController = [folderStoryBoard instantiateViewControllerWithIdentifier:@"FolderView"];
    
    NPUser *owner = [[NPUser alloc] init];
    owner.userId = 41;

    AccessEntitlement *access = [[AccessEntitlement alloc] initWithOwnerAndViewer:owner theViewer:[[AccountManager instance] currentLoginAcct]];
    NPFolder *folder = [[NPFolder alloc] initWithModuleAndFolderId:BOOKMARK_MODULE folderId:ROOT_FOLDER accessInfo:access];
    
    // The moduleId and accessInfo must be set here
    [folderViewController showFolderTree:folder];
    
    return folderViewController;
}

@end
