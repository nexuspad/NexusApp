//
//  NPImagePickerNavigationController.h
//  nexuspad
//
//  Created by Ren Liu on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAssetSelectionDelegate.h"

@protocol NPImagePickerControllerDelegate <NSObject>
- (void)didFinishPickingMediaWithInfo:(NSArray *)info;
- (void)didCancelImagePicker;
- (void)didFinishTakingPhoto:(UIImage*)image metaData:(NSDictionary*)metaData;
@end

@class NPImagePickerNavigationController;

@interface NPImagePickerNavigationController : UINavigationController <ELCAssetSelectionDelegate,
                                                                UINavigationControllerDelegate,
                                                                UIImagePickerControllerDelegate>

@property (nonatomic, weak) id<NPImagePickerControllerDelegate> imagePickerDelegate;

- (void)cancelImagePicker;

@end

