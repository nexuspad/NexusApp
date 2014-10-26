//
//  EventDayViewPresenter.m
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import "DayViewHelper.h"
#import "EventDayScrollView.h"
#import "DateUtil.h"
#import "ViewDisplayHelper.h"
#import "UIColor+NPColor.h"


@interface DayViewHelper ()
@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) NSArray *sortedHourlyEvents;
@property (nonatomic, strong) NSMutableArray *overlappedEventGroups;
@property (nonatomic, strong) NSMutableDictionary *dayViewBuffer;
@end


@implementation DayViewHelper


- (id)initWithDate:(NSDate*)date {
    self = [super init];
    
    self.currentDate = date;
    [self initHourGridTable:YES];

    return self;
}


- (void)initHourGridTable:(BOOL)animated {
    DLog(@"Initialize the hour grid tables with date: %@", self.currentDate);
    
    NSMutableArray *initialPages = [[NSMutableArray alloc] initWithCapacity:3];
    
    NSDate *previousDate = [DateUtil addDays:self.currentDate days:-1];
    [initialPages addObject:[self getEventDayViewTable:previousDate]];
    
    [initialPages addObject:[self getEventDayViewTable:self.currentDate]];
    
    NSDate *nextDate = [DateUtil addDays:self.currentDate days:+1];
    [initialPages addObject:[self getEventDayViewTable:nextDate]];
    
    CGRect rect;
    
//    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
//        rect = [ViewDisplayHelper contentViewRect:64.0 heightAdjustment:0];
//    } else {
//        rect = [ViewDisplayHelper contentViewRect:52.0 heightAdjustment:0];
//    }
    
    rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
    
    self.dayScrollView = [[NPScrollView alloc] initWithPageViews:rect pageViews:initialPages startingIndex:99 backgroundColor:[UIColor whiteColor]];
    self.dayScrollView.dataDelegate = self;
}


// Refresh the current view with provided data from the view controller
- (void)refreshView:(NSDate*)forDate inFolder:(NPFolder*)inFolder withEntryList:(EntryList*)withEntryList {
    self.currentDate = forDate;
    self.folder = inFolder;

    NSString *ymd = [DateUtil convertToYYYYMMDD:forDate];
    
    EventDayScrollView* eventDayView = (EventDayScrollView*)[_dayViewBuffer objectForKey:ymd];
    
    if (inFolder.colorLabel != nil) {
        [eventDayView setCalendarColor:[UIColor colorFromHexString:inFolder.colorLabel]];
    }
    
    DLog(@"Refresh the event day view for selected date: %@", self.currentDate);
    DLog(@"Current active day view tag: %li", (long)eventDayView.tag);
    
    if (eventDayView.tag != [ymd intValue]) {
        return;
    }
    
    // Make sure to clean up all data and views.
    NSMutableArray *dayEvents = [[NSMutableArray alloc] init];
    
    self.sortedHourlyEvents = nil;
    self.overlappedEventGroups = nil;
    
    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
    
    for (id evt in withEntryList.entries) {
        NSArray *eventDayParts = [NPEvent splitMultiDayEvent:evt];
        
        // Filter out the parts that are outside the selected date.
        for (NPEvent *evtPart in eventDayParts) {
            if ([DateUtil isSameDate:evtPart.startTime anotherDate:self.currentDate]) {
                if (evtPart.allDayEvent || evtPart.noStartingTime) {
                    [dayEvents addObject:evtPart];
                } else {
                    [tmpArray addObject:evtPart];
                }
            }
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    self.sortedHourlyEvents = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
    
    NSInteger cnt = [self.sortedHourlyEvents count];
    
    if (cnt > 0) {
        NSMutableArray *firstGroup = [NSMutableArray arrayWithObject:[self.sortedHourlyEvents objectAtIndex:0]];
        self.overlappedEventGroups = [NSMutableArray arrayWithObject:firstGroup];
        
        // Now go through the rest of the events
        for (int i=1; i<cnt; i++) {
            NPEvent *theEvent = [self.sortedHourlyEvents objectAtIndex:i];
            
            BOOL eventAddedToGroup = NO;
            
            for (NSMutableArray *thisGroup in self.overlappedEventGroups) {
                BOOL overlapWithAllEventInGroup = YES;                      // Assume overlapping
                for (NPEvent *eventInGroup in thisGroup) {
                    if (![theEvent overlaps:eventInGroup]) {
                        overlapWithAllEventInGroup = NO;
                        break;
                    }
                }
                if (overlapWithAllEventInGroup == YES) {
                    [thisGroup addObject:theEvent];
                    eventAddedToGroup = YES;
                }
            }
            
            if (eventAddedToGroup == NO) {
                NSMutableArray *newGroup = [[NSMutableArray alloc] initWithCapacity:1];
                [newGroup addObject:theEvent];
                [self.overlappedEventGroups addObject:newGroup];
            }
        }
    }
    
    NSMutableArray *eventsInfo = [[NSMutableArray alloc] init];
    
    for (NSMutableArray *overlapGroup in self.overlappedEventGroups) {
        NSInteger overlapCount = [overlapGroup count];
        for (NSInteger i=0; i<overlapCount; i++) {
            NPEvent *e = [overlapGroup objectAtIndex:i];
            
            NSDictionary *eventInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:e,
                                                                           [NSNumber numberWithInteger:overlapCount],
                                                                           [NSNumber numberWithInteger:i],
                                                                           nil]
                                                                  forKeys:[NSArray arrayWithObjects:@"EVENT", @"OVERLAPS", @"INDENTATION", nil]];
            
            [eventsInfo addObject:eventInfo];
        }
    }
    
    [eventDayView displayEvents:dayEvents hourEventsInfo:eventsInfo];
}


- (UIView*)clearDataAndRefreshDayView:(NSDate*)forDate inFolder:(NPFolder*)inFolder {
    self.currentDate = forDate;
    self.folder = inFolder;
    
    [self.dayViewBuffer removeAllObjects];
    [self initHourGridTable:YES];
    
    return self.dayScrollView;
}


- (EventDayScrollView*)getEventDayViewTable:(NSDate*)forDate {
    if (_dayViewBuffer == nil) {
        _dayViewBuffer = [[NSMutableDictionary alloc] init];
    }
    
    NSString *ymd = [DateUtil convertToYYYYMMDD:forDate];
    
    EventDayScrollView *hourGridTableView = [_dayViewBuffer objectForKey:ymd];
    
    if (hourGridTableView == nil) {
        CGRect rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
        rect.origin.x = 0.0;
        rect.origin.y = 0.0;
        
        hourGridTableView = [[EventDayScrollView alloc] initWithFrame:rect];
        
        hourGridTableView.tag = [ymd intValue];
        hourGridTableView.eventViewDelegate = self;
        
        if (self.folder != nil && self.folder.colorLabel != nil) {
            [hourGridTableView setCalendarColor:[UIColor colorFromHexString:self.folder.colorLabel]];
        }
        
        [_dayViewBuffer setObject:hourGridTableView forKey:ymd];
    }
    
    return hourGridTableView;
}

#pragma mark - scrollview delegate

- (id)getLeftPageView:(NSInteger)pageViewTag {
    DLog(@"Display event day view at index %li", (long)pageViewTag);
    
    NSString *ymd = [NSString stringWithFormat:@"%li", (long)pageViewTag];
    self.currentDate = [DateUtil parseFromYYYYMMDD:ymd];
    
    NSDate *previousDate = [DateUtil addDays:self.currentDate days:-1];
    EventDayScrollView *theView = [self getEventDayViewTable:previousDate];
    
    [self.controllerDelegate changeCalendarViewDate:self.currentDate];
    
    return theView;
}

- (id)getRightPageView:(NSInteger)pageViewTag {
    DLog(@"Display event day view at index %li", (long)pageViewTag);
    
    NSString *ymd = [NSString stringWithFormat:@"%li", (long)pageViewTag];
    self.currentDate = [DateUtil parseFromYYYYMMDD:ymd];
    
    NSDate *nextDate = [DateUtil addDays:self.currentDate days:1];
    EventDayScrollView *theView = [self getEventDayViewTable:nextDate];
    
    [self.controllerDelegate changeCalendarViewDate:self.currentDate];
    
    return theView;
}

#pragma mark - event day view delegate

- (void)openEventDetail:(NPEvent *)event {
    [self.controllerDelegate displayEventDetail:event];
}


- (EntryList*)buildTestEvents
{
    NSMutableArray *events = [[NSMutableArray alloc] init];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd kk:mm:ss"];
    [df setTimeZone:[NSTimeZone timeZoneWithName:@"America/New_York"]];
    
    NPEvent *testEvent1 = [[NPEvent alloc] initWithDate:nil];
    
    testEvent1.entryId = @"11111";
    testEvent1.title = @"this is test event 1";
    testEvent1.startTime = [df dateFromString: @"2013-09-04 09:00:00"];
    testEvent1.endTime = [df dateFromString: @"2013-09-04 10:30:00"];
    [events addObject:testEvent1];
    
    NPEvent *testEvent2 = [[NPEvent alloc] initWithDate:nil];
    testEvent2.entryId = @"22222";
    testEvent2.title = @"this is test event 2";
    testEvent2.startTime = [df dateFromString: @"2013-09-04 09:30:00"];
    testEvent2.endTime = [df dateFromString: @"2013-09-04 10:30:00"];
    [events addObject:testEvent2];
    
    NPEvent *testEvent6 = [[NPEvent alloc] initWithDate:nil];
    testEvent6.entryId = @"66666";
    testEvent6.title = @"this is test event 6";
    testEvent6.startTime = [df dateFromString: @"2013-09-04 10:15:00"];
    testEvent6.endTime = [df dateFromString: @"2013-09-04 11:45:00"];
    [events addObject:testEvent6];
    
    NPEvent *testEvent3 = [[NPEvent alloc] initWithDate:nil];
    testEvent3.entryId = @"33333";
    testEvent3.title = @"this is test event 3";
    testEvent3.singleTimeEvent = YES;
    testEvent3.startTime = [df dateFromString: @"2013-09-04 06:30:00"];
    [events addObject:testEvent3];
    
    NPEvent *testEvent4 = [[NPEvent alloc] initWithDate:nil];
    testEvent4.entryId = @"44444";
    testEvent4.title = @"this is test event 4";
    testEvent4.allDayEvent = YES;
    testEvent4.startTime = [df dateFromString: @"2013-09-04 09:30:00"];
    [events addObject:testEvent4];
    
    NPEvent *testEvent5 = [[NPEvent alloc] initWithDate:nil];
    testEvent5.entryId = @"55555";
    testEvent5.title = @"this is test event 5";
    testEvent5.noStartingTime = YES;
    testEvent5.startTime = [df dateFromString: @"2013-09-04 09:30:00"];
    [events addObject:testEvent5];
    
    EntryList *eventList = [[EntryList alloc] init];
    eventList.entries = events;
    
    return eventList;
}

@end
