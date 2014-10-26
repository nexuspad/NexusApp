//
//  UserPrefUtil.m
//  NexusAppCore
//
//  Created by Ren Liu on 9/5/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "UserPrefUtil.h"
#import "Constants.h"

@implementation UserPrefUtil

#pragma mark - calendar filter

// Update the hidden calendar list based on the toggling.
+ (void)toggleCalendarVisibility:(NPFolder*)folder hideIt:(BOOL)hideIt{
    NSMutableArray *hiddenCals = nil;
    if ([self getHiddenCalendars] != nil) {
        hiddenCals = [NSMutableArray arrayWithArray:[self getHiddenCalendars]];
    } else {
        hiddenCals = [[NSMutableArray alloc] init];
    }
    
    if (hideIt) {
        if (![hiddenCals containsObject:[folder uniqueKey]]) {
            [hiddenCals addObject:[folder uniqueKey]];
        }

    } else {
        [hiddenCals removeObject:[folder uniqueKey]];
    }
    
    [self setHiddenCalendars:hiddenCals];
}

+ (void)setHiddenCalendars:(NSArray*)calendars {
    [self setPreference:[NSArray arrayWithArray:calendars] forKey:@"HIDDEN_CALENDARS"];
}

+ (NSArray*)getHiddenCalendars {
    return [self getPreference:@"HIDDEN_CALENDARS"];
}


#pragma mark - agenda view date range

+ (void)setWeekRange:(NSDate*)currentDate fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    int unitFlags = NSCalendarUnitWeekOfMonth;

    NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:fromDate toDate:currentDate options:0];
    NSInteger weeksBackward = [dateComponents weekOfMonth];
    
    if (weeksBackward < 0) {
        weeksBackward = 0;
    }
    
    dateComponents = [calendar components:unitFlags fromDate:currentDate toDate:toDate options:0];
    NSInteger weeksForward = [dateComponents weekOfMonth];

    if (weeksForward < 0) {
        weeksForward = 0;
    }
    
    NSArray *weekRange = [NSArray arrayWithObjects:[NSNumber numberWithInteger:weeksBackward], [NSNumber numberWithInteger:weeksForward], nil];
    
    DLog(@"Store week range to preference: %@ -- %@", [weekRange objectAtIndex:0], [weekRange objectAtIndex:1]);

    [self setPreference:weekRange forKey:@"CALENDAR_WEEK_RANGE"];
}


+ (NSArray*)getWeekRange {
    return [self getPreference:@"CALENDAR_WEEK_RANGE"];
}


#pragma mark - general methods to get/set

+ (void)setPreference:(id)value forKey:(NSString*)forKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:forKey];
    [defaults synchronize];
}

+ (id)getPreference:(NSString*)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    return value;
}

// Remove all stored preferences
+ (void)clearAll {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [defaults removePersistentDomainForName:appDomain];
}

@end
