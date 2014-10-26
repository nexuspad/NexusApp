//
//  DataStoreUtil.h
//  NexusAppCore
//
//  Created by Weiran Zhang on 11/04/2013.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreSettings.h"
#import "AccessEntitlement.h"
#import "UserManager.h"
#import "NPManagedDocument.h"

/*
 * DataStore handles Core Data interfaces.
 */

@interface DataStore : NSObject


+ (NPManagedDocument*)getNPManagedDocument;
+ (BOOL)storeIsBeingOpened;

- (NPManagedDocument*)getNPManagedDocInstance;

- (void)clearAllOfflineItems;

@end
