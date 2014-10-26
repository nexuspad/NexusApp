//
//  EntryViewInfoDelegate.h
//  nexuspad
//
//  Created by Ren Liu on 9/18/12.
//
//

#import <Foundation/Foundation.h>

@protocol EntryViewInfoDelegate <NSObject>

@optional
- (void)updatePrompt:(NSString*)promptMessage;

@end
