//
//  AttendeeViewController.m
//  nexuspad
//
//  Created by Ren Liu on 8/10/12.
//
//

#import "AttendeeViewController.h"

@interface AttendeeViewController ()
@property (nonatomic, strong) NSMutableArray *sectionTitles;
@property (nonatomic, strong) NSMutableDictionary *attendeeBySections;
@end

@implementation AttendeeViewController

@synthesize attendees = _attendees;

- (void)setAttendees:(NSArray *)attendees
{
    _attendees = attendees;
    
    self.sectionTitles = [[NSMutableArray alloc] init];
    self.attendeeBySections = [[NSMutableDictionary alloc] init];
    
    for (Attendee *att in self.attendees) {
        NSString *sectionTitle = @"Unknown";

        if (att.status == notinvited) {
            sectionTitle = NSLocalizedString(@"Not invited",);
            
        } else if (att.status == invited) {
            sectionTitle = NSLocalizedString(@"Invited",);
            
        } else if (att.status == willattend) {
            sectionTitle = NSLocalizedString(@"Will attend",);
            
        } else if (att.status == wontattend) {
            sectionTitle = NSLocalizedString(@"Won't attend",);
            
        } else if (att.status == mayattend) {
            sectionTitle = NSLocalizedString(@"May attend",);
        }
        
        if (![self.sectionTitles containsObject:sectionTitle]) {
            [self.sectionTitles addObject:sectionTitle];
            [self.attendeeBySections setObject:[[NSMutableArray alloc] init] forKey:sectionTitle];
        }
        
        [[self.attendeeBySections objectForKey:sectionTitle] addObject:att];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sectionTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *title = [self.sectionTitles objectAtIndex:section];
    if ([self.attendeeBySections objectForKey:title] != nil) {
        return [[self.attendeeBySections objectForKey:title] count];
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.sectionTitles objectAtIndex:section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AttendeeInfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    NSString *title = [self.sectionTitles objectAtIndex:indexPath.section];
    if ([self.attendeeBySections objectForKey:title] != nil) {
        Attendee *attendee = [[self.attendeeBySections objectForKey:title] objectAtIndex:indexPath.row];
        if (attendee.name != nil) {
            cell.textLabel.text = attendee.name;
        } else {
            cell.textLabel.text = attendee.email;
        }
        if (attendee.comment != nil) {
            cell.detailTextLabel.text = attendee.comment;
        }
    }

    return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
