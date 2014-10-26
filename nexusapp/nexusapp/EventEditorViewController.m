//
//  EventEditorViewControllerViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EventEditorViewController.h"
#import "DateUtil.h"
#import "ReminderEditorViewController.h"
#import "AttendeeEditorViewController.h"
#import "RecurrenceEditorViewController.h"
#import "UIFont+NPFont.h"
#import "UIColor+NPColor.h"
#import "UIView+FindFirstResponder.h"
#import "ColorPaletteView.h"
#import "EventService.h"


#define END_OF_DAY  1439

@interface EventEditorViewController()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UITextField *startDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *startTimeTextField;
@property (weak, nonatomic) IBOutlet UISwitch *allDaySwitch;
@property (weak, nonatomic) IBOutlet UITextField *endDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet TextViewWithPlaceHolder *noteTextView;

@property (weak, nonatomic) IBOutlet UITableViewCell *titleCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *startDateTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endDateTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *recurrenceCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *remindersCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *attendeesCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tagsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *noteCell;

@property (weak, nonatomic) IBOutlet UIButton *colorPickerButton;
@property (nonatomic, strong) ColorPaletteView *colorPicker;
@property (nonatomic, strong) NSString *colorLabelHexString;
@property (nonatomic, strong) UIDatePicker *timePicker;
@property (nonatomic, strong) NSString *startDateYmd;
@property NSInteger startTimeInMinutes;
@property (nonatomic, strong) NSString *endDateYmd;
@property NSInteger endTimeInMinutes;
@end

@implementation EventEditorViewController

@synthesize event = _event;

- (NPEntry*)currentEditedEntry {
    return _event;
}

- (void)setEvent:(NPEvent*)event
{
    _event = [event copy];
    
    if ([NSString isBlank:_event.entryId]) {
        self.startDateYmd = [DateUtil convertToYYYYMMDD:self.event.startTime];
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.event.startTime];
        NSInteger hours = [dateComponents hour];
        NSInteger minutes = [dateComponents minute];
        self.startTimeInMinutes = hours*60 + minutes;
        
        self.endDateYmd = nil;
        self.endTimeInMinutes = 0;
        
    } else {
        self.startDateYmd = [DateUtil convertToYYYYMMDD:self.event.startTime];
        
        if (self.event.noStartingTime || self.event.allDayEvent) {
            self.startTimeInMinutes = 0;
        } else {
            NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.event.startTime];
            NSInteger hours = [dateComponents hour];
            NSInteger minutes = [dateComponents minute];
            self.startTimeInMinutes = hours*60 + minutes;
        }
        
        if (self.event.noStartingTime || self.event.allDayEvent || self.event.singleTimeEvent) {
            self.endTimeInMinutes = 0;

        } else {
            self.endDateYmd = [DateUtil convertToYYYYMMDD:self.event.endTime];
            NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.event.endTime];
            NSInteger hours = [dateComponents hour];
            NSInteger minutes = [dateComponents minute];
            self.endTimeInMinutes = hours*60 + minutes;
        }
    }

    self.colorLabelHexString = [NSString stringWithString:self.event.colorLabel];
    
    [self.tableView reloadData];
}

- (IBAction)saveEvent:(id)sender
{
    [self collectStartAndEndTime];

    // Clear the old values
    [self.event.featureValuesDict removeAllObjects];

    self.event.title = self.titleTextField.text;
    self.event.note = self.noteTextView.text;
    self.event.tags = self.tagsTextField.text;

    self.event.location = [[NPLocation alloc] init];
    self.event.location.locationName = self.locationTextField.text;

    self.event.colorLabel = self.colorLabelHexString;
    
    if (self.event.folder.folderId == -1) {
        [self openFolderView:nil];
        return;
    }
    
    BOOL timeIsValid = YES;
    if ([NSString isBlank:self.startDateYmd]) {
        timeIsValid = NO;

    } else {
        if (self.event.allDayEvent == NO && self.event.singleTimeEvent == NO && self.event.noStartingTime == NO) {
            if ([self.event.startTime compare:self.event.endTime] == NSOrderedDescending) {
                timeIsValid = NO;
            }
        }
    }
    
    if (timeIsValid == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Invalid dates",) delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alert show];

    } else {
        EventService *eventService = [[EventService alloc] init];
        eventService.serviceDelegate = self;
        [eventService addOrUpdateEvent:self.event];
    }
}

// Result of saving the bookmark
- (void)updateServiceResult:(id)serviceResult
{
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        if (actionResponse.success) {
            if (actionResponse.entry != nil) {
                self.event.entryId = actionResponse.entry.entryId;
            }

            if (self.afterSavingDelegate != nil) {
                [self.afterSavingDelegate entryUpdateSaved:self.event];
            }
            
            // Note that the returned action result is not sent out when the action returned a list of entries.
            if ([actionResponse.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                [NotificationUtil sendEntryUpdatedNotification:self.event];
            } else {
                [NotificationUtil sendEntryUpdatedNotification:actionResponse.entry];
            }

            [self cancelEditor:nil];
        }
    }
}

// This is called whenever the start date / start time / end date / end time is set
- (void)collectStartAndEndTime
{
    if (self.allDaySwitch.on) {
        self.event.allDayEvent = YES;
    } else {
        self.event.allDayEvent = NO;
    }
    
    if (self.event.allDayEvent) {

        // **** This is an all day event ****
        if (![NSString isBlank:self.startDateYmd]) {
            self.event.startTime = [DateUtil parseFromYYYYMMDD:self.startDateYmd];
        }
        
    } else {
        
        if ([NSString isBlank:self.startTimeTextField.text]) {                      // Make sure to cover the case that "clear" button is clicked.
            self.startTimeInMinutes = 0;
        }
        
        if ([NSString isBlank:self.endTimeTextField.text]) {
            self.endTimeInMinutes = 0;
        }
        
        NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        NSDateComponents *components = [[NSDateComponents alloc] init];
        
        if (![NSString isBlank:self.startDateYmd] && ![NSString isBlank:self.endDateYmd] && ![self.startDateYmd isEqualToString:self.endDateYmd])
        {
            //
            // Both start date and end date are provided and they are different
            // 1. No time is provided for either start or end.
            // 2. One or both times are provided.
            //
            if (self.startTimeInMinutes == 0 && self.endTimeInMinutes == 0) {
                self.event.allDayEvent = YES;

                [components setMinute:self.startTimeInMinutes];
                self.event.startTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.startDateYmd] options:0];
                
                [components setMinute:END_OF_DAY];
                self.event.endTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.endDateYmd] options:0];
                
            } else {
                [components setMinute:self.startTimeInMinutes];
                self.event.startTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.startDateYmd] options:0];
                
                if (self.endTimeInMinutes != 0) {
                    [components setMinute:self.endTimeInMinutes];
                } else {
                    [components setMinute:END_OF_DAY];
                }
                self.event.endTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.endDateYmd] options:0];
            }

        } else {

            // Get the start time
            if (![NSString isBlank:self.startDateYmd]) {
                [components setMinute:self.startTimeInMinutes];
                self.event.startTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.startDateYmd] options:0];
                
                if (self.startTimeInMinutes == 0) {                                     // No starting time is set
                    self.event.noStartingTime = YES;
                } else {
                    self.event.noStartingTime = NO;
                }
            }
            
            // Get the end time
            if (![NSString isBlank:self.endDateYmd]) {                                  // The end date is set
                if (self.endTimeInMinutes == 0) {                                       // The end time is not set
                    if ([self.endDateYmd isEqualToString:self.startDateYmd]) {          // The end date is the same as start date
                        self.event.singleTimeEvent = YES;
                        
                    } else {                                                            // The end time is set (both end date and time are set)
                        self.endTimeInMinutes = END_OF_DAY;
                    }
                }
                
                [components setMinute:self.endTimeInMinutes];
                self.event.endTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.endDateYmd] options:0];
                
                if ([self.event.endTime compare:self.event.startTime] == NSOrderedSame) {   // Double check to set the singleTimeEvent flag
                    self.event.singleTimeEvent = YES;
                } else {
                    self.event.singleTimeEvent = NO;
                }
                
            } else {                                                                    // The end date is not set
                if (self.endTimeInMinutes != 0) {
                    if (![NSString isBlank:self.startDateYmd]) {                        // Use the start date to help figure out end time
                        self.endDateYmd = [NSString stringWithString:self.startDateYmd];
                        [components setMinute:self.endTimeInMinutes];
                        self.event.endTime = [cal dateByAddingComponents:components toDate:[DateUtil parseFromYYYYMMDD:self.endDateYmd] options:0];
                        
                        if ([self.event.endTime compare:self.event.startTime] == NSOrderedSame) {   // Double check to set the singleTimeEvent flag
                            self.event.singleTimeEvent = YES;
                        } else {
                            self.event.singleTimeEvent = NO;
                        }
                    }
                    
                } else {                                                                // Neither end dat and end time is set
                    if (self.event.noStartingTime == NO && [self.event.endTime compare:self.event.startTime] == NSOrderedSame) {
                        // Set to single time event only when it DOES have a starting time.
                        // Also, still check the difference of start and end time because it can be different days.
                        self.event.singleTimeEvent = YES;
                    }
                }
            }
        }
    }
    
    DLog(@"%@ - %@", self.event.startTime, self.event.endTime);
}

#pragma mark - delegate to handle value settings in Recurrence, Reminder and Attendee

- (void)updateEventRecurrence:(Recurrence*)recurrence
{
    self.event.recurrence = [recurrence copy];
    if (self.event.recurrence.pattern != norepeat) {
        self.recurrenceCell.textLabel.text = @"";
        self.recurrenceCell.detailTextLabel.text = [self.event.recurrence repeatDescriptionString:YES];
        self.recurrenceCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.recurrenceCell.detailTextLabel.textColor = [UIColor blackColor];
        
    } else {
        self.recurrenceCell.textLabel.text = [self.event.recurrence repeatDescriptionString:YES];
        self.recurrenceCell.detailTextLabel.text = @"";
    }
}

- (void)updateEventReminder:(NSArray*)reminders
{
    if (reminders != nil && [reminders count] > 0) {
        self.event.reminders = [NSMutableArray arrayWithArray:reminders];
    } else {
        self.event.reminders = nil;
    }
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:0 inSection:EVENT_REMINDER_SECTION];
    NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
    [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
}


- (void)updateEventAttendee:(NSArray*)attendees
{
    if (attendees != nil && [attendees count] > 0) {
        self.event.attendees = [NSMutableArray arrayWithArray:attendees];
    } else {
        self.event.attendees = nil;
    }
    NSIndexPath* rowToReload = [NSIndexPath indexPathForRow:0 inSection:EVENT_ATTENDEE_SECTION];
    NSArray* rowsToReload = [NSArray arrayWithObjects:rowToReload, nil];
    [self.tableView reloadRowsAtIndexPaths:rowsToReload withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - delegate to handle input views

// Delegate for date selector
- (void)setSelectedValue:(id)value {
    if ([value isKindOfClass:[ColorTile class]]) {        // event color selector
        ColorTile *colorTile = (ColorTile*)value;
        self.colorPickerButton.backgroundColor = colorTile.backgroundColor;
        self.colorLabelHexString = [NSString stringWithString:colorTile.colorHexString];
        [self.colorPicker slideOff];
    }
}


- (void)didSelectedDate:(id)sender {
    NSString *ymd = (NSString*)sender;
    
    if ([self.startDateTextField isFirstResponder]) {
        self.startDateTextField.text = [DateUtil displayDate:[DateUtil parseFromYYYYMMDD:ymd]];
        self.startDateYmd = ymd;
        [self.startDateTextField resignFirstResponder];
        
    } else if ([self.endDateTextField isFirstResponder]) {
        self.endDateTextField.text = [DateUtil displayDate:[DateUtil parseFromYYYYMMDD:ymd]];
        self.endDateYmd = ymd;
        [self.endDateTextField resignFirstResponder];
        
    }
    
    [self collectStartAndEndTime];
}


- (void)inputAccessoryViewDidCancel:(id)sender
{
    [self.tableView endEditing:YES];
}

- (void)inputAccessoryViewDidFinish:(id)sender
{
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.timePicker.date];
    NSInteger hours = [dateComponents hour];
    NSInteger minutes = [dateComponents minute];
    NSInteger minutesRounded = ( (NSInteger)(minutes / 15) ) * 15;
    NSDate *roundedDate = [[NSDate alloc] initWithTimeInterval:60.0 * (minutesRounded - minutes) sinceDate:self.timePicker.date];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"h:mm a"];
    NSString *timeStr = [outputFormatter stringFromDate:roundedDate];
    
    if ([self.startTimeTextField isFirstResponder]) {
        self.startTimeTextField.text = timeStr;
        self.startTimeInMinutes = hours*60 + minutesRounded;

    } else if ([self.endTimeTextField isFirstResponder]) {
        self.endTimeTextField.text = timeStr;
        self.endTimeInMinutes = hours*60 + minutesRounded;
    }
    
    [self collectStartAndEndTime];
    
    [self.tableView endEditing:YES];
}

- (IBAction)openColorPicker:(id)sender
{
    [self.view endEditing:YES];
    if (self.colorPicker == nil) {
        self.colorPicker = [[ColorPaletteView alloc] initWithToolBar:self.navigationController.view];
        self.colorPicker.delegate = self;
        [self.navigationController.view addSubview:self.colorPicker];
    }
    [self.colorPicker slideIn:self.navigationController.view];
}

- (void)keyboardDidShow:(id)sender {
    [self.colorPicker slideOff];
}

- (IBAction)toggleAllDaySwitch:(id)sender
{
    // The UI element first
    if (self.allDaySwitch.on) {
        self.startTimeTextField.text = @"";
        self.startTimeTextField.enabled = NO;
    } else {
        self.startTimeTextField.enabled = YES;
    }
    
    // Update the time and flag values
    [self collectStartAndEndTime];

    [self.tableView reloadData];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return EVENT_SECTIONS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case EVENT_TITLE_SECTION:
        {
            return self.titleCell;
        }   
        case EVENT_LOCATION_SECTION:
        {
            return self.locationCell;
        }
        case EVENT_TIME_SECTION:
        {
            if (indexPath.row == 0) {                
                return self.startDateTimeCell;
                
            } else if (indexPath.row == 1) {
                if (self.event.allDayEvent) {
                    return self.recurrenceCell;
                } else {
                    return self.endDateTimeCell;
                }
                
            } else if (indexPath.row == 2) {
                return self.recurrenceCell;
            }
        }
        case EVENT_REMINDER_SECTION:
        {
            if ([self.event.reminders count] > 0) {
                self.remindersCell.textLabel.text = NSLocalizedString(@"Reminders",);
                self.remindersCell.detailTextLabel.text = [self.event reminderText];
            } else {
                self.remindersCell.textLabel.text = NSLocalizedString(@"Reminders",);
                self.remindersCell.detailTextLabel.text = @"";
            }
            return self.remindersCell;
        }
        case EVENT_ATTENDEE_SECTION:
        {
            if ([self.event.attendees count] > 0) {
                self.attendeesCell.textLabel.text = NSLocalizedString(@"Attendees",);
                self.attendeesCell.detailTextLabel.text = [self.event attendeeText];
            } else {
                self.attendeesCell.textLabel.text = NSLocalizedString(@"Attendees",);
                self.attendeesCell.detailTextLabel.text = @"";
            }
            return self.attendeesCell;
        }
        case EVENT_TAG_SECTION:
        {
            if (indexPath.row == 0) {
                return self.tagsCell;
            } else if (indexPath.row == 1) {
                return self.noteCell;
            }
        }
        default:
            break;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case EVENT_TITLE_SECTION:
        case EVENT_LOCATION_SECTION:
            return 1;
        case EVENT_TIME_SECTION:
            if (self.event.allDayEvent) {   // No need to display the end time row
                return 2;
            }
            return 3;
        case EVENT_REMINDER_SECTION:
        case EVENT_ATTENDEE_SECTION:
            return 1;
        case EVENT_TAG_SECTION:
            return 2;
        default:
            break;
    }
    return 1;
}

#pragma - segue to reminder editor

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.view endEditing:YES];

    if ([segue.identifier isEqualToString:@"ShowReminderEditor"]) {
        [segue.destinationViewController setReminders:self.event.reminders];
        [segue.destinationViewController setEntryUpdateDelegate:self];
        
    } else if ([segue.identifier isEqualToString:@"ShowAttendeeEditor"]) {
        [segue.destinationViewController setAttendees:self.event.attendees];
        [segue.destinationViewController setEntryUpdateDelegate:self];
        
    } else if ([segue.identifier isEqualToString:@"ShowRecurrenceEditor"]) {
        [segue.destinationViewController setRecurrence:self.event.recurrence];
        [segue.destinationViewController setEntryUpdateDelegate:self];
    }
}


- (UIToolbar*)timePickerToolbar
{
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 44)];

    pickerToolbar.barStyle = UIBarStyleDefault;
    
    UIBarButtonItem *selectButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select",)
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(inputAccessoryViewDidFinish:)];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self action:@selector(inputAccessoryViewDidCancel:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [pickerToolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, selectButton, nil] animated:NO];
    
    return pickerToolbar;
}

- (UIDatePicker*)getTimePicker
{
    if (self.timePicker == nil) {
        self.timePicker = [[UIDatePicker alloc] init];
        self.timePicker.datePickerMode = UIDatePickerModeTime;
        self.timePicker.minuteInterval = 15;
    }
    
    return self.timePicker;
}


#pragma mark - FolderPickerControllerDelegate

- (void)didSelectFolder:(NPFolder*)selectedFolder forAction:(FolderViewingPurpose)forAction {
    [super didSelectFolder:selectedFolder forAction:forAction];
    self.event.folder = [selectedFolder copy];
    self.event.folder.folderId = selectedFolder.folderId;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.noteTextView.placeholder = NSLocalizedString(@"Note",);
    
    self.titleTextField.text = self.event.title;
    
    if (self.event.location != nil) {
        self.locationTextField.text = self.event.location.locationName;
    }
    
    // Set start date and time
    
    InputDateSelectorView *dateSelector = [[InputDateSelectorView alloc] initWithToolBar:self.view asInputView:YES];
    dateSelector.delegate = self;
    self.startDateTextField.text = [DateUtil displayDate:self.event.startTime];
    self.startDateTextField.inputView = dateSelector;
    
    if (self.event.allDayEvent) {
        self.startTimeTextField.text = @"";
        
    } else {
        if (self.event.noStartingTime == NO) {
            self.startTimeTextField.text = [DateUtil displayEventTime:self.event.startTime];
        }
    }
    
    self.startTimeTextField.inputView = [self getTimePicker];
    self.startTimeTextField.inputAccessoryView = [self timePickerToolbar];
    
    // Set end date and time
    if (self.event.allDayEvent) {
        self.allDaySwitch.on = YES;
        self.endDateTextField.text = @"";
        self.endTimeTextField.text = @"";
        
    } else {
        self.allDaySwitch.on = NO;
        
        if (!self.event.noStartingTime && !self.event.singleTimeEvent) {
            self.endDateTextField.text = [DateUtil displayDate:self.event.endTime];
            self.endTimeTextField.text = [DateUtil displayEventTime:self.event.endTime];
        }
    }

    dateSelector.delegate = self;
    self.endDateTextField.inputView = dateSelector;
    
    self.endTimeTextField.inputView = [self getTimePicker];
    self.endTimeTextField.inputAccessoryView = [self timePickerToolbar];
    
    
    // Set the recurrence information
    NSString *description = [self.event.recurrence repeatDescriptionString:YES];
    if (self.event.recurrence.pattern == norepeat) {
        self.recurrenceCell.textLabel.text = description;
        self.recurrenceCell.detailTextLabel.text = @"";
    } else {
        self.recurrenceCell.textLabel.text = @"";
        self.recurrenceCell.detailTextLabel.text = description;
    }

    self.recurrenceCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    self.recurrenceCell.detailTextLabel.font = [UIFont boldSystemFontOfSize:15.0];
    self.recurrenceCell.detailTextLabel.numberOfLines = 0;
    self.recurrenceCell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;

    self.tagsTextField.text = self.event.tags;
    self.noteTextView.text = self.event.note;
    
    // color picker button
    self.colorPickerButton.backgroundColor = [UIColor colorFromHexString:self.event.colorLabel];
    self.colorPickerButton.layer.cornerRadius = 15;
    
    
    // Keep track of keyboard - for sliding off color
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tableView endEditing:YES];
    [self.colorPicker slideOff];
}

- (void)viewDidUnload {
    [self setTitleTextField:nil];
    [self setLocationTextField:nil];
    [self setStartDateTextField:nil];
    [self setStartTimeTextField:nil];
    [self setAllDaySwitch:nil];
    [self setEndDateTextField:nil];
    [self setEndTimeTextField:nil];
    [self setNoteTextView:nil];
    [self setTitleCell:nil];
    [self setLocationCell:nil];
    [self setStartDateTimeCell:nil];
    [self setEndDateTimeCell:nil];
    [self setRecurrenceCell:nil];
    [self setRemindersCell:nil];
    [self setAttendeesCell:nil];
    [self setTagsCell:nil];
    [self setNoteCell:nil];
    [self setAllDaySwitch:nil];
    [self setTagsTextField:nil];
    [self setColorPickerButton:nil];
    [super viewDidUnload];
}

@end
