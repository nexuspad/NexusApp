//
//  Person.m
//  nexuspad
//
//  Created by Ren Liu on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPPerson.h"
#import "NPItem.h"
#import "NSString+NPStringUtil.h"
#import "NSDictionary+NPUtil.h"

@implementation NPPerson

@synthesize profileImage, profileImageUrl, phones, emails, address, firstName = _firstName, lastName = _lastName, middleName, businessName;
@synthesize sectionNumber, searchKey = _searchKey;

- (id)init
{
    self = [super init];
    if (self) {
        self.folder.moduleId = CONTACT_MODULE;
        self.templateId = contact;
        return self;
    }
    
    return self;
}

- (NSString*)addressBookTitle {
    if ([NSString isNotBlank:self.lastName] && [NSString isNotBlank:self.firstName]) {
        if ([NSString isBlank:self.middleName]) {
            return [NSString stringWithFormat:@"%@, %@", self.lastName, self.firstName];
        } else {
            return [NSString stringWithFormat:@"%@, %@ %@.", self.lastName, self.firstName, [[self.middleName substringToIndex:1] capitalizedString]];
        }
    } else if ([NSString isNotBlank:self.firstName]) {
        return self.firstName;

    } else if ([NSString isNotBlank:self.title]) {
        return self.title;
    
    } else if ([NSString isNotBlank:self.businessName]) {
        return self.businessName;

    } else if ([NSString isNotBlank:[self getEmail]]) {
        return [self getEmail];
    }
    
    // There is really nothing there that I can use to display title.
    return @"";
}

- (NSString*)firstName
{
    if (_firstName == nil) return @"";
    return _firstName;
}

- (NSString*)sectionKey {
    if ([NSString isNotBlank:_lastName]) {
        return _lastName;
    }
    
    return [self addressBookTitle];
}

- (NSString*)searchKey {
    NSString *phoneStr = @"";
    
    if (self.phones.count > 0) {
        NSMutableArray *phoneNumberArr = [[NSMutableArray alloc] init];
        for (NPItem *item in self.phones) {
            [phoneNumberArr addObject:item.value];
            [phoneNumberArr addObject:[item.value stripOffNonNumerics]];
        }
        phoneStr = [phoneNumberArr componentsJoinedByString:@" "];
    }

    NSString *emailStr = @"";
    if (self.emails.count > 0) {
        emailStr = [[self.emails valueForKey:@"value"] componentsJoinedByString:@" "];
    }

    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", self.title, self.lastName, self.firstName, phoneStr, emailStr, self.note];
}

- (BOOL)hasProfilePhoto {
    if (self.profileImage != nil || (self.profileImageUrl != nil && self.profileImageUrl.length > 0)) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setEmail:(NSString*)email {
    if (self.emails == nil) {
        self.emails = [NSMutableArray arrayWithObject:email];
    } else {
        [self.emails addObject:email];
    }
}

- (NSString*)getEmail {
    if (self.emails != nil) {
        return [self.emails firstObject];
    }
    return nil;
}


- (id)copyWithZone:(NSZone*)zone
{
    NPPerson *person = [[NPPerson alloc] init];
    [person copyBasic:self];

    if (self.profileImageUrl != nil) {
        person.profileImageUrl = self.profileImageUrl;
    }

    if (self.profileImage != nil) {
        person.profileImage = [UIImage imageWithData:UIImagePNGRepresentation(self.profileImage)];
    }
    
    if (self.firstName != nil) {
        person.firstName = [self.firstName copy];
    }
    if (self.lastName != nil) {
        person.lastName = [self.lastName copy];
    }
    if (self.middleName != nil) {
        person.middleName = [self.middleName copy];
    }
    if (self.businessName != nil) {
        person.businessName = [self.businessName copy];
    }
    
    person.phones = [self.phones copy];
    person.emails = [self.emails copy];
    person.address = [self.address copy];

    if (self.attachments != nil && [self.attachments count] > 0) {
        NSArray *tmpArr = [NSArray arrayWithObject:[self.attachments objectAtIndex:0]];
        person.attachments = [NSArray arrayWithArray:tmpArr];
    } else {
        person.attachments = nil;
    }
    return person;
}

- (NSDictionary*)buildParamMap
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[super buildParamMap]];

    // Dump the names
    if (self.firstName != nil) {
        [params setValue:self.firstName forKey:CONTACT_FIRST_NAME];
    }
    
    if (self.lastName != nil) {
        [params setValue:self.lastName forKey:CONTACT_LAST_NAME];
    }
    
    if (self.middleName != nil) {
        [params setValue:self.middleName forKey:CONTACT_MI];
    }
    
    if (self.businessName != nil) {
        [params setValue:self.businessName forKey:CONTACT_BUSINESS];
    }
    
    if (self.webAddress != nil) {
        [params setValue:self.webAddress forKey:CONTACT_WEBSITE];
    }

    // Dump phones
    if ([self.phones count] > 0) {
        NSMutableArray *phoneArr = [[NSMutableArray alloc] initWithCapacity:[self.phones count]];
        for (NPItem *item in self.phones) {
            [phoneArr addObject:[item toDictionary]];
        }
        [params setValue:[NSString convertDataToJsonString:phoneArr] forKey:CONTACT_PHONE];
    }
    
    // Dump emails
    if ([self.emails count] > 0) {
        NSMutableArray *emailArr = [[NSMutableArray alloc] initWithCapacity:[self.emails count]];
        for (NPItem *item in self.emails) {
            [emailArr addObject:[item toDictionary]];
        }
        [params setValue:[NSString convertDataToJsonString:emailArr] forKey:CONTACT_EMAIL];
    }

    // Dump address
    if (![NSString isBlank:self.address.streetAddress]) {
        [params setValue:self.address.streetAddress forKey:CONTACT_ADDRESS];
    }
    if (![NSString isBlank:self.address.city]) {
        [params setValue:self.address.city forKey:CONTACT_CITY];
    }
    if (![NSString isBlank:self.address.province]) {
        [params setValue:self.address.province forKey:CONTACT_PROVINCE];
    }
    if (![NSString isBlank:self.address.postalCode]) {
        [params setValue:self.address.postalCode forKey:CONTACT_POSTAL];
    }
    if (![NSString isBlank:self.address.country]) {
        [params setValue:self.address.country forKey:CONTACT_COUNTRY];
    }

    return params;
}

+ (NPPerson*)personFromEntry:(NPEntry*)entry
{
    /*
     We want to make sure doing a Person to Person copy. Here is the scenario we are trying to cover:
     1. A contact is updated.
     2. BaseEntryListViewController receives updated Person object and add it into the currentEntryList.entries
     3. ContactListViewController builds the sectioned map based on the list. Each list item is converted to a Person object.
        However, doing NPEntry to Person conversion will lose the lastName attribute because featureValueDict is NOT populated in that case.
        SO, we just need to do a Person object copy to make sure the object is correctly duplicated.
     */
    if ([entry isKindOfClass:[NPPerson class]]) {
        return (NPPerson*)entry;
    }
    
    if (entry == nil) {
        return nil;
    }
    
    NPPerson *person = [[NPPerson alloc] initWithNPEntry:entry];
    
    // Get the names
    if ([entry.featureValuesDict objectForKey:CONTACT_FIRST_NAME] != nil) {
        person.firstName = [entry.featureValuesDict valueForKey:CONTACT_FIRST_NAME];
    }
    
    if ([entry.featureValuesDict objectForKey:CONTACT_LAST_NAME] != nil) {
        person.lastName = [entry.featureValuesDict valueForKey:CONTACT_LAST_NAME];
    }

    if ([entry.featureValuesDict objectForKey:CONTACT_MI] != nil) {
        person.middleName = [entry.featureValuesDict valueForKey:CONTACT_MI];
    }
    
    if ([entry.featureValuesDict objectForKey:CONTACT_BUSINESS] != nil) {
        person.businessName = [entry.featureValuesDict valueForKey:CONTACT_BUSINESS];
    }
    
    // Get the profile photo
    if ([entry.featureValuesDict objectForKeyNotNull:CONTACT_PROFILE_PHOTO]) {
        person.profileImageUrl = [entry.featureValuesDict valueForKey:CONTACT_PROFILE_PHOTO];
    }

    // Extract phones
    if ([entry.featureValuesDict objectForKey:CONTACT_PHONE] != nil) {
        id phoneDetail = [entry.featureValuesDict objectForKey:CONTACT_PHONE];
        if ([phoneDetail isKindOfClass:[NSString class]] && [phoneDetail length] > 0) { // If the phone info is just a string, turn it into an array
            NSArray *phonesArray = [NSJSONSerialization JSONObjectWithData:[phoneDetail dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            [person setFeatureValue:CONTACT_PHONE featureValue:phonesArray];
        }
    }

    // Extract emails
    if ([entry.featureValuesDict objectForKey:CONTACT_EMAIL] != nil) {
        id emailDetail = [entry.featureValuesDict objectForKey:CONTACT_EMAIL];
        if ([emailDetail isKindOfClass:[NSString class]] && [emailDetail length] > 0) { // If the phone info is just a string, turn it into an array.
            NSArray *emailsArray = [NSJSONSerialization JSONObjectWithData:[emailDetail dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
            [person setFeatureValue:CONTACT_EMAIL featureValue:emailsArray];
        }
    }
    
    // Parse the phones - The CONTACT_PHONE should have been converted to array if it was a string.
    if ([person getFeatureValue:CONTACT_PHONE] != nil) {
        NSMutableArray *phones = [[NSMutableArray alloc] init];
        NSArray *phoneDictArr = [person getFeatureValue:CONTACT_PHONE];
        for (NSDictionary *phoneDict in phoneDictArr) {
            NPItem *phone = [[NPItem alloc] initWithType:PhoneItem];
            if ([phoneDict objectForKeyNotNull:ENTRY_DETAIL_LABEL]) {
                phone.subType = [NSString stringWithString:[phoneDict valueForKey:ENTRY_DETAIL_LABEL]];
            } else {
                phone.subType = @"";
            }

            phone.value = [NSString stringWithString:[phoneDict valueForKey:ENTRY_DETAIL_VALUE]];
            
            if ([[phoneDict valueForKey:@"formatted_value"] length]) {
                phone.formattedValue = [phoneDict valueForKey:@"formatted_value"];
            }

            [phones addObject:phone];
        }
        person.phones = [NSMutableArray arrayWithArray:phones];
        
        [person removeFeatureValue:CONTACT_PHONE];
    }
    
    // Parse the emails - The CONTACT_EMAIL should have been converted to array if it was a string.
    if ([person getFeatureValue:CONTACT_EMAIL] != nil) {
        NSMutableArray *emails = [[NSMutableArray alloc] init];
        NSArray *emailDictArr = [person getFeatureValue:CONTACT_EMAIL];
        for (NSDictionary *emailDict in emailDictArr) {
            NPItem *email = [[NPItem alloc] initWithType:EmailItem];
            if ([emailDict objectForKeyNotNull:ENTRY_DETAIL_LABEL]) {
                email.subType = [NSString stringWithString:[emailDict valueForKey:ENTRY_DETAIL_LABEL]];
            } else {
                email.subType = @"";
            }
            email.value = [NSString stringWithString:[emailDict valueForKey:ENTRY_DETAIL_VALUE]];
            [emails addObject:email];
        }
        person.emails = [NSMutableArray arrayWithArray:emails];
        
        [person removeFeatureValue:CONTACT_EMAIL];
    }
    
    // Parse the address
    person.address = [[NPLocation alloc] init];
    if (![NSString isBlank:[entry getFeatureValue:CONTACT_ADDRESS]]) {
        person.address.streetAddress = [entry getFeatureValue:CONTACT_ADDRESS];
    }
    if (![NSString isBlank:[entry getFeatureValue:CONTACT_CITY]]) {
        person.address.city = [entry getFeatureValue:CONTACT_CITY];
    }
    if (![NSString isBlank:[entry getFeatureValue:CONTACT_PROVINCE]]) {
        person.address.province = [entry getFeatureValue:CONTACT_PROVINCE];
    }
    if (![NSString isBlank:[entry getFeatureValue:CONTACT_POSTAL]]) {
        person.address.postalCode = [entry getFeatureValue:CONTACT_POSTAL];
    }
    
    return person;
}


+ (NPPerson*)personFromAddressbookDict:(NSDictionary*)addressbookDict {
    NSString *email = [addressbookDict valueForKey:@"email"];
    if (email.length > 0) {
        NPPerson *person = [[NPPerson alloc] init];
        
        [person setEmail:email];
        
        NSInteger userId = [[addressbookDict valueForKey:@"user_id"] integerValue];
        person.npUserId = userId;
        
        person.title = [addressbookDict valueForKey:@"display_name"];

        return person;
    }
    
    return nil;
}

@end
