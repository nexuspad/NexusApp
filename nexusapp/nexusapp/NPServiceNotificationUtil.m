//
//  NPServiceNotificationUtil.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/28/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPServiceNotificationUtil.h"

@implementation NPServiceNotificationUtil

+ (void)sendDataRefreshNotification:(id)folder {
    [[NSNotificationCenter defaultCenter] postNotificationName:N_DATA_REFRESHED object:folder userInfo:nil];
}

@end
