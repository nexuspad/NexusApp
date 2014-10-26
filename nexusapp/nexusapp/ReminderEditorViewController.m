//
//  ReminderEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReminderEditorViewController.h"
#import "ViewDisplayHelper.h"
#import "NSString+NPStringUtil.h"
#import "Reminder.h"
#import "AccountManager.h"

int const REMINDER_EMAIL_TEXTFIELD      = 10;
int const REMINDER_OFFSET_TEXTFIELD     = 20;

NSString* const MINUTES                 = @"minutes";
NSString* const HOURS                   = @"hour(s)";
NSString* const DAYS                    = @"day(s)";

@interface ReminderEditorViewController ()
@property (nonatomic, strong) NSDictionary *offsetSelections;
@property (nonatomic, strong) NSMutableArray *reminders;
@end

@implementation ReminderEditorViewController

@synthesize reminders = _reminders, reminderOffsetValuePicker;

- (void)setReminders:(NSMutableArray*)reminders
{
    if (reminders == nil) {
        _reminders = [[NSMutableArray alloc] init];
    } else {
        _reminders = [NSMutableArray arrayWithArray:reminders];
    }

    if (_reminders.count == 0) {
        // No reminders.
        Reminder *defaultReminder = [[Reminder alloc] init];
        Account *account = [[AccountManager instance] getCurrentLoginAcct];
        defaultReminder.deliverAddress = account.email;
        [_reminders addObject:defaultReminder];

        Reminder *newReminder = [[Reminder alloc] init];
        [_reminders addObject:newReminder];

    } else {
        // Add a new reminder row
        Reminder *newReminder = [[Reminder alloc] init];
        [_reminders addObject:newReminder];
    }
}

- (NSInteger)addNewRowRowId
{
    return [self.reminders count] - 1;
}

- (IBAction)cancelReminder:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneReminder:(id)sender
{
    NSMutableArray *finalRemindersArr = [[NSMutableArray alloc] init];

    // Step through all table cells and collect valid reminders
    NSArray *cells = [self.tableView visibleCells];

    for (UITableViewCell *cell in cells) {
        NSString *email = nil, *offset = nil;

        for (UIView *subview in [cell.contentView subviews]) {
            if (subview.tag == REMINDER_EMAIL_TEXTFIELD) {
                UITextField *emailTextField = (UITextField*)subview;
                email = emailTextField.text;
                
            } else if (subview.tag == REMINDER_OFFSET_TEXTFIELD) {
                UITextField *offsetTextField = (UITextField*)subview;
                offset = offsetTextField.text;
                if ([offset length] == 0) {
                    offset = @"15 minute";
                }
            }
        }

        if (![NSString isBlank:email] && [NSString isValidEmail:email] && ![NSString isBlank:offset]) {
            NSArray *offsetArr = [offset componentsSeparatedByString:@" "];
            
            Reminder *aReminder = [[Reminder alloc] init];
            aReminder.deliverAddress = email;
            
            long offsetInSecs = 0;
            
            if ([[offsetArr objectAtIndex:1] isEqualToString:MINUTES]) {
                offsetInSecs = [[offsetArr objectAtIndex:0] intValue] * 60;
                aReminder.unit = @"minute";
                aReminder.unitCount = [[offsetArr objectAtIndex:0] intValue];
                
            } else if ([[offsetArr objectAtIndex:1] isEqualToString:HOURS]) {
                offsetInSecs = [[offsetArr objectAtIndex:0] intValue] * 3600;
                aReminder.unit = @"hour";
                aReminder.unitCount = [[offsetArr objectAtIndex:0] intValue];
                
            } else if ([[offsetArr objectAtIndex:1] isEqualToString:DAYS]) {
                offsetInSecs = [[offsetArr objectAtIndex:0] intValue] * 86400;
                aReminder.unit = @"day";
                aReminder.unitCount = [[offsetArr objectAtIndex:0] intValue];
                
            } else {
                offsetInSecs = 900;                 // 15 minutes
                aReminder.unit = @"minute";
                aReminder.unitCount = 15;
            }
            
            aReminder.offsetTs = offsetInSecs;
            
            [finalRemindersArr addObject:aReminder];
        }
    }

    [self.entryUpdateDelegate updateEventReminder:finalRemindersArr];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)inputAccessoryViewDidFinish:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.reminders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Reminder *reminder = [self.reminders objectAtIndex:indexPath.row];

    static NSString *CellIdentifier = @"ReminderInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    for (UIView *subview in [cell.contentView subviews]) {
        if (subview.tag == REMINDER_EMAIL_TEXTFIELD) {
            UITextField *emailTextField = (UITextField*)subview;
            emailTextField.text = reminder.deliverAddress;
            emailTextField.delegate = self;

        } else if (subview.tag == REMINDER_OFFSET_TEXTFIELD) {
            UITextField *offsetTextField = (UITextField*)subview;
            offsetTextField.text = [reminder reminderTime];
            offsetTextField.delegate = self;
            offsetTextField.inputView = self.reminderOffsetValuePicker;
            [self addInputViewToolbar:offsetTextField];
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (indexPath.row == [self addNewRowRowId]) {  // Last row is always inserting
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [self.reminders removeObjectAtIndex:indexPath.row];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];

    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - Textfield delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *contentView = (UITableViewCell*)textField.superview;
    UITableViewCell *cell = (UITableViewCell*)[contentView superview];
    
    if ([[self.tableView indexPathForCell:cell] row] == [self addNewRowRowId]) {
        // Update the datasource
        Reminder *newReminder = [[Reminder alloc] init];
        [self.reminders addObject:newReminder];                     // Note addNewRowRowId has been incremented.
        
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self addNewRowRowId] inSection:0]];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];
        
        self.tableView.editing = NO;
        self.tableView.editing = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UIView *contentView = (UITableViewCell*)textField.superview;
    UITableViewCell *cell = (UITableViewCell*)[contentView superview];
    NSInteger rowId = [[self.tableView indexPathForCell:cell] row];
    
    if (textField.tag == REMINDER_EMAIL_TEXTFIELD) {
        [[self.reminders objectAtIndex:rowId] setDeliverAddress:textField.text];

    } else if (textField.tag == REMINDER_OFFSET_TEXTFIELD) {
        NSString *offsetText = @"";
        if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 0) {
            NSString *col2 = [NSString stringWithString:MINUTES];
            NSString *col1 = [[self.offsetSelections objectForKey:MINUTES] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]];
            offsetText = [NSString stringWithFormat:@"%@ %@", col1, col2];

        } else if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 1) {
            NSString *col2 = [NSString stringWithString:HOURS];
            NSString *col1 = [[self.offsetSelections objectForKey:HOURS] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]];
            offsetText = [NSString stringWithFormat:@"%@ %@", col1, col2];

        } else if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 2) {
            NSString *col2 = [NSString stringWithString:DAYS];
            NSString *col1 = [[self.offsetSelections objectForKey:DAYS] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]];
            offsetText = [NSString stringWithFormat:@"%@ %@", col1, col2];
        }
        
        textField.text = offsetText;
    }
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        NSInteger selectedRowInCol2 = [pickerView selectedRowInComponent:1];

        if (selectedRowInCol2 == 0) {               // minute
            return [[self.offsetSelections objectForKey:MINUTES] objectAtIndex:row];

        } else if (selectedRowInCol2 == 1) {        // hour
            return [[self.offsetSelections objectForKey:HOURS] objectAtIndex:row];
            
        } else if (selectedRowInCol2 == 2) {        // day
            return [[self.offsetSelections objectForKey:DAYS] objectAtIndex:row];
            
        } 
        
    } else if (component == 1) {
        if (row == 0) return MINUTES;
        else if (row == 1) return HOURS;
        else if (row == 2) return DAYS;
    }
    
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0) {
        
    } else if (component == 1) {
        [pickerView reloadComponent:0];
    }
}

- (void)setOffsetInReminders
{
    long offsetInSecs = 0;

    if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 0) {
        int minutes = [[[self.offsetSelections objectForKey:MINUTES] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]] intValue];
        offsetInSecs = minutes * 60;
        
    } else if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 1) {
        int hours = [[[self.offsetSelections objectForKey:HOURS] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]] intValue];
        offsetInSecs = hours * 3600;
        
    } else if ([self.reminderOffsetValuePicker selectedRowInComponent:1] == 2) {
        int days = [[[self.offsetSelections objectForKey:DAYS] objectAtIndex:[self.reminderOffsetValuePicker selectedRowInComponent:0]] intValue];
        offsetInSecs = days * 24 * 3660;
    }
    
    UIView *contentView = (UITableViewCell*)self.reminderOffsetValuePicker.superview;
    UITableViewCell *cell = (UITableViewCell*)[contentView superview];
    NSInteger rowId = [[self.tableView indexPathForCell:cell] row];
    
    Reminder *theReminder = [self.reminders objectAtIndex:rowId];
    theReminder.offsetTs = offsetInSecs;
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        if (pickerView.numberOfComponents == 1) {
            return 1;
        }

        NSInteger selectedRowInCol2 = [pickerView selectedRowInComponent:1];

        if (selectedRowInCol2 == 0 || selectedRowInCol2 == -1) {                // minute
            return [[self.offsetSelections objectForKey:MINUTES] count];

        } else if (selectedRowInCol2 == 1) {                                    // hour
            return [[self.offsetSelections objectForKey:HOURS] count];

        } else if (selectedRowInCol2 == 2) {                                    // day
            return [[self.offsetSelections objectForKey:DAYS] count];
        }

    } else if (component == 1) {
        return 3;
    }
    
    return 0;
}


#pragma mark - Table view delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setEditing:YES];
    
    NSMutableDictionary *offsets = [[NSMutableDictionary alloc] initWithCapacity:3];
    [offsets setObject:[NSArray arrayWithObjects:@"15", @"30", @"45", nil] forKey:MINUTES];
    [offsets setObject:[NSArray arrayWithObjects:@"1", @"2", @"3", nil] forKey:HOURS];
    [offsets setObject:[NSArray arrayWithObjects:@"1", @"2", nil] forKey:DAYS];
    self.offsetSelections = [NSDictionary dictionaryWithDictionary:offsets];
    
    CGRect datePickerViewRect = CGRectZero;
    datePickerViewRect.size = [ViewDisplayHelper getInputViewSize];
    self.reminderOffsetValuePicker = [[UIPickerView alloc] initWithFrame:datePickerViewRect];
    self.reminderOffsetValuePicker.showsSelectionIndicator = YES;
    self.reminderOffsetValuePicker.delegate = self;
    self.reminderOffsetValuePicker.dataSource = self;
    
    [self.reminderOffsetValuePicker selectRow:0 inComponent:1 animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)addInputViewToolbar:(UITextField*)textField;
{
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 44)];
    pickerToolbar.barStyle = UIBarStyleBlackOpaque;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self action:@selector(inputAccessoryViewDidFinish:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [pickerToolbar setItems:[NSArray arrayWithObjects:flexibleSpace, doneButton, nil] animated:NO];
    
    textField.inputAccessoryView = pickerToolbar;
}

@end
