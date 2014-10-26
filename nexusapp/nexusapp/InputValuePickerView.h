//
//  InputValuePickerView.h
//  nexuspad
//
//  Created by Ren Liu on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InputValueSelectedDelegate.h"

@interface InputValuePickerView : UIView <UIPickerViewDelegate,UIPickerViewDataSource>

@property (nonatomic, strong) UIPickerView *valuePicker;

@property (nonatomic, strong) id pickerValues;

- (void)selectPickDefaultValue:(NSString*)value;

@end
