//
//  NPFetcher.h
//  nexuspad
//
//  Created by Ren Liu on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// UI should be the delegate for service result.

#import "CoreSettings.h"
#import "ServiceResult.h"

typedef enum {
    wifi, threeG, lte, none
} ServiceSpeed;

@protocol NPDataServiceDelegate <NSObject>
- (void)updateServiceResult:(id)serviceResult;
- (void)serviceError:(ServiceResult*)serviceResult;
@optional
- (void)serviceDeniedAccess:(id)serviceResult;
@end


@interface NPService : NSObject

@property (nonatomic, weak) id<NPDataServiceDelegate> serviceDelegate;

+ (void)setServiceSpeed:(ServiceSpeed)speed;
+ (ServiceSpeed)getServiceSpeed;
+ (BOOL)isServiceAvailable;
+ (BOOL)isLoggedIn;

@end
