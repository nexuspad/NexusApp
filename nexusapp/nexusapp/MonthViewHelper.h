//
//  MonthViewHelper.h
//  nexusapp
//
//  Created by Ren Liu on 10/10/13.
//
//

#import <Foundation/Foundation.h>
#import "CalendarMonthView.h"
#import "EntryList.h"
#import "CalendarViewPresenterDelegate.h"

@interface MonthViewHelper : NSObject <CalendarMonthViewDelegate,
                                        UITableViewDelegate,
                                        UITableViewDataSource>

- (id)initWithFrame:(CGRect)frame parentView:(UIView*)parentView;

@property (nonatomic, strong) NPFolder *folder;
@property (nonatomic, strong) NSDate *currentSelectedDate;

@property (nonatomic, strong) CalendarMonthView *monthView;

@property (nonatomic, weak) id<CalendarViewPresenterDelegate> controllerDelegate;

- (void)refreshView:(NPFolder*)inFolder withEntryList:(EntryList*)withEntryList;

- (void)clearMonthViewData;

- (NSArray*)getCurrentStartEndDates;

- (void)cleanup;

@end
