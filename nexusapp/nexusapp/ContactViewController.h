//
//  ContactViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntryDetailTableViewController.h"
#import "NPPerson.h"
#import "NoteCell.h"

@interface ContactViewController : EntryDetailTableViewController <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NPPerson *person;

@end
