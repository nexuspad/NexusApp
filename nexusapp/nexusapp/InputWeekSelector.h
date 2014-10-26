//
//  InputWeekSelector.h
//  nexuspad
//
//  Created by Ren Liu on 8/14/12.
//
//

#import <UIKit/UIKit.h>
#import "InputValueSelectedDelegate.h"

@protocol InputWeekSelectedDelegate <NSObject>
- (void)didSelectWeek:(id)value;

@optional
- (void)inputWeekSelectorCancelled;
- (void)done;
@end

@interface InputWeekSelector : UIView<UIPickerViewDelegate,UIPickerViewDataSource>

- (id)initWithToolBar:(UIView*)parentView startDate:(NSDate*)startDate endDate:(NSDate*)endDate;

@property BOOL isVisible;

- (void)slideOff;
- (void)slideIn:(UIView*)parentView;

@property (nonatomic, weak) id<InputWeekSelectedDelegate> delegate;

@end
