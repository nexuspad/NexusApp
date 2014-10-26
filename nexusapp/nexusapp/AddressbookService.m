//
//  PhoneContactSyncService.m
//  NexusAppCore
//
//  Created by Ren Liu on 10/13/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "AddressbookService.h"
#import "ContactVcardUploadService.h"
#import "NPServiceNotificationUtil.h"
#import "NPFolder.h"
#import "NPPerson.h"

@implementation AddressbookService

static AddressbookService* theService = nil;
static BOOL downloadingAddressbook;

+ (AddressbookService*)instance {
    if (theService == nil) {
        theService = [[AddressbookService alloc] init];
    }
    return theService;
}

#pragma mark - phone contact sync preference

+ (void)syncPhoneContact:(BOOL)yesOrNo {
    if (yesOrNo) {
        [UserPrefUtil setPreference:[NSNumber numberWithInt:1] forKey:PREF_SYNC_PHONE_CONTACT];
    } else {
        [UserPrefUtil setPreference:[NSNumber numberWithInt:0] forKey:PREF_SYNC_PHONE_CONTACT];
    }
}

+ (BOOL)syncPhoneContactAllowed {
    NSNumber *setting = [UserPrefUtil getPreference:PREF_SYNC_PHONE_CONTACT];
    if (setting == nil || [setting intValue] != 1) {
        return NO;
    }
    return YES;
}

+ (BOOL)isPhoneContactSyncOptionSet {
    if ([UserPrefUtil getPreference:PREF_SYNC_PHONE_CONTACT] == nil) {
        return NO;
    }
    return YES;
}

- (id)init {
    self = [super init];
    return self;
}

- (void)start {
    DLog(@"Start phone contact syncing...");
    dispatch_queue_t phoneContactSyncQ = dispatch_queue_create("com.nexusapp.PhoneContactSyncService", NULL);
    dispatch_async(phoneContactSyncQ, ^{
        [self syncContacts];
        if (!downloadingAddressbook) {
            [self downloadAddressbookLookup];
        }
    });
}

- (void)checkLastSyncTimeAndStart {
    NSDate *now = [NSDate date];
    // One day
    if (([now timeIntervalSince1970] - [self getLastPhoneContactsSyncTime]) > 86400) {
        [self start];
    }
}

- (double)getLastPhoneContactsSyncTime {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double lastSyncDate = [defaults integerForKey:@"PhoneContactsLastSyncTime"];
    
    if (!lastSyncDate) {
        lastSyncDate = 0;
    }
    
    return lastSyncDate;
}

- (void)setLastPhoneContactsSyncTime {
    DLog(@"Update phone contacts the last sync time to now");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    double newSyncDate = [[NSDate date] timeIntervalSince1970];
    [defaults setInteger:newSyncDate forKey:@"PhoneContactsLastSyncTime"];
    [defaults synchronize];
}

- (void)syncContacts {
    CFErrorRef error = NULL;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (addressBook == nil) {
        return;
    }
    
    if (error != nil) {
        DLog(@"Error opening address book. %@", error);
    }
    
    NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    ContactVcardUploadService *vcardUploader = [[ContactVcardUploadService alloc] init];

    for (int i = 0; i < [allContacts count]; i++) {
        ABRecordRef contact = (__bridge ABRecordRef)allContacts[i];
        ABRecordRef people[1];
        people[0] = contact;
        CFArrayRef peopleArray = CFArrayCreate(NULL, (void *)people, 1, &kCFTypeArrayCallBacks);
        NSData *vCardData = CFBridgingRelease(ABPersonCreateVCardRepresentationWithPeople(peopleArray));

        NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID(contact)];
        
        NSDate *modificationDate = (__bridge_transfer NSDate*) ABRecordCopyValue(contact, kABPersonModificationDateProperty);
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:2];
        [params setObject:recordId forKey:@"external_id"];
        [params setObject:@"ios" forKey:@"external_src"];

        [params setObject:[NSNumber numberWithDouble:[modificationDate timeIntervalSince1970]] forKey:@"update_time"];
        
        [vcardUploader uploadToServer:vCardData params:params];
        
        CFRelease(contact);
    }
    
    CFRelease(addressBook);
    
    [self setLastPhoneContactsSyncTime];
    
    // Notify the front end
    DLog(@"Notify UI for contact refresh.");
    NPFolder *contactFolder = [[NPFolder alloc] initWithModuleAndFolderId:CONTACT_MODULE folderId:ROOT_FOLDER accessInfo:nil];
    [NPServiceNotificationUtil sendDataRefreshNotification:contactFolder];
}

// Download the addressbook lookup and store it into plist
- (void)downloadAddressbookLookup {
    DLog(@"Download the full addressbook lookup...");

    NSString *addressbookUrl = [NSString stringWithFormat:@"%@/contacts/fulladdressbook", [[HostInfo current] getApiUrl]];

    // Set a flag so we don't do it again
    downloadingAddressbook = YES;

    [self doGet:addressbookUrl
     completion:^(BOOL success, NSURLRequest *originalRequest, NSData *responseData) {
         downloadingAddressbook = NO;

         if (success == YES) {
             if (!self.responseData) return;
             
             // Parse self.responseDate
             NSMutableArray *addressbookArr = [[NSMutableArray alloc] init];
             
             NSError *error = nil;
             NSDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&error];
             
             ServiceResult *result = [[ServiceResult alloc] initWithData:returnedData];
             
             if (result.success) {
                 if ([result isEntryListResponse]) {
                     NSArray *addressbookDictArr = [result.body objectForKey:LIST_ENTRIES];
                     for (NSDictionary *addressbookDict in addressbookDictArr) {
                         if ([addressbookDict objectForKey:@"email"] != nil) {
                             [addressbookArr addObject:addressbookDict];
                         }
                     }
                 }
                 
                 if ([addressbookArr count] > 0) {
                     NSString *plistError;
                     NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                     NSString *plistPath = [rootPath stringByAppendingPathComponent:@"npab.plist"];
                     
                     NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:addressbookArr
                                                                                    format:NSPropertyListXMLFormat_v1_0
                                                                          errorDescription:&plistError];
                     if (plistData) {
                         [plistData writeToFile:plistPath atomically:YES];
                     } else {
                         NSLog(@"Writing to plist file error : %@",error);
                     }
                 }
             } else {
                 NSLog(@"Failed to download full addressbook: %@", result);
             }

         } else {
             NSLog(@"Failed to download full addressbook. Web service error.");
         }
     }];
}

// Get the addressbook lookup from plist
- (NSArray*)getAddressbook {
    NSMutableArray *addressbook = [[NSMutableArray alloc] init];

    NSString *error;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"npab.plist"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        DLog(@"Parse addressbook from npab.plist...");
        NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSPropertyListFormat plistFormat;
        NSArray *tempArr = (NSArray *)[NSPropertyListSerialization propertyListFromData:plistXML
                                                                       mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                                                 format:&plistFormat
                                                                       errorDescription:&error];
        
        for (NSDictionary *addressbookDict in tempArr) {
            NPPerson *person = [NPPerson personFromAddressbookDict:addressbookDict];
            if (person != nil) {
                [addressbook addObject:person];
            }
        }
        
        if (error != nil) {
            NSLog(@"Reading plist file error : %@",error);
        }

    } else {
        // plist file non exist, download the full addressbook.
        if (!downloadingAddressbook) {
            [self downloadAddressbookLookup];
        }
    }
    
    return addressbook;
}

- (void)updateServiceResult:(id)serviceResult {
    // No implementation.
}

- (void)serviceError:(id)serviceResult {
    // TODO
}


@end
