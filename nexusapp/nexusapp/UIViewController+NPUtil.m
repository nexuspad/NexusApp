//
//  UIViewController+NPUtil.m
//  nexuspad
//
//  Created by Ren Liu on 10/7/12.
//
//

#import "UIViewController+NPUtil.h"
#import "DashboardController.h"

@implementation UIViewController (NPUtil)

- (void)backToDashboard
{
    BOOL foundDashboard = NO;
    
    // We need to figure out wher the dashboard controller is so we can pop our view to that location.
    // In normal circumstances it is StartViewController -> DashboardViewController
    // But if user has to login in, it becomes StartViewController -> LoginViewController -> DashboardViewController, so
    // we cannot pop to index 1 since it takes user to the login page.
    //
    // If searching through the navigation controller does not find any DashboardViewController, we'll have to create one from
    // storyboard. This really an error condition and should happen than way.
    UIViewController *controller1 = [[self.navigationController viewControllers] objectAtIndex:1];
    if ([controller1 isKindOfClass:[DashboardController class]]) {
        [self.navigationController popToViewController:controller1 animated:YES];
        foundDashboard = YES;
        
    } else {
        for (UIViewController *aController in [self.navigationController viewControllers]) {
            if ([aController isKindOfClass:[DashboardController class]]) {
                [self.navigationController popToViewController:aController animated:YES];
                foundDashboard = YES;
            }
        }
    }
    
    if (!foundDashboard) {
        NSLog(@"Dashboard controller cannot be found in navigation controller stack. Create new one from storyboard.");
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_main" bundle:nil];
        DashboardController *dashboardController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"DashboardView"];
        [self.navigationController pushViewController:dashboardController animated:YES];
    }
}


- (void)openDashboard:(id)sender
{
    //    [UIView beginAnimations:nil context:nil];
    //    [UIView setAnimationDuration:0.5];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    //    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.navigationController.view cache:YES];
    
    BOOL foundDashboard = NO;
    
    // We need to figure out wher the dashboard controller is so we can pop our view to that location.
    // In normal circumstances it is StartViewController -> DashboardViewController
    // But if user has to login in, it becomes StartViewController -> LoginViewController -> DashboardViewController, so
    // we cannot pop to index 1 since it takes user to the login page.
    //
    // If searching through the navigation controller does not find any DashboardViewController, we'll have to create one from
    // storyboard. This really an error condition and should happen than way.
    UIViewController *controller1 = [[self.navigationController viewControllers] objectAtIndex:1];
    if ([controller1 isKindOfClass:[DashboardController class]]) {
        [self.navigationController popToViewController:controller1 animated:YES];
        foundDashboard = YES;
        
    } else {
        for (UIViewController *aController in [self.navigationController viewControllers]) {
            if ([aController isKindOfClass:[DashboardController class]]) {
                [self.navigationController popToViewController:aController animated:YES];
                foundDashboard = YES;
            }
        }
    }
    
    if (!foundDashboard) {
        NSLog(@"Dashboard controller cannot be found in navigation controller stack. Create new one from storyboard.");
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_main" bundle:nil];
        DashboardController *dashboardController = [mainStoryBoard instantiateViewControllerWithIdentifier:@"DashboardView"];
        [self.navigationController pushViewController:dashboardController animated:YES];
    }
    
    //    [UIView commitAnimations];
}
@end
