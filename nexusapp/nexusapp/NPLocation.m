//
//  Location.m
//  nexuspad
//
//  Created by Ren Liu on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPLocation.h"
#import "NSString+NPStringUtil.h"
#import "Constants.h"

@implementation NPLocation

@synthesize fullAddress, streetAddress, city, province, country, postalCode, latitude, longitude, locationName;

- (id)init
{
    self = [super init];
    if (self) {
        return self;
    }
    
    return self;
}

- (id)initWithAddress:(NSString*)address
{
    self = [super init];
    if (self) {
        return self;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NPLocation *address = [[NPLocation alloc] init];
    
    if (self.locationName.length > 0) {
        address.locationName = [NSString stringWithString:self.locationName];
    }
    
    if (self.fullAddress.length > 0) {
        address.fullAddress = [NSString stringWithString:self.fullAddress];
    }
    
    if (self.streetAddress != nil) {
        address.streetAddress = [NSString stringWithString:self.streetAddress];
    }
    if (self.city != nil) {
        address.city = [NSString stringWithString:self.city];
    }
    if (self.province != nil) {
        address.province = [NSString stringWithString:self.province];
    }
    if (self.postalCode != nil) {
        address.postalCode = [NSString stringWithString:self.postalCode];
    }
    if (self.country != nil) {
        address.country = [NSString stringWithString:self.country];
    }
    if (self.latitude != nil) {
        address.latitude = [NSString stringWithString:self.latitude];
    }
    if (self.longitude != nil) {
        address.longitude = [NSString stringWithString:self.longitude];
    }
    return address;
}

- (NSArray*)getAddressInArray
{
    NSMutableArray *addrArr = [[NSMutableArray alloc] initWithCapacity:2];
    if (![NSString isBlank:self.streetAddress]) {
        [addrArr addObject:self.streetAddress];
    }
    
    NSMutableString *cityStateZip = [[NSMutableString alloc] init];
    
    if (![NSString isBlank:self.city]) {
        [cityStateZip appendString:self.city];
    }
    
    if (![NSString isBlank:self.province]) {
        [cityStateZip appendString:@" "];
        [cityStateZip appendString:self.province];
    }
    
    if (![NSString isBlank:self.postalCode]) {
        [cityStateZip appendString:@" "];
        [cityStateZip appendString:self.postalCode];
    }
    
    if ([cityStateZip length] > 0) {
        [addrArr addObject:cityStateZip];
    }
    return addrArr;
}

- (NSString*)getAddressStringForMap {
    NSMutableArray *addrArr = [[NSMutableArray alloc] initWithCapacity:3];
    if (![NSString isBlank:self.streetAddress]) {
        [addrArr addObject:self.streetAddress];
    }
    if (![NSString isBlank:self.province]) {
        [addrArr addObject:self.province];
    }
    if (![NSString isBlank:self.postalCode]) {
        [addrArr addObject:self.postalCode];
    }
    
    if ([addrArr count] >= 2) {
        return [addrArr componentsJoinedByString:@","];
    }
    
    // Check the full address attribute. This might be populated.
    if (self.fullAddress.length > 0) {
        return self.fullAddress;
    }
    
    return nil;
}

- (NSDictionary*)toDictionary {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];

    if (self.locationName.length > 0) {
        [params setValue:self.locationName forKey:LOCATION_NAME];
    }
    
    if (self.fullAddress.length > 0) {
        [params setValue:self.fullAddress forKey:LOCATION_FULL_ADDRESS];
    }
    
    if (self.streetAddress.length > 0) {
        [params setValue:self.streetAddress forKey:LOCATION_STREET_ADDRESS];
    }
    
    if (self.city.length > 0) {
        [params setValue:self.city forKey:LOCATION_CITY];
    }
    
    if (self.country.length > 0) {
        [params setValue:self.country forKey:LOCATION_COUNTRY];
    }
    
    if (self.province.length > 0) {
        [params setValue:self.province forKey:LOCATION_PROVINCE];
    }
    
    if (self.postalCode.length > 0) {
        [params setValue:self.postalCode forKey:LOCATION_POSTAL_CODE];
    }
    
    if (self.latitude.length > 0) {
        [params setValue:self.latitude forKey:LOCATION_LATITUDE];
    }
    
    if (self.longitude.length > 0) {
        [params setValue:self.longitude forKey:LOCATION_LONGITUDE];
    }

    return params;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"location:%@ full addr:%@ streer:%@ city:%@ state:%@ zip:%@ lat:%@ lng:%@ ", self.locationName, self.fullAddress, self.streetAddress, self.city, self.province, self.postalCode, self.latitude, self.longitude];
}

@end
