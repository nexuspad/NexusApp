//
//  InputListCell.m
//  nexuspad
//
//  Created by Ren Liu on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BasicItemInputCell.h"
#import "UIColor+NPColor.h"
#import "UIFont+NPFont.h"
#import "ViewDisplayHelper.h"

static int LABEL_TEXT_FIELD_TAG = 99;

@interface BasicItemInputCell()
@end

@implementation BasicItemInputCell

@synthesize inputListTable, itemListArr, itemType = _itemType;

- (void)displayInput:(NSArray*)items itemType:(BasicItemTypes)itemType
{
    _itemType = itemType;

    self.itemListArr = [NSMutableArray arrayWithArray:items];
    [self.itemListArr addObject:[[NPItem alloc] initWithType:itemType]];

    // Create a table view for multiple values
    self.inputListTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.inputListTable.scrollEnabled = NO;
    self.inputListTable.delegate = self;
    self.inputListTable.dataSource = self;
    [self.inputListTable setEditing:YES];

    self.inputListTable.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:self.inputListTable];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect tableRect = CGRectInset(self.contentView.bounds, 4, 0);
    self.inputListTable.frame = tableRect;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.itemListArr count];
}

#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NPItem *item = [self.itemListArr objectAtIndex:indexPath.row];

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    int labelWidth = 120;
    
    // The value textfield
    CGRect rect = CGRectInset(cell.contentView.bounds, 8, 8);
    rect.size.width -= labelWidth;

    UITextField *valueTextField = [[UITextField alloc]initWithFrame:rect];
    
    if (indexPath.row == self.addNewRowRowId) {
        valueTextField.text = @"";
        valueTextField.placeholder = [item itemPlaceholderName];

    } else {
        valueTextField.text = item.value;
    }

    valueTextField.clearsOnBeginEditing = NO;
    valueTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    valueTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    valueTextField.delegate = self;  
    valueTextField.tag = indexPath.row;
    valueTextField.backgroundColor = [UIColor clearColor];
    valueTextField.font = [UIFont valueFont];
    valueTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    if (item.type == PhoneItem) {
        valueTextField.keyboardType = UIKeyboardTypePhonePad;

    } else if (item.type == EmailItem) {
        valueTextField.keyboardType = UIKeyboardTypeEmailAddress;
    }
    
    [cell.contentView addSubview:valueTextField];
    
    // The selection types for input.
    if ([item subTypeSelections] != nil) {
        // The label text field
        rect = CGRectInset(cell.contentView.bounds, 8, 10);
        rect.origin.x += valueTextField.frame.size.width + 2;

        UITextField *labelTextField = [[UITextField alloc]initWithFrame:rect];
        labelTextField.delegate = self;
        
        // Initialize the label picker
        CGRect pickerFrame = CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 216);
        InputValuePickerView *inputValuePickerView = [[InputValuePickerView alloc] initWithFrame:pickerFrame];

        inputValuePickerView.pickerValues = [item subTypeSelections];
        
        labelTextField.inputView = inputValuePickerView;
        
        UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 44)];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      target:self action:@selector(inputAccessoryViewDidCancel)];
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

        UIBarButtonItem *selectButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select",)
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(inputAccessoryViewDidSelect:)];

        [pickerToolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, selectButton, nil] animated:NO];
        
        labelTextField.inputAccessoryView = pickerToolbar;

        if (item.subType == nil || item.subType.length == 0) {
            labelTextField.text = NSLocalizedString(@"Label",);
        } else {
            labelTextField.text = [item.subType capitalizedString];
        }

        labelTextField.font = [UIFont boldSystemFontOfSize:15.0];
        labelTextField.textColor = [UIColor darkBlue];
        labelTextField.tag = LABEL_TEXT_FIELD_TAG;
        
        [cell.contentView addSubview:labelTextField];        
    }
    
    return cell;

}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (indexPath.row == self.addNewRowRowId) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [self.itemListArr removeObjectAtIndex:indexPath.row];
        [self.inputListTable beginUpdates];
        [self.inputListTable deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
        [self.inputListTable endUpdates];

        // Call the parent table to decrease the size of the wrapping cell.
        [self.delegate inputListChanged:self];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


#pragma mark - Textfield delegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // Check if this is a text field for phone/email label. If it is, set the picker selection based on the current value.
    if ([textField.inputView isKindOfClass:[InputValuePickerView class]]) {
        InputValuePickerView *pickerView = (InputValuePickerView*)textField.inputView;
        [pickerView selectPickDefaultValue:textField.text];

    // Check if this row is a "new row" for phone or email. If it is, automatically add another new row.
    } else {

        UITableViewCell *cell = [self findParentTableViewCell:textField];
        long rowForThisCell = [[self.inputListTable indexPathForCell:cell] row];
        
        if (rowForThisCell == self.addNewRowRowId) {
            // Update the datasource
            NPItem *addNewItem = [[NPItem alloc] initWithType:self.itemType];
            [self.itemListArr addObject:addNewItem];
            
            NSArray *paths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.addNewRowRowId inSection:0]];
            
            [self.inputListTable beginUpdates];
            [self.inputListTable insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationTop];
            [self.inputListTable endUpdates];

            self.inputListTable.editing = NO;
            self.inputListTable.editing = YES;
            
            // Call the parent table to increase the size of the wrapping cell.
            [self.delegate inputListChanged:self];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    UITableViewCell *cell = [self findParentTableViewCell:textField];

    NSInteger row = [[self.inputListTable indexPathForCell:cell] row];
    
    if ([self.itemListArr objectAtIndex:row] != nil) {
        NPItem *item = [self.itemListArr objectAtIndex:row];
        
        if (textField.tag == LABEL_TEXT_FIELD_TAG) {                       // This is a label text field
            if ([textField.text length] > 0){
                item.subType = textField.text;
                [textField.text capitalizedString];
            }

        } else {
            item.value = textField.text;
        }

    } else {
        DLog(@"Error locating the item using the row number: %li", (long)row);
    }
}

- (NSInteger)addNewRowRowId
{
    return [self.itemListArr count] - 1;
}

- (void)inputAccessoryViewDidCancel {
    [self endEditing:YES];
}

- (void)inputAccessoryViewDidSelect:(id)sender {
    UIView* currentFirstResponder = [self findFirstResponder];
    
    if ([currentFirstResponder isKindOfClass:[UITextField class]]) {
        currentFirstResponder = (UITextField*)currentFirstResponder;
        if (currentFirstResponder.tag == LABEL_TEXT_FIELD_TAG) {
            InputValuePickerView *labelPicker = (InputValuePickerView*)currentFirstResponder.inputView;
            NSInteger row = [labelPicker.valuePicker selectedRowInComponent:0];
            
            NSString *label = [[labelPicker.pickerValues objectForKey:[NSNumber numberWithInt:0]] objectAtIndex:row];
            
            [self setSelectedValue:label];
        }
    }
}

// Find the UITableViewCell who is the parent of the UITextField.
// This is a hackish way and needs to be thought over.
- (UITableViewCell*)findParentTableViewCell:(UIView*)view {
    UIView *contentView = (UITableViewCell*)view.superview;
    if ([contentView.superview isKindOfClass:[UITableViewCell class]]) {
        return (UITableViewCell*)contentView.superview;
    } else if ([contentView.superview.superview isKindOfClass:[UITableViewCell class]]) {
        return (UITableViewCell*)contentView.superview.superview;
    }
    
    return nil;
}


#pragma mark - picker delegate
- (void)setSelectedValue:(id)value
{
    UIView* currentFirstResponder = [self findFirstResponder];

    if ([currentFirstResponder isKindOfClass:[UITextField class]]) {
        
        UITextField *currentTextField = (UITextField*)currentFirstResponder;
        
        if ([value isEqualToString:NSLocalizedString(@"other",)]) {
            [currentFirstResponder resignFirstResponder];
            currentTextField.inputView = nil;
            currentTextField.text = @"";
            [currentFirstResponder becomeFirstResponder];

        } else {
            currentTextField.text = [value capitalizedString];
            [currentFirstResponder resignFirstResponder];
        }
        
        // The item.subType is set after resigning the first responder, and inside textFieldDidEndEditing
    }
}


@end
