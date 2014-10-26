//
//  LayoutConstants.h
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CONTACT_SECTIONS            8                       // This MUST MATCH what's in storyboard.
#define CONTACT_TITLE_SECTION       0
#define CONTACT_NAME_SECTION        1
#define CONTACT_BUSINESS_SECTION    2
#define CONTACT_PHONE_SECTION       3
#define CONTACT_EMAIL_SECTION       4
#define CONTACT_ADDRESS_SECTION     5
#define CONTACT_WEB_SECTION         6
#define CONTACT_TAG_SECTION         7

#define EVENT_SECTIONS              6
#define EVENT_TITLE_SECTION         0
#define EVENT_LOCATION_SECTION      1
#define EVENT_TIME_SECTION          2
#define EVENT_REMINDER_SECTION      3
#define EVENT_ATTENDEE_SECTION      4
#define EVENT_TAG_SECTION           5

#define RECURRENCE_PATTERN_SECTION  0
#define RECURRENCE_DAILY_SECTION    1
#define RECURRENCE_WEEKLY_SECTION   2
#define RECURRENCE_MONTHLY_SECTION  3
#define RECURRENCE_YEARLY_SECTION   4
#define RECURRENCE_END_SECTION      5

#define BOOKMARK_URL_SECTION        0
#define BOOKMARK_TAGS_SECTION       1

#define NOTE_TITLE_SECTION          0
#define NOTE_TEXT_SECTION           1

@interface LayoutConstants : NSObject

@end
