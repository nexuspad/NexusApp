//
//  AccountViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate>

- (IBAction)cancelLogin:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passTextField;

@end
