//
//  DocUploadViewController.h
//  nexuspad
//
//  Created by Ren Liu on 9/10/12.
//
//

#import <UIKit/UIKit.h>
#import "BaseUploadViewController.h"
#import "FolderViewController.h"

@interface ImportDocUploadViewController : BaseUploadViewController <FolderViewControllerDelegate>

- (void)addFileURLWithDestination:(NSURL*)fileUrl toFolder:(NPFolder*)toFolder;

@end
