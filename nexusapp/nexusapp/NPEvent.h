//
//  Event.h
//  nexuspad
//
//  Created by Ren Liu on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "Recurrence.h"
#import "Attendee.h"
#import "Reminder.h"

@interface NPEvent : NPEntry

@property int recurId;

@property BOOL singleTimeEvent;
@property BOOL allDayEvent;
@property BOOL noStartingTime;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSTimeZone *timeZone;

@property (nonatomic, strong) Recurrence *recurrence;
@property (nonatomic, strong) NSMutableArray *reminders;
@property (nonatomic, strong) NSMutableArray *attendees;

@property RecurEventUpdateOption recurUpdateOption;


- (id)initWithDate:(NSDate*)aDate;

- (NSString*)eventTimeText;
- (NSString*)reminderText;
- (NSString*)attendeeText;

- (BOOL)isRecurring;

- (BOOL)isPastEventToDate:(NSDate*)date;

- (BOOL)overlaps:(NPEvent*)anotherEvent;

- (NSString*)eventDisplayTime;

+ (NPEvent*)eventFromEntry:(NPEntry*)entry;

+ (NSArray*)splitMultiDayEvent:(NPEvent*)anEvent;                   // Explode a multi-day event for UI display
+ (NSArray*)splitRecurringEvent:(NPEvent*)anEvent;                  // Split recurring event into multiple records

@end
