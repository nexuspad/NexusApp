//
//  ACPerson.m
//  nexusapp
//
//  Created by Ren Liu on 1/10/14.
//
//

#import "ACPerson.h"

@implementation ACPerson

+ (ACPerson*)acPersonFromEntry:(NPPerson*)npPerson {
    ACPerson *acPerson = [[ACPerson alloc] init];
    
    if (npPerson.profileImageUrl != nil) {
        acPerson.profileImageUrl = npPerson.profileImageUrl;
    }
    
    if (npPerson.profileImage != nil) {
        acPerson.profileImage = [UIImage imageWithData:UIImagePNGRepresentation(npPerson.profileImage)];
    }
    
    if (npPerson.title != nil) {
        acPerson.title = npPerson.title;
    }
    
    if (npPerson.firstName != nil) {
        acPerson.firstName = npPerson.firstName;
    }
    if (npPerson.lastName != nil) {
        acPerson.lastName = npPerson.lastName;
    }
    if (npPerson.middleName != nil) {
        acPerson.middleName = npPerson.middleName;
    }
    if (npPerson.businessName != nil) {
        acPerson.businessName = npPerson.businessName;
    }
    
    acPerson.phones = npPerson.phones;
    acPerson.emails = npPerson.emails;
    
    return acPerson;
}

- (NSString*)autocompleteString {
    return [self getEmail];
}

@end
