//
//  PhoneContactSyncService.h
//  NexusAppCore
//
//  Created by Ren Liu on 10/13/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "NPWebApiService.h"
#import "UserPrefUtil.h"

/**
 * Handles Up syncing Phone address book AND downloading NP addressbook on the server.
 *
 */
@interface AddressbookService : NPWebApiService <NPDataServiceDelegate>

+ (AddressbookService*)instance;

+ (void)syncPhoneContact:(BOOL)yesOrNo;
+ (BOOL)syncPhoneContactAllowed;
+ (BOOL)isPhoneContactSyncOptionSet;

- (NSArray*)getAddressbook;

- (void)start;
- (void)checkLastSyncTimeAndStart;

- (double)getLastPhoneContactsSyncTime;
- (void)setLastPhoneContactsSyncTime;

@end
