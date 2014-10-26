//
//  LabelValueCell.m
//  nexuspad
//
//  Created by Ren Liu on 6/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ClickableItemListCell.h"
#import "UIColor+NPColor.h"
#import "UIFont+NPFont.h"
#import "NSString+NPStringUtil.h"
#import "UIBasicItemButton.h"
#import "NPItem.h"
#import "Constants.h"

@implementation ClickableItemListCell

@synthesize nameLabel, valueLabel, valueListTable, valueDataList;


- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{    
    if (!(self=[super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        return nil;
    }

    return self;
}

- (id) initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	return self;
}

- (void)displayValue:(NSString*)valueName valueData:(id)valueData
{
    if (valueName != nil && [valueName length] > 0) {
        if (self.nameLabel == nil) {
            self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.nameLabel.backgroundColor = [UIColor clearColor];
            self.nameLabel.textAlignment = NSTextAlignmentRight;
            self.nameLabel.textColor = [UIColor darkBlue];
            self.nameLabel.font = [UIFont labelFont];
            self.nameLabel.adjustsFontSizeToFitWidth = YES;
            self.nameLabel.baselineAdjustment = UIBaselineAdjustmentNone;
            self.nameLabel.numberOfLines = 20;
            [self.contentView addSubview:self.nameLabel];
        }
        self.nameLabel.text = [valueName capitalizedString];
    }

    // The value is a simple string
    if ([valueData isKindOfClass:[NSString class]]) {
        if (self.valueLabel == nil) {
            self.valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.valueLabel.font = [UIFont valueFont];
            self.valueLabel.backgroundColor = [UIColor clearColor];
            [self.valueLabel sizeToFit];
            [self.contentView addSubview:self.valueLabel];   
        }
        self.valueLabel.text = valueData;
        
    } else if ([valueData isKindOfClass:[NSArray class]]) { 
        self.valueDataList = valueData;
        // Create a table view for multiple values
        if (self.valueListTable == nil) {
            self.valueListTable = [[UITableView alloc] initWithFrame:CGRectZero];
            self.valueListTable.backgroundColor = [UIColor clearColor];
            self.valueListTable.scrollEnabled = NO;
            self.valueListTable.delegate = self;
            self.valueListTable.dataSource = self;
            if ([valueData count] == 1) {
                self.valueListTable.separatorStyle = UITableViewCellSeparatorStyleNone;
            }
            [self.contentView addSubview:self.valueListTable];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
	
    float valuePositionOffset = 4.0;
    float valueRightPadding = 8.0;
    
    if (self.nameLabel != nil) {
        CGRect labelRect = CGRectMake(8.0, 8.0, 67, 25);
        self.nameLabel.frame = labelRect;   
        valuePositionOffset = self.nameLabel.frame.size.width + 14.0;
    }

    if (self.valueLabel != nil) {
        CGRect valueRect = CGRectInset(self.contentView.bounds, 0, 4.0);
        valueRect.origin.x += valuePositionOffset;
        valueRect.size.width = valueRect.size.width - valuePositionOffset - valueRightPadding;
        self.valueLabel.frame = valueRect;
    }
    
    if (self.valueListTable != nil) {
        CGRect tableRect = CGRectInset(self.contentView.bounds, 0, 0);
        tableRect.origin.x += valuePositionOffset;
        tableRect.size.width = tableRect.size.width - valuePositionOffset - valueRightPadding;
        self.valueListTable.frame = tableRect;
        [self.valueListTable reloadData];
    }

}


#pragma mark - Table view data source

// for displaying value in a list
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.valueDataList count];
}

#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NPItem *item = [self.valueDataList objectAtIndex:indexPath.row];

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ValueListCellWithTypeLabel"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGRect labelRect = CGRectMake(0.0, 12.0, 72, 18);
    UILabel *typeLabel = [[UILabel alloc] initWithFrame:labelRect];
    typeLabel.textAlignment = NSTextAlignmentRight;
    typeLabel.font = [UIFont labelFont];
    typeLabel.textColor = [UIColor darkBlue];
    typeLabel.backgroundColor = [UIColor clearColor];
    
    if (item.subType != nil && item.subType.length > 0) {
        typeLabel.text = [item.subType capitalizedString];
    } else {
        if (item.type == PhoneItem) {
            typeLabel.text = NSLocalizedString(@"Phone",);
        }
        else if (item.type == EmailItem) {
            typeLabel.text = NSLocalizedString(@"Email",);
        }
    }
    
    [cell.contentView addSubview:typeLabel];

    int valuePositionOffset = typeLabel.frame.size.width + 6.0;

    CGRect valueRect = CGRectInset(cell.contentView.frame, 0, 0);
    valueRect.origin.x += valuePositionOffset;
    valueRect.size.width = valueRect.size.width - valuePositionOffset - 28.0;   // 28 is some additional padding for the button
    
    UIBasicItemButton *valueButton = [[UIBasicItemButton alloc] initWithFrame:valueRect];
    
    valueButton.item = item;
    
    [valueButton setTitle:[item getDisplayValue] forState:UIControlStateNormal];

    [valueButton addTarget:self action:@selector(callOrEmail:) forControlEvents:UIControlEventTouchDown];
    
    [cell.contentView addSubview:valueButton];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath { 
    return 44.0;
}

- (void)callOrEmail:(UIBasicItemButton*)button
{
    NPItem *item = button.item;
    if (item.type == PhoneItem) {
        NSString *actionString = [NSString stringWithFormat:@"telprompt://%@", item.value];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionString]];
        
    } else if (item.type == EmailItem) {
        NSString *actionString = [NSString stringWithFormat:@"mailto://%@", item.value];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:actionString]];
    }
}

@end
