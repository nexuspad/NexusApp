//
//  EventViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EventViewController.h"
#import "MapViewController.h"
#import "DateUtil.h"
#import "EventEditorViewController.h"
#import "ReminderViewController.h"
#import "AttendeeViewController.h"
#import "EntryEditorTableViewController.h"
#import "UIColor+NPColor.h"

@interface EventViewController()
@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *startDateCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endDateCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *recurrenceCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *reminderCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *attendeeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *noteCell;
@property BOOL hasTags;
@property BOOL hasNote;
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *colorLabel;
@end

@implementation EventViewController
@synthesize titleCell;
@synthesize locationCell;
@synthesize startDateCell;
@synthesize endDateCell;
@synthesize recurrenceCell;
@synthesize reminderCell;
@synthesize attendeeCell;
@synthesize tagCell;
@synthesize noteCell;

@synthesize event = _event;

// Overwrite EntryViewController method
- (NPEntry*)getCurrentEntry {
    return _event;
}

// Not used
- (void)retrieveEntryDetail {
    [self.eventService getEventDetail:_event];
}

- (void)updateServiceResult:(id)serviceResult
{
    [super updateServiceResult:serviceResult];
    
    if ([serviceResult isKindOfClass:[NPEntry class]]) {
        _event = [NPEvent eventFromEntry:serviceResult];
        
        [self updateEventFields];
        [self.tableView reloadData];

    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        if (actionResponse.success) {
            //
            // Use the notification route so the same logic only appears in handleEntryDeletedNotification
            //
            //
            if ([actionResponse.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                [NotificationUtil sendEntryDeletedNotification:[actionResponse.entries objectAtIndex:0]];
            } else if ([actionResponse.name isEqualToString:ACTION_DELETE_ENTRY]) {
                [NotificationUtil sendEntryDeletedNotification:actionResponse.entry];
            }
        }
    }
}

// This is called in the data service delegate
- (void)setEvent:(NPEvent *)event {
    _event = [event copy];
}

// Overwrite callDeleteService in EntryViewController
- (void)callDeleteService {
    [self.eventService deleteEvent:_event];
    _event.status = ENTRY_STATUS_DELETED;
}

// delegate method
// This is called after successfuly saving the entry in the editor.
- (void)entryUpdateSaved:(NPEvent*)event {
    _event = event;
    [self.tableView reloadData];
}

- (void)updateEventFields {
    self.titleTextLabel.numberOfLines = 0;
    self.titleTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleTextLabel.text = _event.title;
    
    self.locationCell.textLabel.text = _event.location.locationName;
    if (_event.location.fullAddress.length > 0) {
        self.locationCell.detailTextLabel.text = _event.location.fullAddress;
    } else {
        self.locationCell.detailTextLabel.text = nil;
    }
    
    if ([_event.location getAddressStringForMap] != nil) {
        self.locationCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (_event.allDayEvent) {
        self.startDateCell.textLabel.text = NSLocalizedString(@"All day",);
        self.startDateCell.detailTextLabel.text = [DateUtil displayEventWeekdayAndDate:_event.startTime];
        
    } else if (_event.singleTimeEvent) {
        self.startDateCell.textLabel.text = NSLocalizedString(@"When",);
        self.startDateCell.detailTextLabel.text = [DateUtil displayEventWeekdayAndDateAndTime:_event.startTime];
        
    } else if (_event.noStartingTime) {
        self.startDateCell.textLabel.text = NSLocalizedString(@"Date",);
        self.startDateCell.detailTextLabel.text = [DateUtil displayEventWeekdayAndDate:_event.startTime];
        
    } else {
        self.startDateCell.textLabel.text = NSLocalizedString(@"From",);
        self.startDateCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.startDateCell.detailTextLabel.text = [DateUtil displayEventWeekdayAndDateAndTime:_event.startTime];
    }
    
    if (_event.singleTimeEvent == NO && _event.noStartingTime == NO && _event.allDayEvent == NO) {
        self.endDateCell.textLabel.text = NSLocalizedString(@"To",);
        self.endDateCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.endDateCell.detailTextLabel.text = [DateUtil displayEventWeekdayAndDateAndTime:_event.endTime];
        
    }
    
    self.recurrenceCell.textLabel.text = NSLocalizedString(@"Recurrence",);
    NSString *description = [_event.recurrence repeatDescriptionString:YES];
    NSArray *lines = [description componentsSeparatedByString:@"\n"];
    self.recurrenceCell.detailTextLabel.numberOfLines = [lines count];
    self.recurrenceCell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.recurrenceCell.detailTextLabel.text = [_event.recurrence repeatDescriptionString:YES];
    
    if ([_event.reminders count] > 0) {
        Reminder *reminder = [_event.reminders objectAtIndex:0];
        self.reminderCell.detailTextLabel.text = reminder.deliverAddress;
    }
    
    if ([_event.attendees count] > 0) {
        Attendee *attendee = [_event.attendees objectAtIndex:0];
        self.attendeeCell.detailTextLabel.text = [attendee getNameOrEmail];
    }
    
    self.colorLabel.backgroundColor = [UIColor colorFromHexString:_event.colorLabel];
    self.colorLabel.layer.cornerRadius = 15.0;
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return EVENT_SECTIONS;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (indexPath.section == 0 && indexPath.row == 0) {
        return self.titleCell;
        
    } else if (indexPath.section == EVENT_LOCATION_SECTION) {
        return self.locationCell;
    
    } else if (indexPath.section == EVENT_TIME_SECTION) {
        if (indexPath.row == 0) {
            return self.startDateCell;

        } else if (indexPath.row == 1) {
            if (_event.singleTimeEvent == NO && _event.noStartingTime == NO && _event.allDayEvent == NO) {
                return self.endDateCell;
                
            } else {
                return self.recurrenceCell;
            }
            
        } else if (indexPath.row == 2) {
            return self.recurrenceCell;
        }

    } else if (indexPath.section == EVENT_REMINDER_SECTION) {
        self.reminderCell.textLabel.text = NSLocalizedString(@"Reminders",);
        return self.reminderCell;

    } else if (indexPath.section == EVENT_ATTENDEE_SECTION) {
        self.attendeeCell.textLabel.text = NSLocalizedString(@"Attendees",);
        return self.attendeeCell;
              
    } else if (indexPath.section == EVENT_TAG_SECTION) {

        if (indexPath.row == 0 && self.hasTags) {
            self.tagCell.textLabel.text = NSLocalizedString(@"Tags",);
            self.tagCell.detailTextLabel.text = _event.tags;
            return self.tagCell;
        }
        
        if ((indexPath.row == 0 && !self.hasTags) || indexPath.row == 1) {
            self.noteCell.textLabel.text = _event.note;
            [self.noteCell layoutSubviews];
            return self.noteCell;
        }
    }
    
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case EVENT_TITLE_SECTION:
        {
            return 1;
        }
        case EVENT_LOCATION_SECTION:
        {
            if (_event.location != nil && _event.location.locationName.length > 0) {
                return 1;
            }
            return 0;
        }
        case EVENT_TIME_SECTION:
        {
            if (_event.allDayEvent) {
                if (_event.recurrence != nil && _event.recurrence.pattern != norepeat) {
                    return 2;                                   // Date and recurrence
                } else {
                    return 1;                                   // Date only
                }

            } else if (_event.singleTimeEvent || _event.noStartingTime) {
                if (_event.recurrence != nil && _event.recurrence.pattern != norepeat) {
                    return 2;                                   // Date and recurrence
                } else {
                    return 1;                                   // Date only
                }

            } else {
                if (_event.recurrence != nil && _event.recurrence.pattern != norepeat) {
                    return 3;                                   // Date, time and recurrence
                } else {
                    return 2;                                   // Date, time
                }               
            }
        }
        case EVENT_REMINDER_SECTION:
        {
            if (_event.reminders != nil && [_event.reminders count] > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case EVENT_ATTENDEE_SECTION:
        {
            if (_event.attendees != nil && [_event.attendees count] > 0) {
                return 1;
            } else {
                return 0;
            }
        }
        case EVENT_TAG_SECTION:
        {
            int rows = 0;
            if (_event.tags.length > 0) {
                self.hasTags = YES;
                rows++;
            } else {
                self.hasTags = NO;
            }
            if (_event.note.length > 0) {
                rows++;
                self.hasNote = YES;
            } else {
                self.hasNote = NO;
            }
            return rows;
        }
        default:
            break;
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == EVENT_LOCATION_SECTION && indexPath.row == 0 && [_event.location getAddressStringForMap] != nil) {
        [self performSegueWithIdentifier:@"OpenMap" sender:self];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case EVENT_TAG_SECTION:
        {
            float cellHeight = 0;
            
            if (indexPath.row == 0 && self.hasTags) {
                cellHeight = self.tagCell.frame.size.height;
            }
            if ((indexPath.row == 0 && !self.hasTags) || indexPath.row == 1) {
                self.noteCell.textLabel.text = _event.note;
                [self.noteCell layoutSubviews];
                cellHeight += self.noteCell.contentView.frame.size.height;
            }
            
            return cellHeight;
        }
        default:
            break;
    }
    
    return 44.0;
}


- (IBAction)deleteEvent:(id)sender {
    if ([_event isRecurring]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        actionSheet.tag = 998;      // For deletion recurring event
        
        actionSheet.title = NSLocalizedString(@"This is a recurring event",);
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete only this event",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete this and all future ones",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete all",)];
        
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
        [actionSheet showFromToolbar:self.navigationController.toolbar];

    } else {
        NSString *message = NSLocalizedString(@"Are you sure you want to delete this event?",);
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel",)
                                                   destructiveButtonTitle:NSLocalizedString(@"Delete",)
                                                        otherButtonTitles:nil];
        
        actionSheet.tag = 997;      // For regular event deletion
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }
}

- (IBAction)openEventEditor:(id)sender {
    if ([_event isRecurring] && _event.recurUpdateOption == UNDEFINED) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        actionSheet.tag = 999;      // For update
        
        actionSheet.title = NSLocalizedString(@"This is a recurring event",);
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update only this event",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update this and all future ones",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Update all",)];
        
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel",)];
        [actionSheet showFromToolbar:self.navigationController.toolbar];

    } else {
        [self performSegueWithIdentifier:@"OpenEventEditor" sender:self];
    }
}

#pragma - segue to editor
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"OpenEventEditor"]) {
        [segue.destinationViewController setAfterSavingDelegate:self];
        [segue.destinationViewController setEvent:_event];            

    } else if ([segue.identifier isEqualToString:@"ShowReminderDetail"]) {
        [segue.destinationViewController setReminders:_event.reminders];

    } else if ([segue.identifier isEqualToString:@"ShowAttendeeDetail"]) {
        [segue.destinationViewController setAttendees:_event.attendees];

    } else if ([segue.identifier isEqualToString:@"OpenMap"]) {
        [segue.destinationViewController setMyLocation:_event.location];
    }
}

- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index
{
    if (sender.tag == 999) {
        if (index == 0) {                       // Only this event
            _event.recurUpdateOption = ONE;
        } else if (index == 1) {                // this and future
            _event.recurUpdateOption = FUTURE;
        } else if (index == 2) {                // all
            _event.recurUpdateOption = ALL;
        } else {
            return;                             // Cancel
        }
        
        [self performSegueWithIdentifier:@"OpenEventEditor" sender:self];
        
    } else if (sender.tag == 998) {
        if (index == 0) {                       // Only this event
            _event.recurUpdateOption = ONE;
        } else if (index == 1) {                // this and future
            _event.recurUpdateOption = FUTURE;
        } else if (index == 2) {                // all
            _event.recurUpdateOption = ALL;
        } else {                                // Cancel
            return;
        }

        [self callDeleteService];
        [sender dismissWithClickedButtonIndex:index animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
        
    } else if (sender.tag == 997) {
        if (index == sender.destructiveButtonIndex) {
            [self callDeleteService];
            [sender dismissWithClickedButtonIndex:index animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            
        } else if (index == sender.cancelButtonIndex) {
            [sender dismissWithClickedButtonIndex:index animated:YES];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.eventService = [[EventService alloc] init];
    self.eventService.serviceDelegate = self;
    
    if (_event != nil) {
        self.titleTextLabel.text = _event.title;
    }
    
    self.startDateCell.textLabel.text = NSLocalizedString(@"Start time",);
    self.endDateCell.textLabel.text = NSLocalizedString(@"End time",);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateEventFields];
    
    // Make sure every time the the edit button is tapped we ask for recur update option.
    _event.recurUpdateOption = UNDEFINED;
}

- (void)viewDidUnload {
    [self setTitleCell:nil];
    [self setLocationCell:nil];
    [self setStartDateCell:nil];
    [self setEndDateCell:nil];
    [self setRecurrenceCell:nil];
    [self setReminderCell:nil];
    [self setAttendeeCell:nil];
    [self setTagCell:nil];
    [self setNoteCell:nil];
    [self setColorLabel:nil];
    [self setTitleTextLabel:nil];
    [super viewDidUnload];
}
@end
