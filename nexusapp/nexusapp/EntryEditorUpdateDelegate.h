//
//  EditorSaveDelegate.h
//  nexuspad
//
//  Created by Ren Liu on 7/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPPerson.h"
#import "NPEvent.h"

@protocol EntryEditorUpdateDelegate <NSObject>

@optional
- (void)entryUpdateSaved:(id)entry;

@optional
- (void)entryDeleted:(id)entry;

@optional
- (void)updateContactAddress:(NPLocation*)address;

@optional
- (void)updateContactPhoto:(UIImage*)image;

@optional
- (void)updateEventRecurrence:(Recurrence*)recurrence;

@optional
- (void)updateEventReminder:(NSArray*)reminders;

@optional
- (void)updateEventAttendee:(NSArray*)attendees;

@end
