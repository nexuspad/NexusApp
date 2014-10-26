//
//  Attendee.m
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import "Attendee.h"
#import "Constants.h"
#import "NSDictionary+NPUtil.h"

@implementation Attendee

@synthesize userId, name, email, status, comment;

- (Attendee*)initWithData:(NSDictionary*)attendeeDict
{
    self = [super init];

    if (self) {
        if ([attendeeDict objectForKeyNotNull:EVENT_ATTENDEE_USER_ID]) {
            self.userId = [[attendeeDict valueForKey:EVENT_ATTENDEE_USER_ID] intValue];
        }
        if ([attendeeDict objectForKeyNotNull:EVENT_ATTENDEE_NAME]) {
            self.name = [NSString stringWithString:[attendeeDict valueForKey:EVENT_ATTENDEE_NAME]];
        }
        if ([attendeeDict objectForKeyNotNull:EVENT_ATTENDEE_EMAIL]) {
            self.email = [NSString stringWithString:[attendeeDict valueForKey:EVENT_ATTENDEE_EMAIL]];
        }
        if ([attendeeDict objectForKeyNotNull:EVENT_ATTENDEE_COMMENT]) {
            self.comment = [NSString stringWithString:[attendeeDict valueForKey:EVENT_ATTENDEE_COMMENT]];
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    Attendee *att = [[Attendee alloc] init];
    att.userId = self.userId;
    att.name = [NSString stringWithString:self.name];
    att.email = [NSString stringWithString:self.email];
    att.status = self.status;

    return att;
}

- (NSString*)getNameOrEmail
{
    if (self.name != nil) {
        return self.name;
    }
    return self.email;
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *aDict = [[NSMutableDictionary alloc] initWithCapacity:5];
    [aDict setValue:[NSNumber numberWithInt:self.userId] forKey:EVENT_ATTENDEE_USER_ID];
    [aDict setValue:self.name forKey:EVENT_ATTENDEE_NAME];
    [aDict setValue:self.email forKey:EVENT_ATTENDEE_EMAIL];
    [aDict setValue:[NSNumber numberWithInt:status] forKey:EVENT_ATTENDEE_ATT_STATUS];
    [aDict setValue:self.comment forKey:EVENT_ATTENDEE_COMMENT];
    
    return aDict;
}

@end
