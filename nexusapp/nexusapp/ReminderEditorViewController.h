//
//  ReminderEditorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NPEvent.h"
#import "EntryEditorUpdateDelegate.h"

@interface ReminderEditorViewController : UITableViewController <UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> entryUpdateDelegate;

@property (nonatomic, strong) UIPickerView *reminderOffsetValuePicker;

- (IBAction)cancelReminder:(id)sender;
- (IBAction)doneReminder:(id)sender;

@end
