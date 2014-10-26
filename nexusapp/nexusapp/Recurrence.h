//
//  Recurrence.h
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {ONE, FUTURE, ALL, UNDEFINED} RecurEventUpdateOption;

typedef enum {norepeat = 0, daily = 1, weekdaily = 2, weekly = 3, monthly = 4, yearly = 5} RecurrencePattern;
typedef enum {byDayOfMonth, byDayOfWeek} MonthlyRepeatBy;

@interface Recurrence : NSObject

@property int pattern;
@property int interval;

@property (nonatomic, strong) NSArray *weeklyDays;
@property (nonatomic, assign) MonthlyRepeatBy monthlyRecurType;
@property int recurrenceTimes;
@property (nonatomic, strong) NSDate *endDate;
@property BOOL recurForever;

- (Recurrence*)initWithData:(NSDictionary*)recurData;
+ (NSDictionary*)recurPatterns;

- (NSString*)buildRecurJsonStringParam;

- (NSString*)repeatDescriptionString:(BOOL)multiLine;

@end
