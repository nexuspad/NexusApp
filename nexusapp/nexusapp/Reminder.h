//
//  Reminder.h
//  nexuspad
//
//  Created by Ren Liu on 8/9/12.
//
//

#import <Foundation/Foundation.h>

@interface Reminder : NSObject

@property NSInteger unitCount;
@property (nonatomic, strong) NSString *unit;

@property long offsetTs;
@property (nonatomic, strong) NSString *deliverAddress;

- (Reminder*)initWithData:(NSDictionary*)reminderDict;

- (NSString*)reminderTime;

- (NSDictionary*)toDictionary;

@end
