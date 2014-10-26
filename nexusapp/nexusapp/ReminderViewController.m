//
//  EventReminderDetailViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReminderViewController.h"

@implementation ReminderViewController

@synthesize reminders = _reminders;

- (void)setReminders:(NSArray *)reminders
{
    _reminders = reminders;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.reminders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ReminderInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    Reminder *reminder = [self.reminders objectAtIndex:indexPath.row];
    
    cell.textLabel.text = reminder.deliverAddress;
    cell.detailTextLabel.text = [reminder reminderTime];
    
    return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

@end
