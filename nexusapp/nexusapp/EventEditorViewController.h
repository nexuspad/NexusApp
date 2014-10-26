//
//  EventEditorViewControllerViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntryEditorTableViewController.h"
#import "InputDateSelectorView.h"
#import "NPEvent.h"

@interface EventEditorViewController : EntryEditorTableViewController <DateSelectedDelegate>

@property (nonatomic, strong) NPEvent *event;

@end
