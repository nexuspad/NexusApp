//
//  AttendeeEditorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPEvent.h"
#import "EntryEditorUpdateDelegate.h"

@interface AttendeeEditorViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> entryUpdateDelegate;

- (IBAction)cancelAttendee:(id)sender;
- (IBAction)doneAttendee:(id)sender;

@end
