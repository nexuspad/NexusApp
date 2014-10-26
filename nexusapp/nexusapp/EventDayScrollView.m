//
//  HourGridTableView.m
//  nexusapp
//
//  Created by Ren Liu on 9/3/13.
//
//

#import "QuartzCore/QuartzCore.h"
#import "EventDayScrollView.h"
#import "NPEvent.h"
#import "DateUtil.h"
#import "ViewDisplayHelper.h"
#import "EventHourGridView.h"
#import "UIColor+NPColor.h"
#import "UITableView+NPAnime.h"

static const float DAY_VIEW_CELL_HEIGHT   = 30.0;
static const float HOUR_GRID_HEIGHT       = 48.0;
static const float EVENT_INDENTATION      = 55.0;

static const NSArray *hours;

@interface EventDayScrollView ()
@property (nonatomic, strong) NSArray *dayEvents;
@property (nonatomic, strong) NSMutableArray *allEventViews;
@property (nonatomic, strong) UITableView *dayEventsView;               // Display day events
@property (nonatomic, strong) UITableView *hourGridTableView;           // Display hourly events
@property (nonatomic, strong) UIView *nowLine;
@end

@implementation EventDayScrollView

@synthesize calendarColor = _calendarColor;

// |-----------------------|
// |- day events table ----|
// |                       |
// |  |-- hour grids ---|  |
// |  |                 |  |
// |  |                 |  |
// -------------------------
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [UIColor lightBlue];

        self.dayEventsView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        
        self.dayEventsView.tag = 100;
        self.dayEventsView.delegate = self;
        self.dayEventsView.dataSource = self;
        self.dayEventsView.backgroundView = nil;
        self.dayEventsView.backgroundColor = [UIColor darkBlue];
        
        [self addSubview:self.dayEventsView];

        self.hourGridTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        self.hourGridTableView.tag = 200;
        self.hourGridTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.hourGridTableView.delegate = self;
        self.hourGridTableView.dataSource = self;
        
        [self addSubview:self.hourGridTableView];
    }
    
    hours = [NSArray arrayWithObjects:@"12 AM", @"1 AM", @"2 AM", @"3 AM", @"4 AM", @"5 AM", @"6 AM", @"7 AM", @"8 AM", @"9 AM", @"10 AM", @"11 AM", @"Noon", @"1 PM", @"2 PM", @"3 PM", @"4 PM", @"5 PM", @"6 PM", @"7 PM", @"8 PM", @"9 PM", @"10 PM", @"11 PM", @"12 PM", nil];
    
    return self;
}

- (void)setCalendarColor:(UIColor *)calendarColor {
    _calendarColor = calendarColor;
    self.backgroundColor = _calendarColor;
    self.dayEventsView.backgroundColor = _calendarColor;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    if (tableView.tag == 100) {
        return DAY_VIEW_CELL_HEIGHT;
    }
    return HOUR_GRID_HEIGHT/2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 100) {         // The day event table
        return self.dayEvents.count;
    }
    return 50;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 100) {         // The day event table
        NSString *CellIdentifier = [NSString stringWithFormat:@"DayEventCell"];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        }

        NPEvent *e = [self.dayEvents objectAtIndex:indexPath.row];
        NSString *timeStr = [e eventDisplayTime];

        if (timeStr.length > 0) {
            cell.textLabel.text = [NSString stringWithFormat:@" %@ ", [e eventDisplayTime]];
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@" %@ ", [DateUtil displayDate:e.startTime]];
        }

        cell.detailTextLabel.text = e.title;
        
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
        
        return cell;
    }

    NSString *CellIdentifier = [NSString stringWithFormat:@"HourGridCell%li", (long)indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
        
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.userInteractionEnabled = NO;
    
    [self showHourMarks:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 100) {
        NPEvent *e = [self.dayEvents objectAtIndex:indexPath.row];

        cell.backgroundColor = [UIColor whiteColor];

        UIColor *eventBgColor = [[UIColor colorFromHexString:e.colorLabel] colorWithAlphaComponent:0.75];
        UIColor *textColor = [UIColor textColorFromBackground:eventBgColor];
        
        cell.textLabel.backgroundColor = eventBgColor;
        cell.textLabel.textColor = textColor;
        cell.textLabel.layer.cornerRadius = 4.0;
        cell.textLabel.layer.masksToBounds = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 100) {
        [self openEventDetail:[self.dayEvents objectAtIndex:indexPath.row]];
    }
}

# pragma mark - display hour labels.

- (void)showHourMarks:(NSIndexPath*)atIndex {
    if (atIndex.row%2 == 0) {
        NSString *hourMark = [hours objectAtIndex:(atIndex.row/2)];
        
        UILabel *hourLabel = [[UILabel alloc] init];
        
        hourLabel.backgroundColor = [UIColor whiteColor];

        hourLabel.text = [NSString stringWithFormat:@" %@ ", hourMark];
        
        int yPos = HOUR_GRID_HEIGHT/2 * atIndex.row - 10;
        
        hourLabel.frame = CGRectMake(12.0, yPos, 43.0, 20.0);
        hourLabel.font = [UIFont boldSystemFontOfSize:12.0];
        hourLabel.textAlignment = NSTextAlignmentLeft;
        
        hourLabel.layer.zPosition = 1;
        
        [self.hourGridTableView addSubview:hourLabel];
    }
}


#pragma mark - display events

- (void)displayEvents:(NSArray*)dayEvents hourEventsInfo:(NSArray*)hourEventsInfo {
    [self clearEventViews];

    // Only reload table with animation under certain circumstance.
    if (self.dayEvents.count != dayEvents.count) {
        self.dayEvents = dayEvents;
        [self.dayEventsView reloadData:NO];
        
    } else {
        self.dayEvents = dayEvents;
        [self.dayEventsView reloadData:NO];
    }
    
    float yPos = 3;
    if (self.dayEvents.count > 0) {
        yPos = (DAY_VIEW_CELL_HEIGHT) * dayEvents.count + 3;
    }
    
    if (yPos > 160.0) {
        yPos = 160.0;
        
        // Reduce the height of the day event table
        CGRect dayEventRect = self.dayEventsView.frame;
        dayEventRect.size.height = 158.0;
        self.dayEventsView.frame = dayEventRect;
    }

    // Adjust the hour grid view position if necessary
    CGRect rect = self.hourGridTableView.frame;
    rect.origin.y = yPos;
    self.hourGridTableView.frame = rect;

    for (NSDictionary *eventInfo in hourEventsInfo) {
        NPEvent *e = [eventInfo objectForKey:@"EVENT"];
        int overlaps = [[eventInfo valueForKey:@"OVERLAPS"] intValue];
        int indentation = [[eventInfo valueForKey:@"INDENTATION"] intValue];
        
        [self showHourlyEventView:e overlaps:overlaps index:indentation];
    }
    
    [self scrollToCurrentHour];
}


- (void)showHourlyEventView:(NPEvent*)event overlaps:(int)overlaps index:(int)index {
    float yOffset = ([DateUtil minutesSinceMidnight:event.startTime]) * (HOUR_GRID_HEIGHT/60.0);
    
    float height = 20.0;
    
    if (!event.singleTimeEvent) {
        // Find out the height of the event
        int minutes = ([event.endTime timeIntervalSince1970] - [event.startTime timeIntervalSince1970])/60;
        height = (minutes/15) * HOUR_GRID_HEIGHT/4.0f;
    }
    
    // Find out the width of the event
    float fullWidth = [self eventFullWidth];
    
    float width = fullWidth/overlaps;
    
    float xOffset = EVENT_INDENTATION + (fullWidth/overlaps)*index;
    
    CGRect eventRect = CGRectMake(xOffset, yOffset, width, height);
    [self.hourGridTableView addSubview:[self getEventViewBlock:eventRect event:event]];
}


- (void)scrollToCurrentHour {
    NSInteger hour = [DateUtil getHour:[NSDate date]];
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:hour*2 inSection:0];
    [self.hourGridTableView scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    
    [self showCurrentTime];
}

- (void)showCurrentTime
{
    NSDate *currentDate = [NSDate date];
    NSInteger minutes = [DateUtil minutesSinceMidnight:currentDate];
    float yOffset = minutes * HOUR_GRID_HEIGHT / 60;
    
    CGRect lineRect = CGRectMake(10.0, yOffset, [ViewDisplayHelper screenWidth], 1.0);
    
    if (self.nowLine == nil) {
        self.nowLine = [[UIView alloc] initWithFrame:lineRect];
        self.nowLine.backgroundColor = [UIColor redColor];
        self.nowLine.layer.opacity = 0.6;
        [self.hourGridTableView addSubview:self.nowLine];
        
    } else {
        // It's already drawn, just re-position it.
        [self.hourGridTableView addSubview:self.nowLine];
        self.nowLine.frame = lineRect;
    }
}

# pragma mark - clear the views.

- (void)clearEventViews {
    NSInteger cnt = [self.allEventViews count];
    
    for (int i=0; i<cnt; i++) {
        EventHourGridView *eventView = [self.allEventViews objectAtIndex:i];
        while (eventView.gestureRecognizers.count) {
            [eventView removeGestureRecognizer:[eventView.gestureRecognizers objectAtIndex:0]];
        }
        
        [UIView animateWithDuration:0.4
                         animations:^{ eventView.alpha = 0.0; }
                         completion:^(BOOL finished) { [eventView removeFromSuperview]; }];
    }

    [self.allEventViews removeAllObjects];
    
    [self.nowLine removeFromSuperview];
}


- (EventHourGridView*)getEventViewBlock:(CGRect)eventRect event:(NPEvent*)event {
    EventHourGridView *eventView = [[EventHourGridView alloc] initWithFrameAndEvent:eventRect event:event];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openEventDetail:)];
    singleTap.delegate = self;
    [eventView addGestureRecognizer:singleTap];
    
    if (self.allEventViews == nil) {
        self.allEventViews = [[NSMutableArray alloc] init];
    }
    [self.allEventViews addObject:eventView];
    
    return eventView;
}

- (int)eventFullWidth {
    return [ViewDisplayHelper screenWidth] - EVENT_INDENTATION - 10;
}

- (void)openEventDetail:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        EventHourGridView *eventView = (EventHourGridView*)((UITapGestureRecognizer*)sender).view;
        [self.eventViewDelegate openEventDetail:eventView.event];
        
        NSIndexPath *tableSelection = [self.dayEventsView indexPathForSelectedRow];
        [self.dayEventsView deselectRowAtIndexPath:tableSelection animated:NO];

    } else if ([sender isKindOfClass:[NPEvent class]]) {
        [self.eventViewDelegate openEventDetail:(NPEvent*)sender];
    }
}

@end
