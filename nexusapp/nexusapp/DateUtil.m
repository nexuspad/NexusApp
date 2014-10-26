//
//  DateHelper.m
//  nexuspad
//
//  Created by Ren Liu on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DateUtil.h"

static NSDateFormatter *dateFormatter;

@implementation DateUtil

+ (NSDateFormatter*)initFormatter {
    if (dateFormatter != nil) return dateFormatter;
    dateFormatter = [[NSDateFormatter alloc] init];
    return dateFormatter;
}

+ (NSArray*)findMonthStartEndDate:(NSDate*)aDate {
    NSArray *ymdArr = [self getYmd:aDate];
    return [self findMonthStartEndDate:[[ymdArr objectAtIndex:0] intValue] month:[[ymdArr objectAtIndex:1] intValue]];
}

+ (NSArray*)findMonthStartEndDate:(NSInteger)year month:(NSInteger)month {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDate *firstDate = [self parseFromYYYYMMDD:[NSString stringWithFormat:@"%li%02li01", (long)year, (long)month]];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setMonth:1];
    [components setDay:-1];
    
    NSDate *lastDateOfMonth = [cal dateByAddingComponents:components toDate:firstDate options:0];
    
    return [NSArray arrayWithObjects:firstDate, lastDateOfMonth, nil];
}


+ (NSDate*)findLastDateOfMonth:(NSString*)yyyymm {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDate *firstDate = [self parseFromYYYYMMDD:[NSString stringWithFormat:@"%@01", yyyymm]];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setMonth:1];
    [components setDay:-1];
    
    return [cal dateByAddingComponents:components toDate:firstDate options:0];
}


+ (BOOL)isStartDateAndEndDateOfMonth:(NSDate*)startDate endDate:(NSDate*)endDate {
    NSArray *monthStartEndDates = [self findMonthStartEndDate:startDate];
    NSString *monthStartYmd = [DateUtil convertToYYYYMMDD:[monthStartEndDates objectAtIndex:0]];
    NSString *monthEndYmd = [DateUtil convertToYYYYMMDD:[monthStartEndDates objectAtIndex:1]];

    if ([[DateUtil convertToYYYYMMDD:startDate] isEqualToString:monthStartYmd] &&
        [[DateUtil convertToYYYYMMDD:endDate] isEqualToString:monthEndYmd])
    {
        return YES;
    }
    
    return NO;
}

+ (NSDate*)getFirstDayOfWeek:(NSDate*)aDate {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    // start of the week
    NSDate *firstDate;
    [cal rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&firstDate interval:0 forDate:aDate];

    return firstDate;
}

+ (NSDate*)getLastDayOfWeek:(NSDate*)aDate {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDate *aDateNextWeek = [self addWeeks:aDate weeks:1];
    
    NSDate *firstDateNextWeek;
    [cal rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&firstDateNextWeek interval:0 forDate:aDateNextWeek];
    
    return [self addDays:firstDateNextWeek days:-1];
}

+ (NSArray*)getYmd:(NSDate*)aDate {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:aDate];
    NSInteger startDay = [components day];
    NSInteger startMonth = [components month];
    NSInteger startYear = [components year];
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInteger:startYear], [NSNumber numberWithInteger:startMonth], [NSNumber numberWithInteger:startDay], nil];
}

+ (NSInteger)getYear:(NSDate*)aDate {
    return [[[self getYmd:aDate] objectAtIndex:0] intValue];
}

+ (NSInteger)getMonth:(NSDate*)aDate {
    return [[[self getYmd:aDate] objectAtIndex:1] intValue];
}

+ (NSInteger)getDay:(NSDate*)aDate {
    return [[[self getYmd:aDate] objectAtIndex:2] intValue];
}

+ (NSInteger)getHour:(NSDate*)aDate {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour fromDate:aDate];
    return [components hour];
}

+ (NSInteger)minutesSinceMidnight:(NSDate*)aDate {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:aDate];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];

    return hour*60 + minute;
}

+ (NSString*)convertToYYYYMMDD:(NSDate*)aDate {
    if (aDate == nil) return @"";
    dateFormatter = [self initFormatter];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString*)convertToYYYYMM:(NSDate*)aDate {
    if (aDate == nil) return @"";
    dateFormatter = [self initFormatter];
    [dateFormatter setDateFormat:@"yyyyMM"];
    return [dateFormatter stringFromDate:aDate];
}

+ (NSDate*)parseFromYYYYMMDD:(NSString*)ymd {
    dateFormatter = [self initFormatter];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    return [dateFormatter dateFromString:ymd];
}

+ (NSDate*)dateOnly:(NSDate*)dateAndTime {
    if (dateAndTime == nil) {
        return nil;
    }
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:flags fromDate:dateAndTime];
    return [calendar dateFromComponents:components];
}

+ (NSDate*)startOfDate:(NSDate*)aDate {
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:aDate];
    
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
    return beginningOfDay;
}

+ (NSDate*)endOfDate:(NSDate*)aDate {
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:aDate];
    
    // Set the time components manually
    [dateComps setHour:23];
    [dateComps setMinute:59];
    [dateComps setSecond:59];
    
    // Convert back
    NSDate *endOfDay = [calendar dateFromComponents:dateComps];
    return endOfDay;    
}

+ (NSString*)displayYear:(NSDate*)aDate
{
    if (aDate == nil) {
        return @"";
    }
    
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }

    [dateFormatter setDateFormat:@"yyyy"];
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString*)displayMonthAndYear:(NSDate*)aDate
{
    if (aDate == nil) {
        return @"";
    }

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }

    NSString *dateComponents = @"yMMMM";
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:dateFormat];
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString*)displayDate:(NSDate*)aDate
{
    return [NSDateFormatter localizedStringFromDate:aDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
}

+ (NSString*)displayWeekday:(NSDate*)aDate
{
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"EEEE"];
    return [dateFormatter stringFromDate:aDate];
}

// Unlike Event:eventDisplayTime, This ONLY takes care of time display
+ (NSString*)displayEventTime:(NSDate*)aDate
{
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }

    [dateFormatter setDateFormat:@"h:mm a"];
    NSString *timeStr = [dateFormatter stringFromDate:aDate];
    
    if ([timeStr isEqualToString:@"12:00 AM"]) {
        return @"";
    } else if ([timeStr isEqualToString:@"11:59 PM"]) {
        return @"";
    }
    
    return timeStr;
}

+ (NSString*)displayEventWeekdayAndDate:(NSDate*)aDate
{
    return [NSString stringWithFormat:@"%@ %@", [self displayWeekday:aDate], [self displayDate:aDate]];
}

+ (NSString*)displayEventWeekdayAndDateAndTime:(NSDate*)aDate
{
    return [NSString stringWithFormat:@"%@ %@ %@", [self displayWeekday:aDate], [self displayDate:aDate], [self displayEventTime:aDate]];
}

+ (NSString*)displayDateRange:(NSDate *)date1 date2:(NSDate *)date2
{
    return [NSString stringWithFormat:@"%@ - %@", [DateUtil displayDate:date1], [DateUtil displayDate:date2]];
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

+ (BOOL)isSameDate:(NSDate*)aDate anotherDate:(NSDate*)anotherDate {
    if ([[self dateOnly:aDate] compare:[self dateOnly:anotherDate]] == NSOrderedSame) {
        return YES;
    }
    return NO;
}

+ (BOOL)isToday:(NSDate *)checkDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:checkDate];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([today isEqualToDate:otherDate]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isWeekRange:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    // start of the week
    NSDate *firstDate;
    [cal rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&firstDate interval:0 forDate:startDate];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:6];
    
    NSDate *endOfWeekDate = [cal dateByAddingComponents:components toDate:firstDate options:0];
    
    if ([startDate compare:firstDate] == NSOrderedSame && [endDate compare:endOfWeekDate] == NSOrderedSame) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isMonthRange:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    // start of the week
    NSDate *firstDate;
    [cal rangeOfUnit:NSCalendarUnitMonth startDate:&firstDate interval:0 forDate:startDate];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setMonth:1];
    [components setDay:-1];
    
    NSDate *lastDateOfMonth = [cal dateByAddingComponents:components toDate:firstDate options:0];
    
    if ([startDate compare:firstDate] == NSOrderedSame && [endDate compare:lastDateOfMonth] == NSOrderedSame) {
        return YES;
    }
    return NO;
}

+ (NSDate*)addDays:(NSDate*)startDate days:(NSInteger)days {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:days];
    
    return [cal dateByAddingComponents:components toDate:startDate options:0];
}

+ (NSDate*)addWeeks:(NSDate*)startDate weeks:(NSInteger)weeks {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setWeekOfMonth:weeks];
    
    return [cal dateByAddingComponents:components toDate:startDate options:0];
}

+ (NSDate*)addMonths:(NSDate *)startDate months:(NSInteger)months {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setMonth:months];
    
    return [cal dateByAddingComponents:components toDate:startDate options:0];
}

// Return an array that has first date of month of all months that between these two dates
+ (NSArray*)firstDateOfMonthBetweenDates:(NSDate*)fromDate toDate:(NSDate*)toDate {
    NSArray *dates = [self findMonthStartEndDate:fromDate];
    NSDate *dateStart = [dates objectAtIndex:0];
    dates = [self findMonthStartEndDate:toDate];
    NSDate *dateEnd = [dates objectAtIndex:0];
    
    NSMutableArray *firstDates = [[NSMutableArray alloc] init];
    if ([self isSameDate:dateStart anotherDate:dateEnd]) {
        [firstDates addObject:dateStart];
    } else {
        while ([dateStart compare:dateEnd] == NSOrderedAscending) {
            [firstDates addObject:dateStart];
            dateStart = [DateUtil addMonths:dateStart months:1];
        }
        [firstDates addObject:dateEnd];
    }
    
    return firstDates;
}

+ (NSString*)getLocalTimeZone
{
    NSTimeZone *tz = [NSTimeZone systemTimeZone];
    return [tz name];
}

@end
