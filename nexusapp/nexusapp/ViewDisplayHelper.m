//
//  ViewDisplayCenter.m
//  nexuspad
//
//  Created by Ren Liu on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ViewDisplayHelper.h"
#import "LoadingOverlayView.h"
#import "MessageView.h"
#import "UIColor+NPColor.h"
#import "DashboardController.h"
#import "DoAlertView.h"

@implementation ViewDisplayHelper

static LoadingOverlayView *loader = nil;

+ (void)displayOutOfSpaceMessage {
    [ViewDisplayHelper displayWarningMessage:NSLocalizedString(@"The account is out of space",)
                                     message:NSLocalizedString(@"Please upgrade or empty the recycle bin to free up more space.",)];    
}

+ (void)displayWarningMessage:(NSString*)title message:(NSString*)message {
    DoAlertView *doAlert = [[DoAlertView alloc] init];
    doAlert.nAnimationType = DoTransitionStylePop;
    doAlert.dRound = 5.0;
    
    [doAlert doYes:title
              body:message
               yes:^(DoAlertView *alertView) {
               }];
}

+ (void)displayWaiting:(UIView*)targetView messageText:(NSString*)messageText {
    if (loader == nil) {
        loader = [[LoadingOverlayView alloc] init];
    }
    
    [loader show:targetView];
}

+ (void)dismissWaiting:(UIView*)targetView
{
    for (UIView *subview in [targetView subviews]) {
        if ([subview isKindOfClass:[LoadingOverlayView class]]) {
            [subview removeFromSuperview];
        }
    }
}

+ (BOOL)is4InchDisplay {
    return [UIScreen mainScreen].bounds.size.height == 568.0f &&
           [UIScreen mainScreen].scale == 2.f &&
            UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

// This should be replaced with autolayout in the future.
+ (CGRect)contentViewRect:(float)offsetY heightAdjustment:(float)heightAdjustment {
    CGRect rect;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            CGSize size = [self sizeInOrientation:orientation];
            rect = CGRectMake(0, 0, size.width, size.height - 88.0);
            
        } else if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationUnknown) {
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                CGSize size = [self sizeInOrientation:orientation];
                rect = CGRectMake(0, 0, size.width, size.height);
            } else {
                CGSize size = [self sizeInOrientation:orientation];
                rect = CGRectMake(0, 0, size.width, size.height);
            }
            
        } else {
            CGSize size = [self sizeInOrientation:orientation];
            rect = CGRectMake(0, 0, size.width, size.height);
        }
        
        rect.origin.y = offsetY;

    } else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            CGSize size = [self sizeInOrientation:orientation];
            rect = CGRectMake(0, 0, size.width, size.height - 88.0);
            
        } else if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationUnknown) {
            if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                CGSize size = [self sizeInOrientation:orientation];
                rect = CGRectMake(0, 0, size.width, size.height - 88.0);
            } else {
                CGSize size = [self sizeInOrientation:orientation];
                rect = CGRectMake(0, 0, size.width, size.height - 64.0);
            }
            
        } else {
            CGSize size = [self sizeInOrientation:orientation];
            rect = CGRectMake(0, 0, size.width, size.height - 64.0);
        }

        rect.origin.y = offsetY;
        rect.size.height += heightAdjustment;
    }

    return rect;
}


+ (CGRect)fullScreenViewRect {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        CGSize size = [self sizeInOrientation:orientation];
        return CGRectMake(0, 20, size.width, size.height);
        
    } else {
        CGSize size = [self sizeInOrientation:orientation];
        return CGRectMake(0, 20, size.width, size.height);
    }
}

// Height does not include status bar
+ (CGFloat)screenHeight {
    CGSize size = [self sizeInOrientation:[UIDevice currentDevice].orientation];
    return size.height;
}

+ (CGFloat)screenWidth {
    CGSize size = [self sizeInOrientation:[UIDevice currentDevice].orientation];
    return size.width;
}

+ (CGFloat)offsetYPosition {
    CGSize size = [self sizeInOrientation:[UIDevice currentDevice].orientation];
    if (size.width > size.height) {
        return size.width + 50.0;
    } else {
        return size.height + 50.0;
    }
}

//+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
//    CGSize size = [UIScreen mainScreen].bounds.size;
//    UIApplication *application = [UIApplication sharedApplication];
//    if (UIInterfaceOrientationIsLandscape(orientation))
//    {
//        size = CGSizeMake(size.height, size.width);
//    }
//    if (application.statusBarHidden == NO)
//    {
//        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
//    }
//    return size;
//}

+ (CGSize)sizeInOrientation:(UIDeviceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

+ (UITableViewCell*)loadMoreCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadMoreRow"];
    
    cell.textLabel.text = @"Scroll to load more";
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
    
    return cell;
}

+ (CGSize)getInputViewSize {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGSizeMake(320.0, 260.0);
    }
    
    return CGSizeMake(320.0, 260.0);
}

+ (UIView *)emptyViewFiller {
    static UILabel *emptyLabel = nil;
    if (!emptyLabel) {
        emptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        emptyLabel.backgroundColor = [UIColor clearColor];
    }
    return emptyLabel;
}

+ (CGRect)offScreen {
    return CGRectMake(0.0f, 480.0f, 320.0f, 304.0f);
}

+ (void)prettifyIcon:(UIImageView*)origImageView {
    origImageView.layer.shadowColor = [[UIColor blackColor] CGColor];
    origImageView.layer.shadowOffset = CGSizeMake(0, 1.5);
    origImageView.layer.shadowOpacity = 0.4;
}

+ (void)addBottomBorder:(UIView *)view {
    CALayer* layer = [view layer];
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.borderColor = [UIColor darkGrayColor].CGColor;
    bottomBorder.borderWidth = 1;
    bottomBorder.frame = CGRectMake(-1, layer.frame.size.height-1, layer.frame.size.width, 1);
    [bottomBorder setBorderColor:[UIColor lightGrayColor].CGColor];
    [layer addSublayer:bottomBorder];
}

+ (void)pushViewControllerBottomUp:(UINavigationController*)navigationController viewController:(UIViewController*)viewController {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionMoveIn; //kCATransitionFade; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromTop; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [navigationController.view.layer addAnimation:transition forKey:nil];
    
    [navigationController pushViewController:viewController animated:NO];
}

+ (void)popViewControllerBottomDown:(UINavigationController*)navigationController {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromBottom; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [navigationController.view.layer addAnimation:transition forKey:nil];
    [navigationController popViewControllerAnimated:NO];
}

+ (BOOL)interfaceOrientationDiffersFromDeviceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    /*
     -- interface --
     UIInterfaceOrientationPortrait = UIDeviceOrientationPortrait,
     UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
     UIInterfaceOrientationLandscapeLeft = UIDeviceOrientationLandscapeRight,
     UIInterfaceOrientationLandscapeRight = UIDeviceOrientationLandscapeLeft
     
     -- device --
     UIDeviceOrientationUnknown - Can't be determined
     UIDeviceOrientationPortrait - Home button facing down
     UIDeviceOrientationPortraitUpsideDown - Home button facing up
     UIDeviceOrientationLandscapeLeft - Home button facing right
     UIDeviceOrientationLandscapeRight - Home button facing left
     UIDeviceOrientationFaceUp - Device is flat, with screen facing up
     UIDeviceOrientationFaceDown - Device is flat, with screen facing down
     */
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    
//    DLog(@"............%ld..............current interface orientation. device..................%ld.............", interfaceOrientation
//         , deviceOrientation);
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
            if (interfaceOrientation != UIInterfaceOrientationPortrait) {
                return YES;
            }
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            if (interfaceOrientation != UIInterfaceOrientationLandscapeLeft) {
                return YES;
            }
        case UIDeviceOrientationLandscapeRight:
            if (interfaceOrientation != UIInterfaceOrientationLandscapeRight) {
                return YES;
            }
            break;
            
        default:        // All others: UIDeviceOrientationUnknown, UIDeviceOrientationFaceUp, UIDeviceOrientationFaceDown
            return NO;
    }
    
    return NO;
}

@end
