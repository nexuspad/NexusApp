//
//  NPMessage.m
//  nexuspad
//
//  Created by Ren Liu on 9/9/12.
//
//

#import "NPMessage.h"

@implementation NPMessage

@synthesize subject, messageBody, emailAddresses;

- (id)init
{
    self = [super init];
    self.subject = @"";
    self.messageBody = @"";
    return self;
}

- (void)addEmailAddress:(NSString*)emailAddr
{
    if (self.emailAddresses == nil || [self.emailAddresses count] == 0) {
        self.emailAddresses = [NSArray arrayWithObject:emailAddr];
    } else {
        NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:self.emailAddresses];
        [tmpArr addObject:emailAddr];
        self.emailAddresses = [NSArray arrayWithArray:tmpArr];
    }
}

@end
