//
//  AttendeeEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AttendeeEditorViewController.h"
#import "NSString+NPStringUtil.h"

int const ATTENDEE_EMAIL_TEXTFIELD = 10;

@interface AttendeeEditorViewController ()
@property (nonatomic, strong) NSMutableArray *attendees;
@end

@implementation AttendeeEditorViewController

@synthesize attendees = _attendees;

- (void)setAttendees:(NSMutableArray *)attendees
{    
    if (attendees == nil) {
        _attendees = [[NSMutableArray alloc] init];
    } else {
        _attendees = [NSMutableArray arrayWithArray:attendees];
    }
    
    // Add a dummy one for "add new reminder"
    Attendee *newAttendee = [[Attendee alloc] init];
    [_attendees addObject:newAttendee];
}

- (NSInteger)addNewRowRowId
{
    return [self.attendees count] - 1;
}

- (IBAction)cancelAttendee:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneAttendee:(id)sender
{
    NSMutableArray *finalAttendees = [[NSMutableArray alloc] init];
    
    // Step through all table cells and collect valid attendees
    NSArray *cells = [self.tableView visibleCells];
    for (UITableViewCell *cell in cells) {
        NSString *email = nil;
        
        for (UIView *subview in [cell.contentView subviews]) {
            if (subview.tag == ATTENDEE_EMAIL_TEXTFIELD) {
                UITextField *emailTextField = (UITextField*)subview;
                email = emailTextField.text;
                
            }
        }
        
        if (email != nil && [NSString isValidEmail:email]) {
            Attendee *attendee = [[Attendee alloc] init];
            attendee.email = email;            
            [finalAttendees addObject:attendee];
        }
    }
    
    [self.entryUpdateDelegate updateEventAttendee:finalAttendees];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.attendees count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Attendee *attendee = [self.attendees objectAtIndex:indexPath.row];

    static NSString *CellIdentifier = @"AttendeeInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    for (UIView *subview in [cell.contentView subviews]) {
        if (subview.tag == ATTENDEE_EMAIL_TEXTFIELD) {
            UITextField *emailTextField = (UITextField*)subview;
            emailTextField.text = attendee.email;
            emailTextField.delegate = self;
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
        [self.attendees removeObjectAtIndex:indexPath.row];
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
        [self.attendees addObject:[[Attendee alloc] init]];                     // Note addNewRowRowId has been incremented.
        
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
    
    if (textField.tag == ATTENDEE_EMAIL_TEXTFIELD && [NSString isValidEmail:textField.text]) {
        Attendee *att = [self.attendees objectAtIndex:rowId];
        att.email = textField.text;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setEditing:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

@end
