//
//  StartViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StartViewController.h"
#import "DashboardController.h"
#import "WelcomeViewController.h"
#import "TestViewController.h"

@interface StartViewController ()
@end

@implementation StartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationItem.title = @"NexusPad";

    NSString *sessionId = [[AccountManager instance] getSessionId];
    DLog(@"The session id is: %@", sessionId);

    if (sessionId != nil) {
        DashboardController *dashboard = [self.storyboard instantiateViewControllerWithIdentifier:@"DashboardView"];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:dashboard] animated:NO];
        
//        [self.navigationController setViewControllers:[NSArray arrayWithObject:[TestViewController testFolderUpdateViewController]] animated:NO];
        
//        [self.navigationController setViewControllers:[NSArray arrayWithObject:[TestViewController testFolderViewController]] animated:NO];

    } else {
        WelcomeViewController *welcome = [self.storyboard instantiateViewControllerWithIdentifier:@"WelcomeView"];
        [self.navigationController setViewControllers:[NSArray arrayWithObject:welcome] animated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

@end
