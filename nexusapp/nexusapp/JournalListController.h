//
//  JournalListController.h
//  nexuspad
//
//  Created by Ren Liu on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseEntryListViewController.h"
#import "InputMonthSelector.h"
#import "InputDateSelectorView.h"

@interface JournalListController : BaseEntryListViewController <InputMonthSelectedDelegate>

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

// Delegate is the JournalViewController to handle selecting a row
@property (nonatomic, strong) id<DateSelectedDelegate> delegate;

- (IBAction)selectMonth:(id)sender;

@end
