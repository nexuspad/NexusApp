//
//  InputValueSelectedDelegate.h
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol InputValueSelectedDelegate <NSObject>

- (void)setSelectedValue:(id)sender;

@optional
- (void)inputValueSelectorCancelled;
- (void)done;

@end
