//
//  ContactEditorController.h
//  nexuspad
//
//  Created by Ren Liu on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryEditorTableViewController.h"
#import "PhotoHelper.h"

@interface ContactEditorViewController : EntryEditorTableViewController <PhotoHelperDelegate>

@property (nonatomic, strong) NPPerson *person;

// EntryEditorUpdateDelegate method
- (void)updateContactAddress:(NPPerson*)person;

- (IBAction)saveContact:(id)sender;

@end
