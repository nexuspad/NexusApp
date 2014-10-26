//
//  CalendarViewController.h
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import "BaseEntryListViewController.h"
#import "DateRangeSelectorViewController.h"
#import "EventService.h"
#import "CalendarViewPresenterDelegate.h"
#import "InputDateSelectorView.h"

typedef enum {DayView, MonthView, AgendaView} CalendarViewType;

@interface CalendarViewController : BaseEntryListViewController <DateRangeSelectDelegate,
                                                                DateSelectedDelegate,
                                                                CalendarViewPresenterDelegate,
                                                                UITableViewDelegate,
                                                                UIScrollViewDelegate,
                                                                UISearchBarDelegate,
                                                                UIActionSheetDelegate>

@property CalendarViewType viewType;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) EventService *eventService;
@property (nonatomic, strong) NSDate *selectedDate;

@end
