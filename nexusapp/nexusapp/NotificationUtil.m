//
//  NotificationUtil.m
//  nexuspad
//
//  Created by Ren Liu on 8/23/12.
//
//

#import "NotificationUtil.h"

@implementation NotificationUtil

+ (void)sendEntryAddedNotification:(id)entry {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_ENTRY_ADDED object:entry userInfo:nil];
}

+ (void)sendEntryUpdatedNotification:(id)entry {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_ENTRY_UPDATED object:entry userInfo:nil];
}

+ (void)sendEntryMovedNotification:(id)entry {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_ENTRY_MOVED object:entry userInfo:nil];
}

+ (void)sendEntryDeletedNotification:(id)entry {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_ENTRY_DELETED object:entry userInfo:nil];
}

+ (void)sendEntryAvailableNotification:(id)entry {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_ENTRY_AVAILABLE object:entry userInfo:nil];
}

+ (void)sendFolderAddedNotification:(NPFolder*)folder {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_FOLDER_ADDED object:folder userInfo:nil];
}

+ (void)sendFolderUpdatedNotification:(NPFolder*)folder {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_FOLDER_UPDATED object:folder userInfo:nil];
}

+ (void)sendFolderMovedNotification:(NPFolder*)folder {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_FOLDER_MOVED object:folder userInfo:nil];
}

+ (void)sendFolderDeletedNotification:(NPFolder*)folder {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_FOLDER_DELETED object:folder userInfo:nil];
}

@end
