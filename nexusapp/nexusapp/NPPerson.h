//
//  Person.h
//  nexuspad
//
//  Created by Ren Liu on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NPEntry.h"
#import "NPLocation.h"


@interface NPPerson : NPEntry

@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSString *profileImageUrl;

@property NSInteger sectionNumber;    // For display sorting

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *middleName;

@property (nonatomic, strong) NSString *businessName;

@property (nonatomic, strong) NPLocation *address;
@property (nonatomic, strong) NSMutableArray *phones;
@property (nonatomic, strong) NSMutableArray *emails;

@property NSInteger npUserId;
@property (nonatomic, strong) NSString *searchKey;

- (NSString*)addressBookTitle;

- (NSString*)sectionKey;

- (void)setEmail:(NSString*)email;
- (NSString*)getEmail;

- (BOOL)hasProfilePhoto;

+ (NPPerson*)personFromEntry:(NPEntry*)entry;

+ (NPPerson*)personFromAddressbookDict:(NSDictionary*)addressbookDict;

@end
