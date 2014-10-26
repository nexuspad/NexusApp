//
//  InputListCell.h
//  nexuspad
//
//  Created by Ren Liu on 7/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoreSettings.h"
#import "InputValuePickerView.h"
#import "NPItem.h"
#import "Constants.h"
#import "UIView+FindFirstResponder.h"

@protocol InputCellInputTextValueChangeDelegate <NSObject>
- (void)inputListChanged:(id)sender;
@end

@interface BasicItemInputCell : UITableViewCell <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, InputValueSelectedDelegate>

@property int parentTableSection;
@property int parentTableRow;

@property (nonatomic, strong) NSMutableArray *itemListArr;
@property (nonatomic, strong) UITableView *inputListTable;

@property (nonatomic, weak) id<InputCellInputTextValueChangeDelegate> delegate;

@property BasicItemTypes itemType;

- (void)displayInput:(NSArray*)items itemType:(BasicItemTypes)itemType;

@end
