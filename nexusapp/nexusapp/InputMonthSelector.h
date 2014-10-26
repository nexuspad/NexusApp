//
//  InputMonthSelector.h
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import <UIKit/UIKit.h>
#import "CoreSettings.h"

@protocol InputMonthSelectedDelegate <NSObject>
- (void)didSelectMonth:(id)value;

@optional
- (void)inputMonthSelectorCancelled;
- (void)done;
@end

@interface InputMonthSelector : UIView<UIPickerViewDelegate,UIPickerViewDataSource>

- (id)initWithToolBar:(UIView*)parentView preselectYear:(int)preselectYear preselectMonth:(int)preselectMonth;

@property BOOL isVisible;

- (void)slideOff;
- (void)slideIn:(UIView*)parentView;

@property (nonatomic, weak) id<InputMonthSelectedDelegate> delegate;

@end
