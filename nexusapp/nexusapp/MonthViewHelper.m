//
//  MonthViewHelper.m
//  nexusapp
//
//  Created by Ren Liu on 10/10/13.
//
//

#import "MonthViewHelper.h"
#import "ViewDisplayHelper.h"
#import "UITableViewCell+NPUtil.h"
#import "NPEvent.h"
#import "EventListViewCell.h"
#import "DateUtil.h"
#import "UIImage+ImageEffects.h"
#import "UIColor+NPColor.h"
#import "CalendarMonthRowCell.h"


@interface MonthViewHelper ()
@property (nonatomic, strong) NSMutableArray *monthRoll;
@property (nonatomic, strong) UITableView *dayEventTableView;
@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, strong) NSMutableDictionary *eventListObjectByMonth;   // This stores the events by month for reuse.

@property (nonatomic, strong) NSMutableDictionary *dataRequests;

@property NSMutableDictionary *dots;
@end

@implementation MonthViewHelper

- (id)initWithFrame:(CGRect)frame parentView:(UIView*)parentView {
    self = [super init];
    
    /*
     * The scrollable month view
     */
    self.monthView = [[CalendarMonthView alloc] initWithFrame:frame];
    self.monthView.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    self.monthView.delegate = self;
    self.monthView.rowCellClass = [CalendarMonthRowCell class];
    self.monthView.firstDate = [NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * 365 * 1];
    self.monthView.lastDate = [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 365 * 5];
    self.monthView.backgroundColor = [UIColor colorWithRed:0.84f green:0.85f blue:0.86f alpha:1.0f];
    self.monthView.pagingEnabled = NO;
    
    CGFloat onePixel = 1.0f / [UIScreen mainScreen].scale;
    self.monthView.contentInset = UIEdgeInsetsMake(0.0f, onePixel, 0.0f, onePixel);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(monthViewTapped:)];
    tap.numberOfTapsRequired = 1;
    [self.monthView addGestureRecognizer:tap];
    

    /*
     * The slide in day event view
     */

    CGRect rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
    
    rect.size.height = 200.0;
    rect.origin.y = [ViewDisplayHelper offsetYPosition];

    self.dayEventTableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
    self.dayEventTableView.delegate = self;
    self.dayEventTableView.dataSource = self;
    
    [parentView addSubview:self.dayEventTableView];
    
    self.parentView = parentView;

    return self;
}

// This provides the date range that are currently displayed on the screen.
- (NSArray*)getCurrentStartEndDates {
    if (self.monthRoll != nil && self.monthRoll.count > 0) {
        NSNumber *ym1 = [self.monthRoll firstObject];
        NSDate *startDate = [DateUtil parseFromYYYYMMDD:[NSString stringWithFormat:@"%d01", [ym1 intValue]]];
        NSNumber *ym2 = [self.monthRoll lastObject];
        NSDate *endDate = [DateUtil findLastDateOfMonth:[ym2 stringValue]];
        
        return [NSArray arrayWithObjects:startDate, endDate, nil];
    }
    return nil;
}

- (void)keepTrackOfDates:(NSString*)ym {
    // Add the ym to the monthRoll.
    // The monthRoll is to keep track of what's being displayed on the screen.
    
    if (self.monthRoll == nil) {
        self.monthRoll = [[NSMutableArray alloc] initWithCapacity:4];
    }
    
    NSNumber *ymNumber = @([ym intValue]);
    
    if (![self.monthRoll containsObject:ymNumber]) {
        [self.monthRoll addObject:ymNumber];
        [self.monthRoll sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    }
    
    if (self.monthRoll.count > 3) {
        if ([[self.monthRoll firstObject] compare:ymNumber] == NSOrderedSame) {         // Scroll up to previous month
            [self.monthRoll removeLastObject];
        } else if ([[self.monthRoll lastObject] compare:ymNumber] == NSOrderedSame) {   // Scroll down to next month
            [self.monthRoll removeObjectAtIndex:0];
        } else {                                                                        // This really shouldn't happen
            [self.monthRoll removeLastObject];
        }
    }
}

- (void)cleanup {
    [self.dayEventTableView removeFromSuperview];
    self.dayEventTableView = nil;
    
    for (UIGestureRecognizer *recognizer in self.monthView.gestureRecognizers) {
        [self.monthView removeGestureRecognizer:recognizer];
    }
    
    [self.monthView removeFromSuperview];
    self.monthView = nil;
}


// Called by CalendarMonthView to retrieve data for the month
- (void)doWantToRequestEventDataForMonth:(NSString *)ym {
    [self keepTrackOfDates:ym];

    if (self.dataRequests == nil) {
        self.dataRequests = [[NSMutableDictionary alloc] init];
    }
    
    if ([self.dataRequests objectForKey:ym] != nil) {
        NSDate *lastRequestTime = [self.dataRequests objectForKey:ym];
        NSDate *expiration = [[NSDate date] dateByAddingTimeInterval:-10];
        
        DLog(@"******** Displaying %@, Compare two dates %@, %@ ", ym, lastRequestTime, expiration);
        
        if ([lastRequestTime compare:expiration] == NSOrderedDescending) {
            DLog(@"****** there was an request just sent, do nothing here ***** ");
            return;
        }
    }
    
    [self.dataRequests setObject:[NSDate date] forKey:ym];

    if (self.eventListObjectByMonth == nil) {
        self.eventListObjectByMonth = [[NSMutableDictionary alloc] init];
    }

    NSString *ymd = [NSString stringWithFormat:@"%@01", ym];
    [self.controllerDelegate getEventsForMonthView:[DateUtil parseFromYYYYMMDD:ymd]];
}


//
// Called back from CalendarViewController
//
// When controller receives more data, it call this to pass the data on.
// This is also called when controller requests the update, like folder has been changed.
//
- (void)refreshView:(NPFolder*)inFolder withEntryList:(EntryList*)withEntryList {
    self.folder = inFolder;

    DLog(@"MonthViewHelper receives data from CalendarViewController: %@ %@", withEntryList.startDate, withEntryList.endDate);
    
    //
    // We want to make sure the entry list is for at least ONE FULL month
    //
    NSArray *monthStartEndDates = [DateUtil findMonthStartEndDate:withEntryList.startDate];
    NSDate *monthStartDate = [monthStartEndDates objectAtIndex:0];
    NSDate *monthEndDate = [monthStartEndDates objectAtIndex:1];
    
    if (([withEntryList.startDate compare:monthStartDate] == NSOrderedAscending ||
         [withEntryList.startDate compare:monthStartDate] == NSOrderedSame)
        &&
        ([monthEndDate compare:withEntryList.endDate] == NSOrderedAscending ||
         [monthEndDate compare:withEntryList.endDate] == NSOrderedSame))
    {
        NSMutableDictionary *eventsArrByMonth = [[NSMutableDictionary alloc] init];
        
        NSArray *firstDatesOfMonths = [DateUtil firstDateOfMonthBetweenDates:withEntryList.startDate toDate:withEntryList.endDate];
        for (NSDate *firstDate in firstDatesOfMonths) {
            NSString *yyyymm = [DateUtil convertToYYYYMM:firstDate];
            if ([eventsArrByMonth objectForKey:yyyymm] == nil) {
                [eventsArrByMonth setObject:[[NSMutableArray alloc] init] forKey:yyyymm];
            }
        }

        for (NPEvent *event in withEntryList.entries) {
            NSString *yyyymm = [DateUtil convertToYYYYMM:event.startTime];
            NSMutableArray *events = [eventsArrByMonth objectForKey:yyyymm];
            [events addObject:event];
        }

        // Update the local data
        for (NSString *ym in eventsArrByMonth) {
            EntryList *eventListObj = [[EntryList alloc] initList:self.folder entryTemplateId:event];
            eventListObj.entries = [eventsArrByMonth objectForKey:ym];
            [self.eventListObjectByMonth setObject:eventListObj forKey:ym];
        }

        // Refresh CalendarMonthView with data set.
        [self.monthView refreshCalendarMonthView:eventsArrByMonth];
    }
}


// When the controller changes the folder, the data is cleared and month view is reloaded.
- (void)clearMonthViewData {
    [self.eventListObjectByMonth removeAllObjects];      // Clear the data, do not nil it since it will still be used.
    [self hideDayEventTable];                   // Clear the screen
}


// When the month view is tapped, hide the day event flyout.
- (void)monthViewTapped:(UITapGestureRecognizer *)recognizer {
    [self hideDayEventTable];
}

- (void)didScrollMonthView {
    [self hideDayEventTable];
}

- (void)showDayEventTable {
    [self.parentView bringSubviewToFront:self.dayEventTableView];
    
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.5];
    
    CGRect rect = self.dayEventTableView.frame;
    
    NSInteger eventCount = [[self getDayEvents:self.currentSelectedDate] count];
    if (eventCount > 4) {
        eventCount = 4;
    }
    
    // table height
    rect.size.height = 55.0*eventCount + 44.0;          // 44 is the section header height
    
    // table y position
    float yPos = self.parentView.frame.size.height - 5.0 - rect.size.height;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        yPos = self.parentView.frame.size.height - 5.0 - rect.size.height;
    }
    
    rect.origin.y = yPos;
    
    self.dayEventTableView.frame = rect;
    
    UIImageView *backGroundView = [[UIImageView alloc] init];
    UIImage *image = [self blurredSnapshot];
    backGroundView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIColor *tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
    
    image = [image applyBlurWithRadius:12 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
    
    backGroundView.image = [image applyLightEffect];

    self.dayEventTableView.backgroundColor = [UIColor clearColor];
    self.dayEventTableView.backgroundView = backGroundView;

    [self.dayEventTableView reloadData];

    [UIView commitAnimations];
}

-(UIImage *)blurredSnapshot {
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(self.dayEventTableView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    // There he is! The new API method
    [self.monthView drawViewHierarchyInRect:self.dayEventTableView.frame afterScreenUpdates:NO];
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    return snapshotImage;
}


- (void)hideDayEventTable {
    float yPos = [ViewDisplayHelper offsetYPosition];
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.4];
    CGRect rect = self.dayEventTableView.frame;
    rect.origin.y = yPos;
    self.dayEventTableView.frame = rect;
    [UIView commitAnimations];
    
    // Make sure everything is cleaned up.
    [self.monthView clearSelectedDate];
}

#pragma mark - month view delegate


// Display the events for the date
- (void)calendarView:(CalendarMonthView *)calendarView didSelectDate:(NSDate *)date {
    self.currentSelectedDate = date;
    
//    [self hideDayEventTable];

    if ([[self getDayEvents:self.currentSelectedDate] count] > 0) {
        [self showDayEventTable];
    }
}


#pragma mark - day event tableview delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger eventCount = [[self getDayEvents:self.currentSelectedDate] count];
    
    if (eventCount == 0) {
        // Display "nothing scheduled"
        return 1;
    } else {
        return [[self getDayEvents:self.currentSelectedDate] count];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    return 55.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44.0)];
    headerView.backgroundColor = [UIColor colorFromHexString:@"#D9EDF799"]; // 99 is for 60% transparency
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0.0f, 0.0f, headerView.frame.size.width, 1.0f);
    topBorder.backgroundColor = [UIColor lightBlue].CGColor;
    [headerView.layer addSublayer:topBorder];
    
    CGRect rect = headerView.frame;
    rect.origin.x = 5.0;
    rect.origin.y = 5.0;
    rect.size.height = 30.0;
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:rect];
    headerLabel.font = [UIFont boldSystemFontOfSize:17.0];;
    headerLabel.text = [NSDateFormatter localizedStringFromDate:self.currentSelectedDate dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle];

    [headerView addSubview:headerLabel];
    
    return headerView;
}

// Remove the bottom line
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dayEvents = [self getDayEvents:self.currentSelectedDate];
    
    if (dayEvents.count == 0) {
        return [UITableViewCell emptyListMessageCell:NSLocalizedString(@"Nothing scheduled",)];
        
    } else {
        NPEvent *evt = [dayEvents objectAtIndex:indexPath.row];
        
        static NSString *CellIdentifier = @"EventListCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = evt.title;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        cell.detailTextLabel.text = evt.eventTimeText;
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        cell.imageView.image = [self getDot:evt.colorLabel];
                
        cell.textLabel.backgroundColor = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor whiteColor];
        
        return cell;
        
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dayEvents = [self getDayEvents:self.currentSelectedDate];

    NPEvent *event = [dayEvents objectAtIndex:indexPath.row];
    [self.controllerDelegate displayEventDetail:event];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (NSArray*)getDayEvents:(NSDate*)date {
    NSString *ym = [DateUtil convertToYYYYMM:date];
    NSString *ymd = [DateUtil convertToYYYYMMDD:date];

    EntryList *eventListObj = [self.eventListObjectByMonth objectForKey:ym];
    NSArray *events = eventListObj.entries;
    
    NSMutableArray *dayEvents = [[NSMutableArray alloc] init];
    
    if (events != nil) {
        for (NPEvent *event in events) {
            if ([ymd isEqualToString:[DateUtil convertToYYYYMMDD:event.startTime]]) {
                [dayEvents addObject:event];
            }
        }
    }
    
    return dayEvents;
}


// Reset the frames
- (void)rotate:(CGRect)newFrame {
    self.monthView.frame = newFrame;
    CGRect dayEventsTableFrame = self.dayEventTableView.frame;
    dayEventsTableFrame.size.width = newFrame.size.width;
    self.dayEventTableView.frame = dayEventsTableFrame;
    
    [self hideDayEventTable];
}

- (UIImage*)getDot:(NSString*)colorHexStr {
    UIImage *dot = nil;
    
    if (_dots == nil) {
        _dots = [[NSMutableDictionary alloc] init];
    }
    
    if ([_dots objectForKey:colorHexStr] != nil) {
        return [_dots objectForKey:colorHexStr];
        
    } else {
        UIGraphicsBeginImageContext(CGSizeMake(15.0f, 15.0f));
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(contextRef, [[UIColor colorFromHexString:colorHexStr] CGColor]);
        CGContextFillEllipseInRect(contextRef,(CGRectMake (0.f, 0.f, 15.0f, 15.0f)));
        dot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [_dots setObject:dot forKey:colorHexStr];
        return dot;
    }
}

@end
