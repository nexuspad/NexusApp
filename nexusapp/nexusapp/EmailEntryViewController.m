//
//  EmailEntryViewController.m
//  nexuspad
//
//  Created by Ren Liu on 9/9/12.
//
//
#import "NPModule.h"

#import "EmailEntryViewController.h"
#import "TextViewWithPlaceHolder.h"
#import "NSString+NPStringUtil.h"
#import "ViewDisplayHelper.h"
#import "NPMessage.h"
#import "ActionResult.h"
#import "AddUserAutoCompletionHelper.h"

@interface EmailEntryViewController ()
@property (nonatomic, strong) EntryService *entryService;
@property (nonatomic, strong) AddUserAutoCompletionHelper *addUserACHelper;

@property (weak, nonatomic) IBOutlet UITableViewCell *emailTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *messageTableViewCell;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet TextViewWithPlaceHolder *messageTextView;
@end

@implementation EmailEntryViewController

@synthesize theEntry;
@synthesize emailTableViewCell;
@synthesize messageTableViewCell;
@synthesize emailTextField;
@synthesize messageTextView;


- (IBAction)send:(id)sender {
    NSString *email = self.emailTextField.text;

    if ([NSString isValidEmail:email]) {        
        if (self.entryService == nil) {
            self.entryService = [[EntryService alloc] init];
            self.entryService.serviceDelegate = self;
        }
        
        NPMessage *message = [[NPMessage alloc] init];
        [message addEmailAddress:email];

        if (![NSString isBlank:self.messageTextView.text]) {
            message.messageBody = self.messageTextView.text;
        }
        [self.entryService emailEntry:self.theEntry message:message];
        [ViewDisplayHelper displayWaiting:self.view messageText:NSLocalizedString(@"Sending...",)];

    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Invalid email address.",) delegate:self cancelButtonTitle:NSLocalizedString(@"Close",) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)serviceError:(ServiceResult*)serviceResult {
    if (serviceResult.code == NP_WEB_SERVICE_NOT_AVAILABLE) {
        // No need to report the error here.
        return;
    }

    NSString *message = NSLocalizedString(@"There is an error emailing the entry.",);
    if (serviceResult.message.length > 0) {
        message = [serviceResult.message copy];
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [alert show];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return self.emailTableViewCell;
    } else if (indexPath.row == 1) {
        return self.messageTableViewCell;
    }
    
    return nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = [NPModule emailModuleEntry:self.theEntry];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.messageTextView.placeholder = NSLocalizedString(@"Message",);
    self.messageTextView.text = @"";

    self.emailTextField.delegate = self;
    [self.emailTextField becomeFirstResponder];
    
    self.addUserACHelper = [[AddUserAutoCompletionHelper alloc] initWithTextField:self.emailTextField];
}

- (void)viewDidUnload
{
    [self setEmailTextField:nil];
    [self setMessageTextView:nil];
    [self setEmailTableViewCell:nil];
    [self setMessageTableViewCell:nil];
    [super viewDidUnload];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    if (theTextField == self.emailTextField) {
        [self.messageTextView becomeFirstResponder];
        return NO;
    }    
    return YES;
}

@end
