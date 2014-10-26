//
//  FeatureDetailViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPPerson.h"
#import "EntryEditorUpdateDelegate.h"

@interface AddressEditorViewController : UITableViewController

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> entryUpdateDelegate;

- (IBAction)cancelAddress:(id)sender;
- (IBAction)doneAddress:(id)sender;

@end
