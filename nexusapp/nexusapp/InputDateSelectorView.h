//
//  InputDateSelectorView.h
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TKCalendarMonthView.h"
#import "CoreSettings.h"

@protocol DateSelectedDelegate <NSObject>
- (void)didSelectedDate:(id)sender;

@optional
- (void)inputDateSelectorCancelled;
@end

@interface InputDateSelectorView : UIView <TKCalendarMonthViewDelegate>

- (id)init:(UIView*)parentView asInputView:(BOOL)asInputView;
- (id)initWithToolBar:(UIView*)parentView asInputView:(BOOL)asInputView;

- (void)selectDate:(NSDate*)date;

- (void)slideOff;
- (void)slideIn;

@property BOOL isVisible;
@property (nonatomic, weak) id<DateSelectedDelegate> delegate;

+ (CGSize)getInputViewSize;

@end
