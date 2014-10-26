//
//  DateHelper.h
//  nexuspad
//
//  Created by Ren Liu on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtil : NSObject

+ (NSArray*)findMonthStartEndDate:(NSDate*)aDate;
+ (NSArray*)findMonthStartEndDate:(NSInteger)year month:(NSInteger)month;
+ (NSDate*)findLastDateOfMonth:(NSString*)yyyymm;

+ (BOOL)isStartDateAndEndDateOfMonth:(NSDate*)startDate endDate:(NSDate*)endDate;

+ (NSDate*)getFirstDayOfWeek:(NSDate*)aDate;
+ (NSDate*)getLastDayOfWeek:(NSDate*)aDate;

+ (NSArray*)getYmd:(NSDate*)aDate;
+ (NSInteger)getYear:(NSDate*)aDate;
+ (NSInteger)getMonth:(NSDate*)aDate;
+ (NSInteger)getDay:(NSDate*)aDate;
+ (NSInteger)getHour:(NSDate*)aDate;

+ (NSInteger)minutesSinceMidnight:(NSDate*)aDate;

+ (NSString*)convertToYYYYMMDD:(NSDate*)aDate;
+ (NSString*)convertToYYYYMM:(NSDate*)aDate;
+ (NSDate*)parseFromYYYYMMDD:(NSString*)ymd;
+ (NSDate*)dateOnly:(NSDate*)dateAndTime;

+ (NSDate*)startOfDate:(NSDate*)aDate;
+ (NSDate*)endOfDate:(NSDate*)aDate;

+ (NSString*)displayYear:(NSDate*)aDate;
+ (NSString*)displayMonthAndYear:(NSDate*)aDate;
+ (NSString*)displayDate:(NSDate*)aDate;
+ (NSString*)displayWeekday:(NSDate*)aDate;
+ (NSString*)displayDateRange:(NSDate*)date1 date2:(NSDate*)date2;

+ (NSString*)displayEventTime:(NSDate*)aDate;
+ (NSString*)displayEventWeekdayAndDate:(NSDate*)aDate;
+ (NSString*)displayEventWeekdayAndDateAndTime:(NSDate*)aDate;

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andDate:(NSDate*)endDate;

+ (BOOL)isSameDate:(NSDate*)aDate anotherDate:(NSDate*)anotherDate;
+ (BOOL)isToday:(NSDate*)checkDate;
+ (BOOL)isWeekRange:(NSDate*)startDate endDate:(NSDate*)endDate;
+ (BOOL)isMonthRange:(NSDate*)startDate endDate:(NSDate*)endDate;

+ (NSArray*)firstDateOfMonthBetweenDates:(NSDate*)fromDate toDate:(NSDate*)toDate;

+ (NSDate*)addDays:(NSDate*)startDate days:(NSInteger)days;
+ (NSDate*)addWeeks:(NSDate*)startDate weeks:(NSInteger)weeks;
+ (NSDate*)addMonths:(NSDate*)startDate months:(NSInteger)months;

+ (NSString*)getLocalTimeZone;

@end
