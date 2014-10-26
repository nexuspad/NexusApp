//
//  FolderUpdaterControllerDelegate.h
//  nexuspad
//
//  Created by Ren Liu on 8/22/12.
//
//

#import <Foundation/Foundation.h>

@protocol FolderUpdaterControllerDelegate <NSObject>

- (void)didAddedFolder:(NPFolder*)folder;
- (void)didUpdatedFolder:(NPFolder*)folder;
- (void)didMovedFolder:(NPFolder*)folder;
- (void)didDeletedFolder:(NPFolder*)folder;

@end
