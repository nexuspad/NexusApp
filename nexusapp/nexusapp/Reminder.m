//
//  Reminder.m
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import "Reminder.h"
#import "Constants.h"
#import "NSString+NPStringUtil.h"

@implementation Reminder

@synthesize offsetTs = _offsetTs, unit, unitCount, deliverAddress;

- (id)init
{
    self = [super init];
    self.offsetTs = 900;
    self.unitCount = 15;
    self.unit = @"minute";
    
    return self;
}

- (Reminder*)initWithData:(NSDictionary*)reminderDict
{
    self = [self init];

    if (self) {
        if ([reminderDict valueForKey:EVENT_REMINDER_OFFSET_TS] != nil) {
            self.offsetTs = [[reminderDict valueForKey:EVENT_REMINDER_OFFSET_TS] longValue];
            
            NSInteger days = self.offsetTs/86400;
            if (days > 0) {
                self.unitCount = days;
                self.unit = @"day";

            } else {
                NSInteger hours = self.offsetTs/3600;
                if (hours > 0) {
                    self.unitCount = hours;
                    self.unit = @"hour";

                } else {
                    NSInteger minutes = self.offsetTs/60;
                    if (minutes > 0) {
                        self.unitCount = minutes;
                        self.unit = @"minute";
                    }
                }
            }
        }
        
        if ([reminderDict valueForKey:EVENT_REMINDER_ADDRESS] != nil) {
            self.deliverAddress = [NSString stringWithString:[reminderDict valueForKey:EVENT_REMINDER_ADDRESS]];
        }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone
{
    Reminder *reminder = [[Reminder alloc] init];
    reminder.offsetTs = self.offsetTs;
    reminder.unit = self.unit;
    reminder.unitCount = self.unitCount;
    reminder.deliverAddress = [NSString stringWithString:self.deliverAddress];

    return reminder;
}

- (NSString*)reminderTime
{
    if ([self.unit isEqualToString:@"minute"]) {
        return [NSString stringWithFormat:@"%li %@", (long)self.unitCount, NSLocalizedString(@"minute(s)",)];
    }
    if ([self.unit isEqualToString:@"hour"]) {
        return [NSString stringWithFormat:@"%li %@", (long)self.unitCount, NSLocalizedString(@"hour(s)",)];
    }
    if ([self.unit isEqualToString:@"day"]) {
        return [NSString stringWithFormat:@"%li %@", (long)self.unitCount, NSLocalizedString(@"day(s)",)];
    }

    return @"";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %ld", self.deliverAddress, self.offsetTs];
}

- (NSDictionary*)toDictionary
{
    NSMutableDictionary *aDict = [[NSMutableDictionary alloc] initWithCapacity:2];
    [aDict setValue:[NSNumber numberWithInteger:self.offsetTs] forKey:EVENT_REMINDER_OFFSET_TS];
    [aDict setValue:self.deliverAddress forKey:EVENT_REMINDER_ADDRESS];
    
    return aDict;
}

@end
