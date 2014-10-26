//
//  UserPrefUtil.h
//  NexusAppCore
//
//  Created by Ren Liu on 9/5/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreSettings.h"
#import "NPFolder.h"

#define PREF_LAST_CALENDAR_VIEW     @"last_calendar_view"
#define PREF_SYNC_PHONE_CONTACT     @"sync_phone_contact"

@interface UserPrefUtil : NSObject

// A calendar can be set to "hidden" if user chooses not to show events from this calendar when viewing "all events"
// It can still be selected from the calendar selector to reveal the events.
+ (void)toggleCalendarVisibility:(NPFolder*)folder hideIt:(BOOL)hideIt;
+ (void)setHiddenCalendars:(NSArray*)calendars;
+ (NSArray*)getHiddenCalendars;

// The date range represented by number of weeks going backward and forward. This is used to figure out the default date range
// when showing the calendar views such as month view and agenda view.
+ (void)setWeekRange:(NSDate*)currentDate fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate;
+ (NSArray*)getWeekRange;

+ (void)setPreference:(id)value forKey:(NSString*)forKey;
+ (id)getPreference:(NSString*)forKey;
+ (void)clearAll;

@end
