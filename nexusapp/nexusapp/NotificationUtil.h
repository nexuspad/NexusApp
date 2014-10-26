//
//  NotificationUtil.h
//  nexuspad
//
//  Created by Ren Liu on 8/23/12.
//
//

#import <Foundation/Foundation.h>
#import "NPEntry.h"
#import "NPFolder.h"

// Front-end notifications
#define N_ENTRY_ADDED           @"EntryAddedNotification"
#define N_ENTRY_UPDATED         @"EntryUpdatedNotification"
#define N_ENTRY_MOVED           @"EntryMovedNotification"
#define N_ENTRY_DELETED         @"EntryDeletedNotification"
#define N_ENTRY_AVAILABLE       @"EntryIsAvailable"

#define N_FOLDER_ADDED          @"FolderAdded"
#define N_FOLDER_UPDATED        @"FolderUpdated"
#define N_FOLDER_MOVED          @"FolderMoved"
#define N_FOLDER_DELETED        @"FolderDeleted"


@interface NotificationUtil : NSObject

+ (void)sendEntryAddedNotification:(id)entry;

+ (void)sendEntryUpdatedNotification:(id)entry;
+ (void)sendEntryMovedNotification:(id)entry;
+ (void)sendEntryDeletedNotification:(id)entry;

+ (void)sendEntryAvailableNotification:(id)entry;

+ (void)sendFolderAddedNotification:(NPFolder*)folder;
+ (void)sendFolderUpdatedNotification:(NPFolder*)folder;
+ (void)sendFolderMovedNotification:(NPFolder*)folder;
+ (void)sendFolderDeletedNotification:(NPFolder*)folder;

@end
