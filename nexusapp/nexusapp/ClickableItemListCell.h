//
//  LabelValueCell.h
//  nexuspad
//
//  Created by Ren Liu on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ClickableItemListCell : UITableViewCell <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UITableView *valueListTable;

@property (nonatomic, strong) NSArray *valueDataList;

- (void)displayValue:(NSString*)valueName valueData:(id)valueData;

@end
