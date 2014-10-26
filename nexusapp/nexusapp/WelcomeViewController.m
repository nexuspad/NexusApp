//
//  WelcomeViewController.m
//  nexuspad
//
//  Created by Ren Liu on 9/10/12.
//
//

#import "WelcomeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+NPColor.h"
#import "ViewDisplayHelper.h"
#import "Constants.h"

@interface WelcomeViewController ()
@property (strong, nonatomic) IBOutlet UIButton *signInButton;
@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@end

@implementation WelcomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([ViewDisplayHelper is4InchDisplay]) {
        self.view.backgroundColor = [UIColor imageBackground:@"Default-568h@2x.png" onView:self.view];
    } else {
        self.view.backgroundColor = [UIColor imageBackground:@"Default.png" onView:self.view];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.toolbarHidden = YES;
    
    [super viewWillAppear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotate {
    return NO;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end
