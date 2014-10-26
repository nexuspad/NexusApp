//
//  AccessEntitlement.h
//  nexuspad
//
//  Created by Ren Liu on 9/4/12.
//
//

#import <Foundation/Foundation.h>

#import "NPUser.h"

@interface AccessEntitlement : NSObject

@property (nonatomic, strong) NPUser *owner;
@property (nonatomic, strong) NPUser *viewer;

@property BOOL read;
@property BOOL write;

- (id)initWithOwnerAndViewer:(NPUser*)theOwner theViewer:(NPUser*)theViewer;
- (id)initWithDictInfo:(NSDictionary*)dictInfo;

- (BOOL)iAmOwner;
- (BOOL)iCanWrite;

+ (NPUser*)accountOwner;

@end
