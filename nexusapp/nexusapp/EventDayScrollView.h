//
//  HourGridTableView.h
//  nexusapp
//
//  Created by Ren Liu on 9/3/13.
//
//

#import <UIKit/UIKit.h>
#import "NPEvent.h"

@protocol EventDayScrollViewDelegate <NSObject>
- (void)openEventDetail:(NPEvent*)event;
@end

// For event day view in NPScrollView
@interface EventDayScrollView : UIScrollView <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIColor *calendarColor;

@property (nonatomic, weak) id<EventDayScrollViewDelegate> eventViewDelegate;

- (void)displayEvents:(NSArray*)dayEvents hourEventsInfo:(NSArray*)hourEventsInfo;

- (void)clearEventViews;

@end