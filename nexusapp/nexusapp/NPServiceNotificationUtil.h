//
//  NPServiceNotificationUtil.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/28/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define N_DATA_REFRESHED           @"NPServiceDataRefreshedNotification"

@interface NPServiceNotificationUtil : NSObject

+ (void)sendDataRefreshNotification:(id)folder;

@end
