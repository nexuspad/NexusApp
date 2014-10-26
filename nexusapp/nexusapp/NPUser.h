//
//  NPUser.h
//  nexuspad
//
//  Created by Ren Liu on 9/4/12.
//
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface NPUser : NSObject

@property int userId;

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *middleName;
@property (nonatomic, strong) NSString *profileImageUrl;

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *userName;

@property (nonatomic, strong) NSString *padHost;

- (id)initWithUser:(NPUser*)user;
- (id)initWithData:(NSDictionary*)dict;

- (NSString*)getDisplayName;
- (NSString*)getProfileImageUrl;

@end
