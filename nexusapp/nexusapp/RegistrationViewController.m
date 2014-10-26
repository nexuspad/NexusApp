//
//  RegistrationViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RegistrationViewController.h"
#import "WebPageViewController.h"
#import "NSString+NPStringUtil.h"
#import "Account.h"
#import "AccountManager.h"
#import "ViewDisplayHelper.h"
#import "StartViewController.h"
#import "DashboardController.h"


@interface RegistrationViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) Account *acct;
@end

@implementation RegistrationViewController
@synthesize passwordTextField;
@synthesize emailTextField;
@synthesize firstNameTextField;
@synthesize lastNameTextField;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.emailTextField becomeFirstResponder];
    self.emailTextField.delegate = self;
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;    
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setFirstNameTextField:nil];
    [self setLastNameTextField:nil];
    [self setPasswordTextField:nil];
    [super viewDidUnload];
}

- (IBAction)cancelRegistration:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)signUp:(id)sender {
    Account *newAcct = [[Account alloc] init];
    
    newAcct.email = self.emailTextField.text;
    newAcct.password = self.passwordTextField.text;
    newAcct.firstName = self.firstNameTextField.text;
    newAcct.lastName = self.lastNameTextField.text;
    
    NSTimeZone *localTimezone = [NSTimeZone systemTimeZone];
    [newAcct setTimezoneStr:[localTimezone name]];
    
    if ([NSString isBlank:newAcct.email] || [NSString isBlank:newAcct.password] ||
        [NSString isBlank:newAcct.firstName] || [NSString isBlank:newAcct.lastName])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"All fields are required.",) delegate:self cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
        [alert show];
        
    } else {

        [self.view endEditing:YES];
        [ViewDisplayHelper displayWaiting:self.view messageText:NSLocalizedString(@"Please wait...",)];
        
        dispatch_queue_t prepareAssetQ = dispatch_queue_create("Create new account", NULL);
        dispatch_async(prepareAssetQ, ^{
            
            self.acct = [[AccountManager instance] createAccount:newAcct];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [ViewDisplayHelper dismissWaiting:self.view];

                if (self.acct.sessionId != nil) {
                    DashboardController *dashboard = [self.storyboard instantiateViewControllerWithIdentifier:@"DashboardView"];
                    [self.navigationController setViewControllers:[NSArray arrayWithObject:dashboard] animated:YES];

                } else {

                    NSString *failReason;
                    if ([self.acct.errorCode intValue] == FAILED_REGISTRATION_ACCT_EXIST) {
                        failReason = NSLocalizedString(@"Registration failed. The account already exists.",);
                    } else {
                        failReason = NSLocalizedString(@"Registration failed. Please try again later.",);
                    }

                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:failReason delegate:self cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
                    [alert show];
                }

            });
        });
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.emailTextField) {
        [self.emailTextField becomeFirstResponder];
    
    } else if (theTextField == self.firstNameTextField) {
        [self.firstNameTextField becomeFirstResponder];

    } else if (theTextField == self.lastNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
        
    } else if (theTextField == self.lastNameTextField) {
        [self signUp:nil];
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenTOU"]) {
        [segue.destinationViewController setPageUrl:@"/page/termsofuse"];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
@end
