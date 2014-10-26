//
//  DateRangeSelectorViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InputValueSelectedDelegate.h"
#import "InputDateSelectorView.h"
#import "KHFlatButton.h"
#import "InputWeekSelector.h"
#import "InputMonthSelector.h"

typedef enum {is_week, is_month, is_arbitrary} DateRangeType;

@protocol DateRangeSelectDelegate <NSObject>
- (void)dateRangeSelected:(NSDate*)startDate endDate:(NSDate*)endDate;
@end

@interface DateRangeSelectorViewController : UITableViewController <InputMonthSelectedDelegate,
                                                                InputWeekSelectedDelegate,
                                                                DateSelectedDelegate,
                                                                UITextFieldDelegate,
                                                                UITableViewDataSource,
                                                                UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) id<DateRangeSelectDelegate> delegate;

- (void)setStartEndDates:(NSDate*)startDate endDate:(NSDate*)endDate;

@end
