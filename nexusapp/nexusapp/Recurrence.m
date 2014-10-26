//
//  Recurrence.m
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import "Constants.h"
#import "Recurrence.h"
#import "DateUtil.h"
#import "NSString+NPStringUtil.h"
#import "NSDictionary+NPUtil.h"

NSString* const RECUR_PATTERN_NOREPEAT  = @"No repeat";
NSString* const RECUR_PATTERN_DAILY     = @"Repeat daily";
NSString* const RECUR_PATTERN_WEEKLY    = @"Repeat weekly";
NSString* const RECUR_PATTERN_MONTHLY   = @"Repeat monthly";
NSString* const RECUR_PATTERN_YEARLY    = @"Repeat yearly";

@implementation Recurrence

@synthesize pattern, interval, weeklyDays, monthlyRecurType, recurrenceTimes, endDate, recurForever;

- (id)init
{
    self = [super init];
    self.pattern = norepeat;
    self.interval = 1;
    self.recurrenceTimes = 1;
    self.recurForever = NO;
    return self;
}

- (Recurrence*)initWithData:(NSDictionary*)recurData
{
    self = [super init];

    if (self) {

        NSDictionary *recurDataCopy = [NSDictionary dictionaryWithDictionary:recurData];

        self.pattern = [[recurDataCopy valueForKey:EVENT_RECUR_PATTERN] intValue];
        
        if ([recurData objectForKeyNotNull:EVENT_RECUR_INTERVAL]) {
            self.interval = [[recurDataCopy valueForKey:EVENT_RECUR_INTERVAL] intValue];
        } else {
            self.pattern = norepeat;
        }
        
        if ([recurData objectForKeyNotNull:EVENT_RECUR_TIMES]) {
            self.recurrenceTimes = [[recurDataCopy valueForKey:EVENT_RECUR_TIMES] intValue];
        }
        
        if ([recurData objectForKeyNotNull:EVENT_RECUR_ENDDATE]) {
            NSString *recurEndDate = [recurDataCopy valueForKey:EVENT_RECUR_ENDDATE];
            if ([recurEndDate length] == 8) {
                self.endDate = [DateUtil parseFromYYYYMMDD:recurEndDate];
            }
        }
        
        if (self.recurrenceTimes == 0 && self.endDate == nil) {
            self.recurForever = YES;
        } else {
            self.recurForever = NO;
        }
        
        return self;
    }

    return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
    Recurrence *newRecurrence = [[Recurrence alloc] init];
    newRecurrence.pattern = self.pattern;
    newRecurrence.interval = self.interval;
    newRecurrence.weeklyDays = [NSArray arrayWithArray:self.weeklyDays];
    newRecurrence.monthlyRecurType = self.monthlyRecurType;
    newRecurrence.recurrenceTimes = self.recurrenceTimes;
    newRecurrence.endDate = [self.endDate copy];
    newRecurrence.recurForever = self.recurForever;
    return newRecurrence;
}

- (NSString*)buildRecurJsonStringParam
{
    NSMutableDictionary *recurInfo = [[NSMutableDictionary alloc] init];
    if (self.pattern == norepeat) {
        return nil;
    } else {
        [recurInfo setValue:[NSNumber numberWithInt:self.pattern] forKey:EVENT_RECUR_PATTERN];
        [recurInfo setValue:[NSNumber numberWithInt:self.interval] forKey:EVENT_RECUR_INTERVAL];
        if (self.pattern == weekly) {
            [recurInfo setValue:[self.weeklyDays componentsJoinedByString:@","] forKey:EVENT_RECUR_WEEKLYDAYS];
        } else if (self.pattern == monthly) {
            [recurInfo setValue:[NSNumber numberWithInt:self.monthlyRecurType] forKey:EVENT_RECUR_MONTHLY_REPEATBY];
        }
        
        if (self.recurForever) {
            [recurInfo setValue:[NSNumber numberWithInt:1] forKey:EVENT_RECUR_FOREVER];
        } else if (self.endDate != nil) {
            [recurInfo setValue:[DateUtil convertToYYYYMMDD:self.endDate] forKey:EVENT_RECUR_ENDDATE];
        } else if (self.recurrenceTimes != 0) {
            [recurInfo setValue:[NSNumber numberWithInt:self.recurrenceTimes] forKey:EVENT_RECUR_TIMES];
        } else {
            return nil;
        }
    }

    return [NSString convertDataToJsonString:recurInfo];
}

- (NSString*)repeatDescriptionString:(BOOL)multiLine
{
    if (self.pattern == norepeat) {
        return NSLocalizedString(@"No repeat",);
    }
    
    NSMutableString *description = [[NSMutableString alloc] init];
    
    if (self.pattern == (int)daily) {
        if (self.interval == 1) {
            [description appendString:@"Repeat daily"];
        } else {
            [description appendFormat:@"Repeat every %i days", self.interval];
        }
    
    } else if (self.pattern == weekdaily) {
        if (self.interval == 1) {
            [description appendString:@"Repeat daily on weekdays"];
        } else {
            [description appendFormat:@"Repeat every %i weekdays", self.interval];
        }

    } else if (self.pattern == (int)weekly) {
        if (self.interval == 1) {
            [description appendString:@"Repeat weekly"];
        } else {
            [description appendFormat:@"Repeat every %i weeks", self.interval];
        }
        
    } else if (self.pattern == (int)monthly) {
        if (self.interval == 1) {
            [description appendString:@"Repeat monthly"];
        } else {
            [description appendFormat:@"Repeat every %i months", self.interval];
        }
        
    } else if (self.pattern == (int)yearly) {
        if (self.interval == 1) {
            [description appendString:@"Repeat yearly"];
        } else {
            [description appendFormat:@"Repeat every %i years", self.interval];
        }
    }
    
    if (!self.recurForever) {
        NSString *separator = @" ";
        if (multiLine) {
            separator = @"\n";
        }
        if (self.endDate != nil) {
            [description appendFormat:@"%@Until %@", separator, [DateUtil displayDate:self.endDate]];
        } else if (self.recurrenceTimes > 0) {
            [description appendFormat:@"%@For %i time(s)", separator, self.recurrenceTimes];
        }
    }

    return description;
}

+ (NSDictionary*)recurPatterns
{
    NSMutableArray *patterns = [[NSMutableArray alloc] initWithObjects:RECUR_PATTERN_DAILY,
                                RECUR_PATTERN_WEEKLY,
                                RECUR_PATTERN_MONTHLY, RECUR_PATTERN_YEARLY, nil];
    NSMutableDictionary *recurValues = [[NSMutableDictionary alloc] initWithCapacity:1];
    [recurValues setObject:patterns forKey:[NSNumber numberWithInt:0]];
    return recurValues;
}

@end
