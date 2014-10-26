//
//  EntryService.h
//  nexuspad
//
//  Created by Ren Liu on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntryStore.h"
#import "NPFolder.h"
#import "NPEntry.h"
#import "NPModule.h"
#import "NPMessage.h"
#import "NPWebApiService.h"
#import "EntryUriHelper.h"
#import "DateUtil.h"
#import "UserManager.h"

@interface EntryService : NPWebApiService <EntryStoreDelegate>

@property (nonatomic, strong) AccessEntitlement *accessInfo;
@property (nonatomic, weak) id<NPDataServiceDelegate> serviceDelegate;

- (void)getEntryDetail:(NPEntry *)entry;

- (void)addOrUpdateEntry:(NPEntry*)entry;
- (void)moveEntry:(NPEntry*)entry;

- (void)updateAttribute:(NPEntry*)entry attributeName:(NSString*)attributeName attributeValue:(NSString*)attributeValue;

- (void)deleteEntry:(NPEntry*)entry;
- (void)deleteAttachment:(NPUpload*)attachment;

- (void)emailEntry:(NPEntry*)entry message:(NPMessage*)message;

- (void)updateRemoteEntryCopy:(NPEntry*)entry;

@end
