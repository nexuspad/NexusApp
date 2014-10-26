//
//  Location.h
//  nexuspad
//
//  Created by Ren Liu on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NPLocation : NSObject

@property (nonatomic, strong) NSString *locationName;

@property (nonatomic, strong) NSString *fullAddress;

@property (nonatomic, strong) NSString *streetAddress;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *province;
@property (nonatomic, strong) NSString *postalCode;
@property (nonatomic, strong) NSString *country;

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;

- (id)initWithAddress:(NSString*)address;

- (NSString*)getAddressStringForMap;
- (NSArray*)getAddressInArray;

- (NSDictionary*)toDictionary;
- (NSString*)description;

@end
