//
//  InputValuePickerView.m
//  nexuspad
//
//  Created by Ren Liu on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InputValuePickerView.h"


@implementation InputValuePickerView

@synthesize valuePicker, pickerValues = _pickerValues;

- (void)setPickerValues:(id)values
{
    if ([values isKindOfClass:[NSDictionary class]]) {
        _pickerValues = values;
        
    } else if ([values isKindOfClass:[NSArray class]]) {
        NSMutableDictionary *valDict = [[NSMutableDictionary alloc] initWithCapacity:1];
        [valDict setObject:values forKey:[NSNumber numberWithInt:0]];
        _pickerValues = valDict;
    }
    
    // _pickerValues looks like this:
    //    $1 = 0x0ac987a0 {
    //        0 =     (
    //                 "Select label",
    //                 home,
    //                 mobile,
    //                 work,
    //                 fax,
    //                 other
    //                 );
    //    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Set up a simple list picker
        self.valuePicker = [[UIPickerView alloc] initWithFrame:frame];
        self.valuePicker.delegate = self;
        self.valuePicker.showsSelectionIndicator = YES;
        [self addSubview:self.valuePicker];
    }
    return self;
}

// Selected a row based on the value
- (void)selectPickDefaultValue:(NSString*)value {
    NSArray *values = [_pickerValues objectForKey:[NSNumber numberWithInt:0]];
    long row = [values indexOfObject:[value lowercaseString]];
    if (row != NSNotFound) {
        [self.valuePicker selectRow:row inComponent:0 animated:YES];
    }
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.pickerValues objectForKey:[NSNumber numberWithInteger:component]] objectAtIndex:row];
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return [self.pickerValues count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self.pickerValues objectForKey:[NSNumber numberWithInteger:component]] count];
}

@end
