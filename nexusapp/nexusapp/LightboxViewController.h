//
//  LightboxViewController.h
//  nexuspad
//
//  Created by Ren Liu on 6/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPPhoto.h"
#import "EntryLightboxViewDelegate.h"
#import "EntryEditorUpdateDelegate.h"
#import "EntryViewInfoDelegate.h"
#import "EntryService.h"
#import "NPScrollView.h"
#import "FolderViewController.h"


@interface LightboxViewController : UIViewController <UIScrollViewDelegate,
                                                    UIGestureRecognizerDelegate,
                                                    UIActionSheetDelegate,
                                                    NPDataServiceDelegate,
                                                    EntryViewInfoDelegate,
                                                    NPScrollViewPageDataDelegate,
                                                    FolderViewControllerDelegate>

@property BOOL isAlbumPhoto;

@property (nonatomic, strong) id<EntryLightboxViewDelegate> navigationDelegate;

@property (nonatomic, strong) NPScrollIndex *scrollIndex;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) NPScrollView *photoScrollView;

- (IBAction)deleteEntry:(id)sender;

@end
