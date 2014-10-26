//
//  NPMessage.h
//  nexuspad
//
//  Created by Ren Liu on 9/9/12.
//
//

#import <Foundation/Foundation.h>

@interface NPMessage : NSObject

@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSString *messageBody;
@property (nonatomic, strong) NSArray *emailAddresses;

- (void)addEmailAddress:(NSString*)emailAddr;

@end
