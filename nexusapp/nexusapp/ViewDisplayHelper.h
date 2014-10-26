//
//  ViewDisplayCenter.h
//  nexuspad
//
//  Created by Ren Liu on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface ViewDisplayHelper : NSObject

+ (void)displayOutOfSpaceMessage;

+ (void)displayWarningMessage:(NSString*)title message:(NSString*)message;

+ (void)displayWaiting:(UIView*)targetView messageText:(NSString*)messageText;
+ (void)dismissWaiting:(UIView*)targetView;

+ (BOOL)is4InchDisplay;

+ (CGRect)contentViewRect:(float)offsetY heightAdjustment:(float)heightAdjustment;
+ (CGRect)fullScreenViewRect;

+ (CGFloat)screenWidth;
+ (CGFloat)screenHeight;
+ (CGFloat)offsetYPosition;

+ (UITableViewCell*)loadMoreCell;

+ (CGSize)getInputViewSize;

+ (UIView *)emptyViewFiller;

+ (CGRect)offScreen;

+ (void)prettifyIcon:(UIImageView*)origImageView;

+ (void)addBottomBorder:(UIView*)view;

+ (void)pushViewControllerBottomUp:(UINavigationController*)navigationController viewController:(UIViewController*)viewController;
+ (void)popViewControllerBottomDown:(UINavigationController*)navigationController;

+ (BOOL)interfaceOrientationDiffersFromDeviceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end
