//
//  Attendee.h
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import <Foundation/Foundation.h>

typedef enum {notinvited = -1, invited = 0, willattend = 1, wontattend = 2, mayattend = 3} AttendeeStatus;

@interface Attendee : NSObject

@property int userId;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *comment;

@property AttendeeStatus status;

- (Attendee*)initWithData:(NSDictionary*)attendeeDict;

- (NSString*)getNameOrEmail;

- (NSDictionary*)toDictionary;

@end
