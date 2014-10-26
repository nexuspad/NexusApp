//
//  Event.m
//  nexuspad
//
//  Created by Ren Liu on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPEvent.h"
#import "DateUtil.h"
#import "NSString+NPStringUtil.h"
#import "NSDictionary+NPUtil.h"

@implementation NPEvent

@synthesize entryId = _entryId;
@synthesize recurId = _recurId;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize timeZone = _timeZone;
@synthesize singleTimeEvent, allDayEvent, noStartingTime;
@synthesize recurrence = _recurrence;
@synthesize reminders = _reminders;
@synthesize attendees = _attendees;

- (id)init {
    self = [super init];
    if (self) {
        self.folder.moduleId = CALENDAR_MODULE;
        self.templateId = event;
        self.recurId = 1;
        return self;
    }
    
    return self;
}

- (id)initWithDate:(NSDate*)aDate
{
    self = [super init];
    if (self) {
        self.folder.moduleId = CALENDAR_MODULE;
        
        self.recurId = 1;

        self.allDayEvent = NO;
        self.singleTimeEvent = NO;
        self.noStartingTime = NO;

        if (aDate == nil) {
            aDate = [NSDate date];
        }
        
        NSDateComponents *time = [[NSCalendar currentCalendar]
                                  components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute
                                  fromDate:aDate];

        NSInteger minutes = [time minute];
        float minuteUnit = ceil((float) minutes / 15.0);
        minutes = minuteUnit * 15.0;
        [time setMinute: minutes];

        self.startTime = [[NSCalendar currentCalendar] dateFromComponents:time];
        self.timeZone = [NSTimeZone localTimeZone];
        self.recurrence = [[Recurrence alloc] init];
        
        self.templateId = event;

        return self;
    }
    
    return self;
}


- (void)setEntryId:(NSString *)entryId {
    if ([entryId stringContains:@","]) {
        NSArray *pieces = [entryId componentsSeparatedByString:@","];
        _entryId = [NSString stringWithFormat:@"%@", pieces[0]];
        _recurId = (int)[pieces[1] integerValue];

    } else {
        if (entryId != nil) {
            _entryId = [NSString stringWithString:entryId];
        }
    }
}

- (id)copyWithZone:(NSZone*)zone
{
    NPEvent *event = [[NPEvent alloc] initWithDate:nil];
    [event copyBasic:self];
    
    if (self.recurId != 0) {
        event.recurId = self.recurId;
    }
    
    event.startTime = [self.startTime copy];
    event.endTime = [self.endTime copy];
    event.timeZone = [NSTimeZone timeZoneWithName:self.timeZone.name];

    event.singleTimeEvent = self.singleTimeEvent;
    event.allDayEvent = self.allDayEvent;
    event.noStartingTime = self.noStartingTime;

    event.recurrence = [self.recurrence copy];
    event.attendees = [self.attendees mutableCopy];
    event.reminders = [self.reminders mutableCopy];

    event.recurUpdateOption = self.recurUpdateOption;

    return event;
}

- (void)setStartTime:(NSDate *)startTime
{
    _startTime = startTime;
}

- (void)setEndTime:(NSDate *)endTime
{
    _endTime = endTime;
}

// Display a friendly time string for UI
- (NSString*)eventDisplayTime {
    if ([self allDayEvent]) {
        return NSLocalizedString(@"All day", );
    }
    
    if ([self noStartingTime]) {
        return @"";
    }
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"h:mm a"];
    NSString *timeStr = [timeFormatter stringFromDate:self.startTime];
    
    if ([timeStr isEqualToString:@"12:00 AM"]) {
        return @"";
    } else if ([timeStr isEqualToString:@"11:59 PM"]) {
        return @"";
    }
    
    return timeStr;
}


- (NSString*)eventTimeText {
    NSMutableString *eventTimeText = [[NSMutableString alloc] init];

    if (self.allDayEvent) {
        [eventTimeText appendString:@"All day"];

    } else {
        if (self.noStartingTime == NO) {
            if (self.startTime != nil && self.endTime != nil && ![self.startTime isEqualToDate:self.endTime]) {
                NSString *startTimeStr = [DateUtil displayEventTime:self.startTime];
                if (![NSString isBlank:startTimeStr]) {
                    [eventTimeText appendString:startTimeStr];
                    NSString *endTimeStr = [DateUtil displayEventTime:self.endTime];
                    if (![NSString isBlank:endTimeStr]) {
                        [eventTimeText appendString:@" - "];
                        [eventTimeText appendString:endTimeStr];
                    }
                }
                
            } else if (self.startTime != nil) {
                [eventTimeText appendString:[DateUtil displayEventTime:self.startTime]];
            }
        }
    }
         
    [eventTimeText appendString:@" "];
    if (self.recurrence.pattern != norepeat) {
        [eventTimeText appendString:[self.recurrence repeatDescriptionString:NO]];
    }

    return eventTimeText;
}


- (NSString*)reminderText {
    if (self.reminders != nil && [self.reminders count] > 0) {
        Reminder *firstRem = [self.reminders objectAtIndex:0];
        NSMutableString *reminderText = [NSMutableString stringWithFormat:@"%@", firstRem.deliverAddress];
        if ([self.reminders count] > 1) {
            [reminderText appendString:@" ..."];
        }
        return reminderText;
    }
    
    return @"";
}

- (NSString*)attendeeText
{
    if (self.attendees != nil && [self.attendees count] > 0) {
        Attendee *firstAtt = [self.attendees objectAtIndex:0];
        NSMutableString *attendeeText = [NSMutableString stringWithFormat:@"%@", [firstAtt getNameOrEmail]];
        if ([self.attendees count] > 1) {
            [attendeeText appendString:@" ..."];
        }
        return attendeeText;
    }
    
    return @"";
}

- (NSString*)description
{
    NSMutableString *desc = [NSMutableString stringWithFormat:@"%@  recurId:%d [%@] [%@]", [super description], self.recurId, [self.startTime description], [self.endTime description]];
    
    if (self.allDayEvent) {
        [desc appendString:@", all day event"];
    }
    if (self.singleTimeEvent) {
        [desc appendString:@", single time event"];
    }
    if (self.noStartingTime) {
        [desc appendString:@", no starting time"];
    }

    return desc;
}

- (BOOL)isRecurring {
    if (self.recurrence != nil && self.recurrence.pattern != norepeat) {
        return YES;
    }
    return NO;
}

- (BOOL)isPastEventToDate:(NSDate*)date
{
    if ([self.startTime compare:date] == NSOrderedAscending) {
        return YES;
    }
    return NO;
}

- (BOOL)overlaps:(NPEvent*)anotherEvent
{
    if (self.allDayEvent || self.noStartingTime || self.singleTimeEvent) return NO;
    if (anotherEvent.allDayEvent || anotherEvent.noStartingTime || anotherEvent.singleTimeEvent) return NO;

    // Check the below 2 cases first.
    if ([self.endTime compare:anotherEvent.startTime] == NSOrderedSame || [self.endTime compare:anotherEvent.startTime] == NSOrderedAscending) {
        return NO;
    }

    if ([anotherEvent.endTime compare:self.startTime] == NSOrderedSame || [anotherEvent.endTime compare:self.startTime] == NSOrderedAscending) {
        return NO;
    }

    if ([DateUtil date:self.startTime isBetweenDate:anotherEvent.startTime andDate:anotherEvent.endTime]) {
        return YES;
    }

    if ([DateUtil date:anotherEvent.startTime isBetweenDate:self.startTime andDate:self.endTime]) {
        return YES;
    }
    
    return NO;
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[super buildParamMap]];
    
    // Build location
    if (self.location != nil) {
        [params addEntriesFromDictionary:[self.location toDictionary]];
    }
    
    // Build time params
    if (self.allDayEvent) {
        [params setValue:[NSNumber numberWithInt:1] forKey:EVENT_ALL_DAY];
        
    } else if (self.noStartingTime) {
        [params setValue:[NSNumber numberWithInt:1] forKey:EVENT_NO_TIME];
        
    } else if (self.singleTimeEvent) {
        [params setValue:[NSNumber numberWithInt:1] forKey:EVENT_SINGLE_TIME];

    }

    [params setValue:[NSNumber numberWithLong:[self.startTime timeIntervalSince1970]] forKey:EVENT_START_TS];
    
    if (self.endTime != nil) {
        [params setValue:[NSNumber numberWithLong:[self.endTime timeIntervalSince1970]] forKey:EVENT_END_TS];   
    }
    
    [params setValue:[self.timeZone name] forKey:EVENT_TIMEZONE];

    // Build the recurrence
    NSString *recurInfo = [self.recurrence buildRecurJsonStringParam];
    if (recurInfo != nil) {
        [params setValue:recurInfo forKey:EVENT_RECURRENCE];
    }
    
    // Build attendees
    if ([self.attendees count] > 0) {
        NSMutableArray *attArr = [[NSMutableArray alloc] initWithCapacity:[self.attendees count]];
        for (Attendee *attObj in self.attendees) {
            [attArr addObject:[attObj toDictionary]];
        }
        [params setValue:[NSString convertDataToJsonString:attArr] forKey:EVENT_ATTENDEES];
    }
    
    // Build reminders
    if ([self.reminders count] > 0) {
        NSMutableArray *reminderArr = [[NSMutableArray alloc] initWithCapacity:[self.reminders count]];
        for (Reminder *rem in self.reminders) {
            [reminderArr addObject:[rem toDictionary]];
        }
        [params setValue:[NSString convertDataToJsonString:reminderArr] forKey:EVENT_REMINDER];
    }
    
    [params setValue:[NSString stringWithFormat:@"%d", self.recurId] forKey:EVENT_RECUR_ID];
    
    // Recur update options
    if (self.recurUpdateOption != UNDEFINED) {
        if (self.recurUpdateOption == ONE) {
            [params setValue:@"ONE" forKey:@"recur_update"];
        } else if (self.recurUpdateOption == FUTURE) {
            [params setValue:@"FUTURE" forKey:@"recur_update"];
        } else if (self.recurUpdateOption == ALL) {
            [params setValue:@"ALL" forKey:@"recur_update"];
        }
    }

    return params;
}

+ (NPEvent*)eventFromEntry:(NPEntry*)entry
{
    if ([entry isKindOfClass:[NPEvent class]]) {
        return (NPEvent*)entry;
    }
    
    if (entry == nil) {
        return nil;
    }

    NPEvent *event = [[NPEvent alloc] initWithNPEntry:entry];

    if (event.location == nil) {                        // location attribute could have been initialized in NPEntry
        event.location = [[NPLocation alloc] init];
    }
    
    if ([entry.featureValuesDict objectForKeyNotNull:LOCATION_NAME]) {
        event.location.locationName = [NSString stringWithString:[entry.featureValuesDict objectForKey:LOCATION_NAME]];
    }

    event.timeZone = [NSTimeZone localTimeZone];
    
    if ([entry.featureValuesDict objectForKeyNotNull:EVENT_RECUR_ID]) {
        NSString *recurIdStr = [entry.featureValuesDict valueForKey:EVENT_RECUR_ID];
        event.recurId = [recurIdStr intValue];

    } else {
        event.recurId = 1;
    }
    
    if ([entry.featureValuesDict objectForKey:EVENT_START_TS] != nil) {
        event.startTime = [NSDate dateWithTimeIntervalSince1970:[[entry.featureValuesDict valueForKey:EVENT_START_TS] doubleValue]];
    } else {
        DLog(@"Error: event has no start timestamp: %@", entry);
        return nil;
    }
    
    if ([entry.featureValuesDict objectForKey:EVENT_END_TS] != nil) {
        event.endTime = [NSDate dateWithTimeIntervalSince1970:[[entry.featureValuesDict valueForKey:EVENT_END_TS] doubleValue]];
    }

    if ([entry.featureValuesDict objectForKey:EVENT_SINGLE_TIME] != nil) {
        event.singleTimeEvent = [[entry.featureValuesDict valueForKey:EVENT_SINGLE_TIME] boolValue];
    } else {
        event.singleTimeEvent = NO;
    }
    
    if ([entry.featureValuesDict objectForKey:EVENT_NO_TIME] != nil) {
        event.noStartingTime = [[entry.featureValuesDict valueForKey:EVENT_NO_TIME] boolValue];
    } else {
        event.noStartingTime = NO;
    }
    
    if ([entry.featureValuesDict objectForKey:EVENT_ALL_DAY] != nil) {
        event.allDayEvent = [[entry.featureValuesDict valueForKey:EVENT_ALL_DAY] boolValue];
    } else {
        event.allDayEvent = NO;
    }
    
    // This is a sanity check on single time event. We only do this when allDayEvent and noStartingTime flags are not set.
    if (event.allDayEvent == NO && event.noStartingTime == NO)
    {
        if (event.startTime != nil && event.endTime != nil && [event.startTime compare:event.endTime] != NSOrderedSame) {
            event.singleTimeEvent = NO;
        } else {
            event.singleTimeEvent = YES;
        }
    }


    // Parse the recurrence.
    // Handles both NSDictionary and NSString
    if ([entry.featureValuesDict objectForKey:EVENT_RECURRENCE] != nil) {
        if ([[entry.featureValuesDict objectForKey:EVENT_RECURRENCE] isKindOfClass:[NSDictionary class]]) {
            event.recurrence = [[Recurrence alloc] initWithData:[entry.featureValuesDict objectForKey:EVENT_RECURRENCE]];
            [event.featureValuesDict removeObjectForKey:EVENT_RECURRENCE];
        
        } else if ([[entry.featureValuesDict objectForKey:EVENT_RECURRENCE] isKindOfClass:[NSString class]]) {
            NSString *recurJsonStr = [entry.featureValuesDict objectForKey:EVENT_RECURRENCE];
            NSDictionary *recurDict = [NSJSONSerialization JSONObjectWithData:[recurJsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:nil];
            event.recurrence = [[Recurrence alloc] initWithData:recurDict];
            [event.featureValuesDict removeObjectForKey:EVENT_RECURRENCE];
        }

    } else {
        event.recurrence = [[Recurrence alloc] init];
    }
    

    // Parse the attendees
    // Handles both NSDictionary and NSString
    if ([entry.featureValuesDict objectForKeyNotNull:EVENT_ATTENDEES]) {
        event.attendees = [[NSMutableArray alloc] init];

        if ([[entry.featureValuesDict objectForKey:EVENT_ATTENDEES] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *attDict in [entry.featureValuesDict objectForKey:EVENT_ATTENDEES]) {
                Attendee *att = [[Attendee alloc] initWithData:attDict];
                [event.attendees addObject:att];
            }
            [event.featureValuesDict removeObjectForKey:EVENT_ATTENDEES];

        } else if ([[entry.featureValuesDict objectForKey:EVENT_ATTENDEES] isKindOfClass:[NSString class]]) {
            NSString *attendeeStr = [entry.featureValuesDict objectForKey:EVENT_ATTENDEES];
            NSArray *attendeeDictArr = [NSJSONSerialization JSONObjectWithData:[attendeeStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:nil];
            
            for (NSDictionary *attDict in attendeeDictArr) {
                Attendee *att = [[Attendee alloc] initWithData:attDict];
                [event.attendees addObject:att];
            }
            [event.featureValuesDict removeObjectForKey:EVENT_ATTENDEES];
        }
    }

    
    // Parse reminders
    // Handles both NSDictionary and NSString
    if ([entry.featureValuesDict objectForKeyNotNull:EVENT_REMINDER]) {
        event.reminders = [[NSMutableArray alloc] init];

        if ([[entry.featureValuesDict objectForKey:EVENT_REMINDER] isKindOfClass:[NSArray class]]) {
            for (NSDictionary *remDict in [entry.featureValuesDict objectForKey:EVENT_REMINDER]) {
                Reminder *rem = [[Reminder alloc] initWithData:remDict];
                [event.reminders addObject:rem];
            }
            [event.featureValuesDict removeObjectForKey:EVENT_REMINDER];

        } else if ([[entry.featureValuesDict objectForKey:EVENT_REMINDER] isKindOfClass:[NSString class]]) {
            NSString *reminderStr = [entry.featureValuesDict objectForKey:EVENT_REMINDER];
            NSArray *reminderDictArr = [NSJSONSerialization JSONObjectWithData:[reminderStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:nil];
            
            for (NSDictionary *remDict in reminderDictArr) {
                Reminder *rem = [[Reminder alloc] initWithData:remDict];
                [event.reminders addObject:rem];
            }
            [event.featureValuesDict removeObjectForKey:EVENT_REMINDER];
        }
    }
    

    // The recur_update information is used when posting change on a recurring event.
    // If device is offline, the field is collected in buildParams method and stored in entry store.
    // When the device gets online and sync starts, the information is read out of entry store, and here,
    // We need to use it.
    if ([event.featureValuesDict objectForKeyNotNull:@"recur_update"]) {
        NSString *option = [event.featureValuesDict valueForKey:@"recur_update"];
        if( [option caseInsensitiveCompare:@"ONE"] == NSOrderedSame ) {
            event.recurUpdateOption = ONE;
        } else if( [option caseInsensitiveCompare:@"FUTURE"] == NSOrderedSame ) {
            event.recurUpdateOption = FUTURE;
        } else if( [option caseInsensitiveCompare:@"ALL"] == NSOrderedSame ) {
            event.recurUpdateOption = ALL;
        }
    }
    
    return event;
}


// Split a multi-day event into several events
+ (NSArray*)splitMultiDayEvent:(NPEvent*)anEvent
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *startDateOnly = [DateUtil dateOnly:anEvent.startTime];    
    NSDate *endDateOnly = [DateUtil dateOnly:anEvent.endTime];
    
    if ([startDateOnly compare:endDateOnly] == NSOrderedSame) {
        return [NSArray arrayWithObject:anEvent];

    } else {
        
        NSMutableArray *events = [[NSMutableArray alloc] init];
        int numOfDays = [endDateOnly timeIntervalSinceDate:startDateOnly]/86400;
        
        NPEvent *firstDayPart = [anEvent copy];
        NSDateComponents *components = [calendar components:NSCalendarUnitMinute fromDate:anEvent.startTime];
        if ([components minute] == 0) {
            firstDayPart.endTime = [firstDayPart.startTime copy];
            firstDayPart.allDayEvent = YES;
        } else {
            firstDayPart.endTime = [startDateOnly dateByAddingTimeInterval:86400];      // Adjust the end time to the end of the day
        }
        [events addObject:firstDayPart];

        for (int i=1; i<numOfDays; i++) {
            NSDateComponents *components = [[NSDateComponents alloc] init];
            [components setDay:i];
            
            NSDate *aDate = [calendar dateByAddingComponents:components toDate:startDateOnly options:0];
            NPEvent *evtInTheMiddle = [anEvent copy];
            evtInTheMiddle.startTime = [aDate copy];
            evtInTheMiddle.endTime = [aDate copy];
            evtInTheMiddle.allDayEvent = YES;
            
            [events addObject:evtInTheMiddle];
        }
        
        NPEvent *lastDayPart = [anEvent copy];
        lastDayPart.startTime = endDateOnly;        // Set the start time to 12:00AM
        if ([lastDayPart.endTime timeIntervalSinceDate:lastDayPart.startTime] >= 86300) {
            lastDayPart.allDayEvent = YES;
        }
        [events addObject:lastDayPart];
        
        return events;
    }
}

+ (NSArray*)splitRecurringEvent:(NPEvent*)anEvent {
    if (!anEvent.isRecurring) {
        return [NSArray arrayWithObject:anEvent];
    }

    NSMutableArray *events = [[NSMutableArray alloc] init];
    
    return events;
}

@end

