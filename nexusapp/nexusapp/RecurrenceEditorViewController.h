//
//  RecurrenceEditorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LayoutConstants.h"
#import "Recurrence.h"
#import "InputValueSelectedDelegate.h"
#import "EntryEditorUpdateDelegate.h"

@interface RecurrenceEditorViewController : UITableViewController

@property (nonatomic, strong) Recurrence *recurrence;

@property (nonatomic, strong) id<InputValueSelectedDelegate> delegate;

@property (nonatomic, strong) id<EntryEditorUpdateDelegate> entryUpdateDelegate;

@end
