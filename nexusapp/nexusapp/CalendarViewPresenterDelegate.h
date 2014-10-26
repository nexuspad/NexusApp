//
//  CalendarViewPresenterDelegate.h
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import <Foundation/Foundation.h>
#import "NPEvent.h"

@protocol CalendarViewPresenterDelegate <NSObject>

- (void)displayEventDetail:(NPEvent*)event;
- (void)deleteEvent:(NPEvent*)event;

@optional
- (void)changeCalendarViewDate:(NSDate*)aDate;

- (void)requestDataToRefreshView;
- (void)getMoreEventsForAgendaView;
- (void)getEventsForMonthView:(NSDate*)monthStartDate;

@end
