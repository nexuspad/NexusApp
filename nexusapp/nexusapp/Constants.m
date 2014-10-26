//
//  DetailFeatureConstants.m
//  nexuspad
//
//  Created by Ren Liu on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"
#import "CoreSettings.h"

@implementation Constants

NSString* const NP_UUID                 = @"uuid";
NSString* const NP_UTOKEN_PARAM         = @"utoken";

NSString* const NP_RESPONSE_STATUS      = @"status";
NSString* const NP_RESPONSE_MESSAGE     = @"message";

NSString* const NP_RESPONSE_CODE        = @"code";

NSString* const NP_RESPONSE_DATA        = @"data";

int const NP_DATA_STORE_NOT_AVAILABLE   = 99998;
int const NP_WEB_SERVICE_NOT_AVAILABLE  = 99999;

int const NP_SERVICE_200                = 200;
int const NP_SERVICE_401                = 401;

NSString* const NP_DATA_ERROR           = @"data_error";
int const NP_ENTRY_NOT_FOUND            = 2001;

NSString* const ACCT_LOGIN_FAIL_REASON  = @"login_fail_reason";
NSString* const ACCT_REGISTER_FAIL_REASON
                                        = @"register_fail_reason";
NSString* const ACCT_SESSION_ID         = @"session_id";
NSString* const ACCT_PAD_HOST           = @"padhost";
NSString* const ACCT_USER_ID            = @"user_id";
NSString* const ACCT_USER_EMAIL         = @"email";
NSString* const ACCT_PROFILE_PHOTO_URL  = @"profile_photo_url";
NSString* const ACCT_FIRST_NAME         = @"first_name";
NSString* const ACCT_LAST_NAME          = @"last_name";
NSString* const ACCT_USER_NAME          = @"user_name";
NSString* const ACCT_USER_PASS          = @"password";
NSString* const ACCT_SPACE_ALLOCATION   = @"space_allocation";
NSString* const ACCT_SPACE_USAGE        = @"space_usage";
NSString* const ACCT_EXTERNAL_SERVICE   = @"external_service";

NSString* const MODULE_ID               = @"module_id";

int const CONTACT_MODULE                = 1;
int const CALENDAR_MODULE               = 2;
int const BOOKMARK_MODULE               = 3;
int const DOC_MODULE                    = 4;
int const PHOTO_MODULE                  = 6;
int const PLANNER_MODULE                = 7;
int const UPLOAD_MODULE                 = 5;

NSString* const FOLDER                  = @"folder";
NSString* const FOLDER_LIST             = @"folders";
NSString* const FOLDER_NAME             = @"folder_name";
NSString* const FOLDER_ID               = @"folder_id";
NSString* const FOLDER_CODE             = @"folder_code";
NSString* const FOLDER_PARENT_ID        = @"parent_id";

NSString* const SHARINGS_DETAIL         = @"sharings";
NSString* const SHARE_TO                = @"share_to";

NSString* const SHARING_ACCESSOR_KEY    = @"accessor_key";
NSString* const SHARING_ACCESSOR_ID     = @"accessor_id";

NSString* const SHARING_PERMISSION      = @"permission";
NSString* const SHARING_READ            = @"read";
NSString* const SHARING_WRITE           = @"write";

int const FOLDER_STATUS_DELETED         = 25;

NSString* const TEMPLATE_ID             = @"template_id";

int const STICKY_FOLDER_ID              = 20;

// action result from data service
NSString* const ACTION_RESULT           = @"action_result";
NSString* const ACTION_ERROR_CODE       = @"action_error_code";
NSString* const ACTION_NAME             = @"action_name";

NSString* const ACTION_DATA             = @"entry";
NSString* const ACTION_ADD_ENTRY        = @"add_entry";
NSString* const ACTION_UPDATE_ENTRY     = @"update_entry";
NSString* const ACTION_MOVE_ENTRY       = @"move_entry";

NSString* const ACTION_MOVE_ENTRIES     = @"move_entries";
NSString* const ACTION_REFRESH_ENTRIES  = @"refresh_entries";

NSString* const ACTION_DELETE_ENTRY     = @"delete_entry";
NSString* const ACTION_UPLOAD_ENTRY     = @"upload_entry";
NSString* const ACTION_DELETE_ENTRIES   = @"delete_entries";

NSString* const ACTION_ADD_FOLDER       = @"add_folder";
NSString* const ACTION_UPDATE_FOLDER    = @"update_folder";
NSString* const ACTION_MOVE_FOLDER      = @"move_folder";
NSString* const ACTION_SHARE_FOLDER     = @"share_folder";
NSString* const ACTION_DELETE_FOLDER    = @"delete_folder";
NSString* const ACTION_UNSHARE_FOLDER   = @"unshare_folder";


// entry detail return
NSString* const ENTRY                   = @"entry";

// list constants
NSString* const LIST_SUMMARY            = @"list_summary";
NSString* const LIST_TOTAL_COUNT        = @"total_count";
NSString* const COUNT_PER_PAGE          = @"count_per_page";
NSString* const LIST_PAGE_ID            = @"page_id";
NSString* const LIST_START_YMD          = @"start_date";
NSString* const LIST_END_YMD            = @"end_date";
NSString* const LIST_SEARCH_KEYWORD     = @"keyword";
NSString* const LIST_ENTRIES            = @"entries";
NSString* const LIST_SUB_FOLDERS        = @"sub_folders";

int const ENTRY_LIST_COUNT              = 20;
int const PHOTO_LIST_COUNT              = 24;               // portrait 4 per row, landscape 6 per row

NSString* const ENTRY_SYNC_ID           = @"sync_id";
NSString* const ENTRY_ID                = @"entry_id";
NSString* const EXTERNAL_ID             = @"external_id";
NSString* const ENTRY_TITLE             = @"title";
NSString* const ENTRY_CREATE_DATE       = @"create_date";
NSString* const ENTRY_CREATE_TS         = @"create_ts";
NSString* const ENTRY_ORIGINAL_TS       = @"original_ts";
NSString* const ENTRY_MODIFIED_TS       = @"modified_ts";
NSString* const ENTRY_MODIFIED_TIME     = @"modified_time";

NSString* const ENTRY_HAS_UPLOADS       = @"has_uploads";
NSString* const ENTRY_HAS_MAPPED        = @"has_mapped_entries";

NSString* const ENTRY_STATUS            = @"status";
int const ENTRY_STATUS_ACTIVE           = 0;
int const ENTRY_STATUS_DELETED          = 25;

NSString* const ENTRY_DETAIL            = @"details";

// entry value types
int const ENTRY_VALUE_IS_STRING         = 0;
int const ENTRY_VALUE_IS_LIST           = 1;
int const ENTRY_VALUE_IS_COMPOSITE      = 2;

NSString* const ENTRY_DETAIL_VALUE      = @"value";         // The 3 below are for the multi-values
NSString* const ENTRY_DETAIL_TYPE       = @"type";
NSString* const ENTRY_DETAIL_SUBTYPE    = @"subtype";
NSString* const ENTRY_DETAIL_LABEL      = @"label";

NSString* const ENTRY_NOTE              = @"note";
NSString* const ENTRY_RT_NOTE           = @"richtext";
NSString* const ENTRY_ATTACHMENTS       = @"attachments";
NSString* const ENTRY_WEB_ADDRESS       = @"web_address";
NSString* const ENTRY_TAG               = @"tags";
NSString* const ENTRY_COLOR_LABEL       = @"color_label";
NSString* const ENTRY_DEFAULT_COLOR     = @"#336699";
NSString* const ENTRY_LOCATION          = @"location";
NSString* const ENTRY_PINNED            = @"pinned";

NSString* const LOCATION_NAME           = @"location";
NSString* const LOCATION_FULL_ADDRESS   = @"full_address";
NSString* const LOCATION_STREET_ADDRESS = @"address";
NSString* const LOCATION_CITY           = @"city";
NSString* const LOCATION_PROVINCE       = @"province";
NSString* const LOCATION_POSTAL_CODE    = @"postal_code";
NSString* const LOCATION_COUNTRY        = @"country";
NSString* const LOCATION_LAT_LNG        = @"lat_lng";
NSString* const LOCATION_LONGITUDE      = @"longitude";
NSString* const LOCATION_LATITUDE       = @"latitude";


NSString* const ATTACHMENT_FILE_NAME    = @"file_name";
NSString* const ATTACHMENT_FILE_TYPE    = @"file_type";
NSString* const ATTACHMENT_FILE_SIZE    = @"file_size";

NSString* const ATTACHMENT_FILE_LINK    = @"download_url";

NSString* const CONTACT_FIRST_NAME      = @"first_name";
NSString* const CONTACT_LAST_NAME       = @"last_name";
NSString* const CONTACT_MI              = @"mi";
NSString* const CONTACT_BUSINESS        = @"business";
NSString* const CONTACT_PHONE           = @"phone";
NSString* const CONTACT_EMAIL           = @"email";
NSString* const CONTACT_ADDRESS         = @"address";
NSString* const CONTACT_CITY            = @"city";
NSString* const CONTACT_PROVINCE        = @"province";
NSString* const CONTACT_POSTAL          = @"postal_code";
NSString* const CONTACT_COUNTRY         = @"country";
NSString* const CONTACT_STATE           = @"state";
NSString* const CONTACT_ZIP             = @"zip";
NSString* const CONTACT_WEBSITE         = @"contact_website";
NSString* const CONTACT_PROFILE_PHOTO   = @"profile_photo_url";

NSString* const EVENT_RECUR_ID          = @"recur_id";
NSString* const EVENT_START_TS          = @"start_ts";
NSString* const EVENT_END_TS            = @"end_ts";
NSString* const EVENT_TIMEZONE          = @"timezone";
NSString* const EVENT_ALL_DAY           = @"all_day";
NSString* const EVENT_NO_TIME           = @"no_starting_time";
NSString* const EVENT_SINGLE_TIME       = @"single_time";

NSString* const EVENT_RECURRENCE        = @"recurrence";
NSString* const EVENT_ATTENDEES         = @"attendees";
NSString* const EVENT_REMINDER          = @"reminders";

NSString* const EVENT_RECUR_PATTERN     = @"pattern";
NSString* const EVENT_RECUR_INTERVAL    = @"interval";
NSString* const EVENT_RECUR_MONTHLY_REPEATBY
                                        = @"monthly_repeat_by";
NSString* const EVENT_RECUR_WEEKLYDAYS  = @"weekly_days";
NSString* const EVENT_RECUR_ENDDATE     = @"repeat_end_date";
NSString* const EVENT_RECUR_TIMES       = @"repeat_times";
NSString* const EVENT_RECUR_FOREVER     = @"repeat_forever";

NSString* const EVENT_REMINDER_RECEIVER_ID
                                        = @"receiver_id";
NSString* const EVENT_REMINDER_OFFSET_TS
                                        = @"offset_ts";
NSString* const EVENT_REMINDER_ADDRESS  = @"deliver_address";

NSString* const EVENT_ATTENDEE_USER_ID  = @"attendee_user_id";
NSString* const EVENT_ATTENDEE_EMAIL    = @"attendee_email";
NSString* const EVENT_ATTENDEE_NAME     = @"attendee_name";
NSString* const EVENT_ATTENDEE_COMMENT  = @"attendee_comment";
NSString* const EVENT_ATTENDEE_ATT_STATUS
                                        = @"attendee_status";

NSString* const BOOKMARK_WEB_ADDRESS    = @"web_address";

NSString* const ALBUM_PHOTOS            = @"photos";

NSString* const PHOTO_TN_URL            = @"tn_url";
NSString* const PHOTO_URL               = @"lightbox_url";


// Access info
NSString* const ACCESS_INFO             = @"access_info";
NSString* const OWNER_ID                = @"owner_id";
NSString* const VIEWER_ID               = @"viewer_id";
NSString* const ACCESS_INFO_READ        = @"read";
NSString* const ACCESS_INFO_WRITE       = @"write";

// User preferences
NSString* const PREF_CALENDAR_RANGE     = @"preference_calendar_range";

// Error codes
int const INVALID_SESSION               = 1001;

int const FAILED_REGISTRATION           = 1010;
int const FAILED_REGISTRATION_ACCT_EXIST
                                        = 1011;

int const LOGIN_NO_USER                 = 1021;
int const LOGIN_ACCT_PROBLEM            = 1022;
int const LOGIN_FAILED                  = 1023;

int const ENTRY_NOT_FOUND               = 2001;
int const ENTRY_NO_READ_PERMISSION      = 2005;
int const ENTRY_NO_WRITE_PERMISSION     = 2006;
int const ENTRY_UPDATE_FAILED           = 2010;
int const ENTRY_DELETE_FAILED           = 2011;

int const FOLDER_NOT_FOUND              = 2021;
int const FOLDER_NO_READ_PERMISSION     = 2025;
int const FOLDER_NO_WRITE_PERMISSION    = 2026;
int const FOLDER_UPDATE_FAILED          = 2030;
int const FOLDER_DELETE_FAILED          = 2040;

int const MISSING_PARAM                 = 2050;
int const NEED_CONFIRMATION             = 2060;
int const GENERAL_ERROR                 = 9999;

@end
