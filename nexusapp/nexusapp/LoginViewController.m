//
//  AccountViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginViewController.h"
#import "DashboardController.h"
#import "AccountManager.h"
#import "NSString+NPStringUtil.h"
#import "ViewDisplayHelper.h"
#import "SyncDownService.h"


@interface LoginViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *resetPasswordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *signInCell;
@end

@implementation LoginViewController
@synthesize loginTextField;
@synthesize passTextField;


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.loginTextField becomeFirstResponder];
    
    self.loginTextField.delegate = self;
    self.passTextField.delegate = self;
    
    self.signInCell.textLabel.text = NSLocalizedString(@"Sign in",);
    self.signInCell.textLabel.textAlignment = NSTextAlignmentRight;
    
    self.resetPasswordCell.textLabel.text = NSLocalizedString(@"Request password reset",);
    self.resetPasswordCell.textLabel.textAlignment = NSTextAlignmentRight;
}

- (void)viewDidUnload
{
    [self setLoginTextField:nil];
    [self setPassTextField:nil];
    [self setSignInCell:nil];
    [super viewDidUnload];
}

- (IBAction)cancelLogin:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2) {
        [self signIn:nil];
        
    } else if (indexPath.row == 3) {
        [self resetPassword];
    }
}

- (void)signIn:(id)sender
{
    NSString *login = self.loginTextField.text;
    NSString *pass = self.passTextField.text;
    
    if ([NSString isBlank:login] || [NSString isBlank:pass]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Login failed. Please provide both user name/email and password.",) delegate:self cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        [self.view endEditing:YES];
        [self resignFirstResponder];

        [ViewDisplayHelper displayWaiting:self.view messageText:NSLocalizedString(@"Logging in...",)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                Account *acct = [[AccountManager instance] login:login password:pass];
                [ViewDisplayHelper dismissWaiting:self.view];
                
                if (acct.sessionId != nil) {
                    [[SyncDownService instance] start];

                    DashboardController *dashboard = [self.storyboard instantiateViewControllerWithIdentifier:@"DashboardView"];
                    [self.navigationController setViewControllers:[NSArray arrayWithObject:dashboard] animated:YES];

                } else {
                    
                    // Deselect the sign in row
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                    NSString *failReason;
                    if ([acct.errorCode intValue] == LOGIN_NO_USER) {
                        failReason = NSLocalizedString(@"Login failed. The account does not exist",);
                    } else if ([acct.errorCode intValue] == LOGIN_ACCT_PROBLEM) {
                        failReason = NSLocalizedString(@"Login failed due to account problem. Please email help@nexuspad.com.",);
                    } else {
                        failReason = NSLocalizedString(@"Login failed. Your password does not match what we have.",);
                    }
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:failReason delegate:self cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
                    [alert show];
                }
            });
        });
    }
}


- (void)resetPassword {
    NSString *email = self.loginTextField.text;
    
    if ([NSString isBlank:email] || ![NSString isValidEmail:email]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"Please provide a valid email address",)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        [self.view endEditing:YES];
        [self resignFirstResponder];
        
        [ViewDisplayHelper displayWaiting:self.view messageText:NSLocalizedString(@"Sending request...",)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[AccountManager instance] resetPassword:email];
                [ViewDisplayHelper dismissWaiting:self.view];

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Please check your inbox for instructions to reset your password."
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Close",)
                                                      otherButtonTitles:nil];
                [alert show];
            });
        });
    }
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.loginTextField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.loginTextField) {
        [self.passTextField becomeFirstResponder];
    } else if (theTextField == self.passTextField) {
        [self signIn:nil];
    }

    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end
