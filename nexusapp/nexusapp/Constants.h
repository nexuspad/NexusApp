//
//  DetailFeatureConstants.h
//  nexuspad
//
//  Created by Ren Liu on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Constants : NSObject

// NP data service
extern NSString* const NP_UUID;
extern NSString* const NP_UTOKEN_PARAM;

extern NSString* const NP_RESPONSE_STATUS;
extern NSString* const NP_RESPONSE_MESSAGE;
extern NSString* const NP_RESPONSE_CODE;
extern NSString* const NP_RESPONSE_DATA;

extern int const NP_DATA_STORE_NOT_AVAILABLE;
extern int const NP_WEB_SERVICE_NOT_AVAILABLE;

extern int const NP_SERVICE_200;
extern int const NP_SERVICE_401;

extern NSString* const NP_DATA_ERROR;
extern int const NP_ENTRY_NOT_FOUND;

// entry value types
extern int const ENTRY_VALUE_IS_STRING;
extern int const ENTRY_VALUE_IS_LIST;
extern int const ENTRY_VALUE_IS_COMPOSITE;

// account constants
extern NSString* const ACCT_LOGIN_FAIL_REASON;
extern NSString* const ACCT_REGISTER_FAIL_REASON;

extern NSString* const ACCT_SESSION_ID;
extern NSString* const ACCT_PAD_HOST;
extern NSString* const ACCT_USER_ID;
extern NSString* const ACCT_USER_EMAIL;
extern NSString* const ACCT_PROFILE_PHOTO_URL;
extern NSString* const ACCT_FIRST_NAME;
extern NSString* const ACCT_LAST_NAME;
extern NSString* const ACCT_USER_NAME;
extern NSString* const ACCT_USER_PASS;
extern NSString* const ACCT_SPACE_ALLOCATION;
extern NSString* const ACCT_SPACE_USAGE;
extern NSString* const ACCT_EXTERNAL_SERVICE;

// module contants
extern NSString* const MODULE_ID;

extern int const CONTACT_MODULE;
extern int const CALENDAR_MODULE;
extern int const BOOKMARK_MODULE;
extern int const DOC_MODULE;
extern int const PHOTO_MODULE;
extern int const PLANNER_MODULE;
extern int const UPLOAD_MODULE;

// folder constants
extern NSString* const FOLDER;
extern NSString* const FOLDER_LIST;
extern NSString* const FOLDER_NAME;
extern NSString* const FOLDER_ID;
extern NSString* const FOLDER_CODE;
extern NSString* const FOLDER_PARENT_ID;

// Sharings detail input/out
extern NSString* const SHARINGS_DETAIL;

// Share to user input
extern NSString* const SHARE_TO;

// Sharing attribute information
extern NSString* const SHARING_ACCESSOR_KEY;
extern NSString* const SHARING_ACCESSOR_ID;

extern NSString* const SHARING_PERMISSION;
extern NSString* const SHARING_READ;
extern NSString* const SHARING_WRITE;

extern int const FOLDER_STATUS_DELETED;

extern NSString* const TEMPLATE_ID;

extern int const STICKY_FOLDER_ID;

// action result from data service
extern NSString* const ACTION_RESULT;
extern NSString* const ACTION_ERROR_CODE;
extern NSString* const ACTION_NAME;
extern NSString* const ACTION_DATA;

extern NSString* const ACTION_ADD_ENTRY;
extern NSString* const ACTION_UPDATE_ENTRY;
extern NSString* const ACTION_MOVE_ENTRY;

extern NSString* const ACTION_MOVE_ENTRIES;
extern NSString* const ACTION_REFRESH_ENTRIES;

extern NSString* const ACTION_UPLOAD_ENTRY;

extern NSString* const ACTION_DELETE_ENTRY;
extern NSString* const ACTION_DELETE_ENTRIES;

extern NSString* const ACTION_ADD_FOLDER;
extern NSString* const ACTION_UPDATE_FOLDER;
extern NSString* const ACTION_MOVE_FOLDER;
extern NSString* const ACTION_SHARE_FOLDER;
extern NSString* const ACTION_DELETE_FOLDER;
extern NSString* const ACTION_UNSHARE_FOLDER;

// entry detail return
extern NSString* const ENTRY;

// list constants
extern NSString* const LIST_SUMMARY;        // A dictionary with summary info
extern NSString* const LIST_TOTAL_COUNT;    // An item in the dictionary
extern NSString* const COUNT_PER_PAGE;
extern NSString* const LIST_PAGE_ID;
extern NSString* const LIST_START_YMD;
extern NSString* const LIST_END_YMD;
extern NSString* const LIST_SEARCH_KEYWORD;
extern NSString* const LIST_ENTRIES;
extern NSString* const LIST_SUB_FOLDERS;

extern int const ENTRY_LIST_COUNT;
extern int const PHOTO_LIST_COUNT;

// entry constants
extern NSString* const ENTRY_SYNC_ID;
extern NSString* const ENTRY_ID;
extern NSString* const EXTERNAL_ID;
extern NSString* const ENTRY_TITLE;
extern NSString* const ENTRY_CREATE_DATE;
extern NSString* const ENTRY_CREATE_TS;
extern NSString* const ENTRY_MODIFIED_TS;
extern NSString* const ENTRY_MODIFIED_TIME;

extern NSString* const ENTRY_HAS_UPLOADS;
extern NSString* const ENTRY_HAS_MAPPED;

extern NSString* const ENTRY_DETAIL;
extern NSString* const ENTRY_ORIGINAL_TS;
extern NSString* const ENTRY_LOCATION;

extern NSString* const LOCATION_NAME;
extern NSString* const LOCATION_FULL_ADDRESS;
extern NSString* const LOCATION_STREET_ADDRESS;
extern NSString* const LOCATION_CITY;
extern NSString* const LOCATION_PROVINCE;
extern NSString* const LOCATION_POSTAL_CODE;
extern NSString* const LOCATION_COUNTRY;
extern NSString* const LOCATION_LAT_LNG;
extern NSString* const LOCATION_LONGITUDE;
extern NSString* const LOCATION_LATITUDE;


extern NSString* const ENTRY_STATUS;
extern int const ENTRY_STATUS_ACTIVE;
extern int const ENTRY_STATUS_DELETED;

// details
extern NSString* const ENTRY_DETAIL_VALUE;  // The 3 below are for the multi-values
extern NSString* const ENTRY_DETAIL_TYPE;
extern NSString* const ENTRY_DETAIL_SUBTYPE;
extern NSString* const ENTRY_DETAIL_LABEL;

extern NSString* const ENTRY_NOTE;
extern NSString* const ENTRY_RT_NOTE;
extern NSString* const ENTRY_ATTACHMENTS;
extern NSString* const ENTRY_TAG;
extern NSString* const ENTRY_WEB_ADDRESS;
extern NSString* const ENTRY_COLOR_LABEL;
extern NSString* const ENTRY_DEFAULT_COLOR;
extern NSString* const ENTRY_PINNED;

extern NSString* const ATTACHMENT_FILE_NAME;
extern NSString* const ATTACHMENT_FILE_TYPE;
extern NSString* const ATTACHMENT_FILE_SIZE;
extern NSString* const ATTACHMENT_FILE_LINK;

// details - contact
extern NSString* const CONTACT_FIRST_NAME;
extern NSString* const CONTACT_LAST_NAME;
extern NSString* const CONTACT_MI;
extern NSString* const CONTACT_BUSINESS;
extern NSString* const CONTACT_PHONE;
extern NSString* const CONTACT_EMAIL;
extern NSString* const CONTACT_ADDRESS;
extern NSString* const CONTACT_CITY;
extern NSString* const CONTACT_PROVINCE;
extern NSString* const CONTACT_POSTAL;
extern NSString* const CONTACT_STATE;
extern NSString* const CONTACT_ZIP;
extern NSString* const CONTACT_COUNTRY;
extern NSString* const CONTACT_WEBSITE;
extern NSString* const CONTACT_PROFILE_PHOTO;

// details - calendar
extern NSString* const EVENT_RECUR_ID;
extern NSString* const EVENT_START_TS;
extern NSString* const EVENT_END_TS;
extern NSString* const EVENT_TIMEZONE;
extern NSString* const EVENT_ALL_DAY;
extern NSString* const EVENT_NO_TIME;
extern NSString* const EVENT_SINGLE_TIME;

extern NSString* const EVENT_RECURRENCE;
extern NSString* const EVENT_ATTENDEES;
extern NSString* const EVENT_REMINDER;

extern NSString* const EVENT_RECUR_PATTERN;
extern NSString* const EVENT_RECUR_INTERVAL;
extern NSString* const EVENT_RECUR_MONTHLY_REPEATBY;
extern NSString* const EVENT_RECUR_WEEKLYDAYS;
extern NSString* const EVENT_RECUR_ENDDATE;
extern NSString* const EVENT_RECUR_TIMES;
extern NSString* const EVENT_RECUR_FOREVER;

extern NSString* const EVENT_REMINDER_RECEIVER_ID;
extern NSString* const EVENT_REMINDER_OFFSET_TS;
extern NSString* const EVENT_REMINDER_ADDRESS;

extern NSString* const EVENT_ATTENDEE_USER_ID;
extern NSString* const EVENT_ATTENDEE_EMAIL;
extern NSString* const EVENT_ATTENDEE_NAME;
extern NSString* const EVENT_ATTENDEE_COMMENT;
extern NSString* const EVENT_ATTENDEE_ATT_STATUS;


// details - photo
extern NSString* const ALBUM_PHOTOS;

extern NSString* const PHOTO_TN_URL;
extern NSString* const PHOTO_URL;


// details bookmark
extern NSString* const BOOKMARK_WEB_ADDRESS;

// Access info
extern NSString* const ACCESS_INFO;
extern NSString* const OWNER_ID;
extern NSString* const VIEWER_ID;
extern NSString* const ACCESS_INFO_READ;
extern NSString* const ACCESS_INFO_WRITE;

// User preferences
extern NSString* const PREF_CALENDAR_RANGE;

// Error codes
extern int const INVALID_SESSION;
extern int const FAILED_REGISTRATION;
extern int const FAILED_REGISTRATION_ACCT_EXIST;

extern int const LOGIN_NO_USER;
extern int const LOGIN_ACCT_PROBLEM;
extern int const LOGIN_FAILED;

extern int const ENTRY_NOT_FOUND;
extern int const ENTRY_NO_READ_PERMISSION;
extern int const ENTRY_NO_WRITE_PERMISSION;
extern int const ENTRY_UPDATE_FAILED;
extern int const ENTRY_DELETE_FAILED;

extern int const FOLDER_NOT_FOUND;
extern int const FOLDER_NO_READ_PERMISSION;
extern int const FOLDER_NO_WRITE_PERMISSION;
extern int const FOLDER_UPDATE_FAILED;
extern int const FOLDER_DELETE_FAILED;

extern int const MISSING_PARAM;
extern int const NEED_CONFIRMATION;
extern int const GENERAL_ERROR;

@end
