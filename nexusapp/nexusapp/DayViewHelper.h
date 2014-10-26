//
//  EventDayViewPresenter.h
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import <Foundation/Foundation.h>
#import "NPScrollView.h"
#import "EventDayScrollView.h"
#import "EntryList.h"
#import "CalendarViewPresenterDelegate.h"

@interface DayViewHelper : NSObject <UIGestureRecognizerDelegate,
                                    NPScrollViewPageDataDelegate,
                                    EventDayScrollViewDelegate>

@property (nonatomic, strong) NPFolder *folder;

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NPScrollView *dayScrollView;

@property (nonatomic, weak) id<CalendarViewPresenterDelegate> controllerDelegate;

- (id)initWithDate:(NSDate*)date;

- (void)refreshView:(NSDate*)forDate inFolder:(NPFolder*)inFolder withEntryList:(EntryList*)withEntryList;
- (UIView*)clearDataAndRefreshDayView:(NSDate*)forDate inFolder:(NPFolder*)inFolder;

@end
