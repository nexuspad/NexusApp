//
//  CalendarViewController.m
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import "CalendarViewController.h"
#import "EventViewController.h"
#import "EventEditorViewController.h"
#import "DayViewHelper.h"
#import "AgendaViewHelper.h"
#import "MonthViewHelper.h"
#import "DateUtil.h"
#import "UILabel+NPUtil.h"
#import "UserPrefUtil.h"
#import "EventListViewCell.h"
#import "UIViewController+KNSemiModal.h"
#import "DropdownButton.h"


@interface CalendarViewController ()
@property (strong, nonatomic) UISegmentedControl *viewSegments;
@property (nonatomic, strong) DayViewHelper *dayViewHelper;
@property (nonatomic, strong) AgendaViewHelper *agendaViewHelper;
@property (nonatomic, strong) MonthViewHelper *monthViewHelper;
@property (nonatomic, strong) InputDateSelectorView *dateSelector;
@property (nonatomic, strong) NSDate *lastAccessTime;
@property (nonatomic, strong) DateRangeSelectorViewController *drsvc;

// Search result
@property (nonatomic, strong) NSMutableArray *searchResultBySection;

@property (nonatomic, strong) CalendarViewController *childCalendarViewController;

@end

@implementation CalendarViewController

@synthesize selectedDate = _selectedDate;


// This overrides the same name method defined in EntryListController. It is called in ViewDidLoad.
- (void)retrieveEntryList {
    self.entryListIsLoading = YES;
    
    if (self.currentEntryList == nil && ![self.currentFolder isEqual:self.currentEntryList.folder]) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:event];
    }
    
    // Assign today to self.selectedDate. A NP service call will be made in the setter method.
    if (self.selectedDate == nil) {
        self.selectedDate = [DateUtil dateOnly:[NSDate date]];
    }
    
    [self setViewTitle];

    // Make the web service call to retrieve the events
    
    if (self.viewType == DayView) {
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];
        [self.entryListService getEntriesByDateRange:event
                                            inFolder:self.currentFolder
                                           startDate:self.selectedDate
                                             endDate:self.selectedDate];
        
    } else if (self.viewType == MonthView) {
        NSArray *startEndDates = [self.monthViewHelper getCurrentStartEndDates];
        if (startEndDates != nil) {
            DLog(@"Retrieve events for month view between: %@ and %@", startEndDates[0], startEndDates[1]);
            self.startDate = startEndDates[0];
            self.endDate = startEndDates[1];
            [self.monthViewHelper clearMonthViewData];
            
            [ViewDisplayHelper displayWaiting:self.view messageText:nil];
            [self.entryListService getEntriesByDateRange:event
                                                inFolder:self.currentFolder
                                               startDate:self.startDate
                                                 endDate:self.endDate];
        }
        
    } else {
        [ViewDisplayHelper displayWaiting:self.view messageText:nil];
        [self.entryListService getEntriesByDateRange:event
                                            inFolder:self.currentFolder
                                           startDate:self.startDate
                                             endDate:self.endDate];
    }
}


// Set the folder in each view helpers.
- (void)setCurrentFolder:(NPFolder *)newFolder {
    [super setCurrentFolder:newFolder];

    if (self.dayViewHelper != nil) {
        self.dayViewHelper.folder = newFolder;
    }
    if (self.monthViewHelper != nil) {
        self.monthViewHelper.folder = newFolder;
    }
    if (self.agendaViewHelper != nil) {
        self.agendaViewHelper.folder = newFolder;
    }
}


// Delegate method for refreshing DayView
- (void)changeCalendarViewDate:(NSDate *)aDate {
    [self clearDayViewScreen];
    
    _selectedDate = aDate;
    [self setViewTitle];
    [self retrieveEntryList];
}


// Delegate method called by MonthViewHelper to retrieve events for a month, this is called when a month
// is scrolled into the view.
- (void)getEventsForMonthView:(NSDate *)monthStartDate {
    self.startDate = monthStartDate;
    self.endDate = [DateUtil addDays:[DateUtil addMonths:monthStartDate months:1] days:-1];

    [self.entryListService getEntriesByDateRange:event
                                        inFolder:self.currentFolder
                                       startDate:self.startDate
                                         endDate:self.endDate];
}

// Delegate method for loading more events for Agenda view
- (void)getMoreEventsForAgendaView {
    self.endDate = [DateUtil addWeeks:self.endDate weeks:4];
    [self retrieveEntryList];
}


// This is the delegate method for NP EntryService
- (void)updateServiceResult:(id)serviceResult {
    [super updateServiceResult:serviceResult];
    
    // The service result could be EntryActionResult. We need to check the object type.
    if ([serviceResult isKindOfClass:[EntryList class]]) {
        EntryList *returnedList = (EntryList*)serviceResult;

        if (![returnedList isSearchResult]) {                                           // Regular listing result
            self.currentEntryList = [serviceResult copy];
            
            NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[self.currentEntryList.entries count]];
            
            // If we are looking at all events, we need to check if there is any calendars that are hidden
            NSArray *hiddenCals = [[NSArray alloc] init];
            if (self.currentEntryList.folder.folderId == ROOT_FOLDER) {
                hiddenCals = [UserPrefUtil getHiddenCalendars];
            }
            
            for (NPEntry *e in self.currentEntryList.entries) {
                // Check if the event is in one of those hidden calendars. If so, do not include it in final event list.
                if ([hiddenCals containsObject:[e.folder uniqueKey]]) {        // This is ok for NSString because it uses isEqualsToString method
                    continue;
                }
                
                NPEvent *anEvent = [NPEvent eventFromEntry:e];
                
                // For monthview, double check the event start time. It could cause issue on monthview so just be caucious here.
                //
                // Also the self.currentEntryList.endDate should have been adjusted to the end of day, otherwise, the events in the last
                // day of month might be filtered out.
                //
                if (self.viewType == MonthView) {
                    if (anEvent != nil &&
                        [DateUtil date:anEvent.startTime isBetweenDate:self.currentEntryList.startDate andDate:self.currentEntryList.endDate])
                    {
                        NSArray *eventDayParts = [NPEvent splitMultiDayEvent:anEvent];
                        [events addObjectsFromArray:eventDayParts];
                    }

                } else {
                    if (anEvent != nil) {
                        NSArray *eventDayParts = [NPEvent splitMultiDayEvent:anEvent];
                        [events addObjectsFromArray:eventDayParts];
                    }
                }
            }
            
            self.currentEntryList.entries = events;
            
            if (self.viewType == DayView) {
                [self.dayViewHelper refreshView:_selectedDate
                                       inFolder:self.currentFolder
                                  withEntryList:self.currentEntryList];
                
            } else if (self.viewType == MonthView) {
                [self.monthViewHelper refreshView:self.currentFolder
                                    withEntryList:self.currentEntryList];
                
            } else if (self.viewType == AgendaView) {
                [self.agendaViewHelper refreshView:self.currentFolder
                                         startDate:self.startDate
                                           endDate:self.endDate
                                     withEntryList:self.currentEntryList];
            }

        } else {
            if (self.searchResultList == nil) {
                self.searchResultList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:event];
            }
            self.searchResultList = returnedList;
            
            NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[self.currentEntryList.entries count]];
            
            for (NPEntry *e in self.searchResultList.entries) {
                NPEvent *anEvent = [NPEvent eventFromEntry:e];
                
                if (anEvent != nil) {
                    NSArray *eventDayParts = [NPEvent splitMultiDayEvent:anEvent];
                    [events addObjectsFromArray:eventDayParts];
                }
            }
            
            self.searchResultList.entries = events;

            [self refreshSearchResultTable];
        }

    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        if (actionResponse.success) {
            //
            // Use the notification route so the same logic only appears in handleEntryDeletedNotification
            //
            //
            if ([actionResponse.name isEqualToString:ACTION_REFRESH_ENTRIES]) {
                [NotificationUtil sendEntryDeletedNotification:[actionResponse.entries objectAtIndex:0]];
            } else if ([actionResponse.name isEqualToString:ACTION_DELETE_ENTRY]) {
                [NotificationUtil sendEntryDeletedNotification:actionResponse.entry];
            }
        }
    }
}


- (void)showItemsAfterSelectingFolder:(NPFolder*)selectedFolder {
    [ViewDisplayHelper popViewControllerBottomDown:self.navigationController];
    self.currentFolder = [selectedFolder copy];

    [self retrieveEntryList];
}


- (void)createNewEntry {
    [self performSegueWithIdentifier:@"NewEvent" sender:self];
}


#pragma mark - change date range with segmented control switch

- (void)segmentedControlValueChanged:(id)sender {
    // make sure unhide this.
    self.navigationController.toolbarHidden = NO;
    
    [self.dayViewHelper.dayScrollView removeFromSuperview];
    [self.monthViewHelper.monthView removeFromSuperview];
    [self.agendaViewHelper.agendaTableView removeFromSuperview];

    if (self.viewSegments.selectedSegmentIndex == 0) {              // Switch to day view
        self.viewType = DayView;
        if (self.dayViewHelper == nil) {
            [self initCalendarViews:NO];
        }

        [self.view addSubview:self.dayViewHelper.dayScrollView];
        [UserPrefUtil setPreference:[NSNumber numberWithInt:DayView] forKey:PREF_LAST_CALENDAR_VIEW];
        
    } else if (self.viewSegments.selectedSegmentIndex == 1) {
        self.viewType = MonthView;
        if (self.monthViewHelper == nil) {
            [self initCalendarViews:NO];
        }

        [self.view addSubview:self.monthViewHelper.monthView];
        
        if (_selectedDate != nil) {
            [self.monthViewHelper.monthView scrollToDate:_selectedDate animated:NO];
        } else {
            [self.monthViewHelper.monthView scrollToDate:[NSDate date] animated:NO];
        }

        [UserPrefUtil setPreference:[NSNumber numberWithInt:MonthView] forKey:PREF_LAST_CALENDAR_VIEW];
        
    } else if (self.viewSegments.selectedSegmentIndex == 2) {       // Switch to agenda
        self.viewType = AgendaView;
        if (self.agendaViewHelper == nil) {
            [self initCalendarViews:NO];
        }
        
        [self.view addSubview:self.agendaViewHelper.agendaTableView];
        
        // The date range needs to be reset for agenda
        [self getDetaultDateRange];

        [UserPrefUtil setPreference:[NSNumber numberWithInt:AgendaView] forKey:PREF_LAST_CALENDAR_VIEW];
    }

    [self retrieveEntryList];

    [self setViewTitle];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"OpenEvent"]) {
        [segue.destinationViewController setEvent:sender];
        
    } else if ([segue.identifier isEqualToString:@"OpenDateRangeSelector"]) {
        DateRangeSelectorViewController *dateRangeController = (DateRangeSelectorViewController*)[[[segue destinationViewController] viewControllers] objectAtIndex:0];
        dateRangeController.delegate = self;
        [dateRangeController setStartEndDates:self.startDate endDate:self.endDate];

    } else if ([segue.identifier isEqualToString:@"NewEvent"]) {
        EventEditorViewController* editorController = (EventEditorViewController*)[segue destinationViewController];
        
        NPEvent *newEvent;
        
        if (self.viewType == MonthView && self.monthViewHelper.currentSelectedDate != nil) {
            newEvent = [[NPEvent alloc] initWithDate:self.monthViewHelper.currentSelectedDate];
        } else {
            newEvent = [[NPEvent alloc] initWithDate:self.selectedDate];
        }
        
        newEvent.noStartingTime = YES;                                      // Let the user to select time
        if (self.currentFolder.folderId == 0) {
            newEvent.folder.folderId = -1;
        } else {
            newEvent.folder.folderId = self.currentFolder.folderId;
        }
        
        newEvent.folder = [self.currentFolder copy];
        newEvent.accessInfo = [self.currentFolder.accessInfo copy];
        
        editorController.event = newEvent;
    }
}

#pragma mark - select the date for day view, or segue to date range selector

- (IBAction)changeDate:(id)sender {
    if (self.viewType == DayView) {
        if (self.dateSelector == nil) {
            self.dateSelector = [[InputDateSelectorView alloc] init:self.view asInputView:NO];
            self.dateSelector.delegate = self;
        }

        [self presentSemiView:self.dateSelector withOptions:@{
                                                              KNSemiModalOptionKeys.pushParentBack    : @(YES),
                                                              KNSemiModalOptionKeys.animationDuration : @(0.3),
                                                              KNSemiModalOptionKeys.shadowOpacity     : @(0.3),
                                                              }];

    } else if (self.viewType == AgendaView) {
        if (self.drsvc == nil) {
            self.drsvc = [self.storyboard instantiateViewControllerWithIdentifier:@"DateRangeSelector"];
            self.drsvc.delegate = self;
        }
        
        [self.drsvc setStartEndDates:self.startDate endDate:self.endDate];
        
        CGRect rect = CGRectMake(0, 0, 320, 264);
        self.drsvc.view.frame = rect;
        [self presentSemiView:self.drsvc.view withOptions:@{
                                                            KNSemiModalOptionKeys.pushParentBack    : @(YES),
                                                            KNSemiModalOptionKeys.animationDuration : @(0.3),
                                                            KNSemiModalOptionKeys.shadowOpacity     : @(0.3),
                                                            }];

    }
}


// Set the title in navigation
- (void)setViewTitle {
    if (self.viewType == DayView) {
        if (self.currentFolder.folderId != ROOT_FOLDER) {
            DropdownButton *navButton = [[DropdownButton alloc] init:self action:@selector(changeDate:)
                                                               line1:[self.currentFolder displayName]
                                                               line2:[DateUtil displayEventWeekdayAndDate:_selectedDate]
                                                          rightImage:[UIImage imageNamed:@"arrow-down.png"]];
            self.navigationItem.titleView = navButton;
            
        } else {
            DropdownButton *navButton = [[DropdownButton alloc] init:self action:@selector(changeDate:)
                                                               line1:[DateUtil displayEventWeekdayAndDate:_selectedDate]
                                                               line2:nil
                                                          rightImage:[UIImage imageNamed:@"arrow-down.png"]];
            self.navigationItem.titleView = navButton;
        }

    } else if (self.viewType == MonthView) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = [self.currentFolder displayName];
        
    } else if (self.viewType == AgendaView) {
        DropdownButton *navButton = [[DropdownButton alloc] init:self action:@selector(changeDate:)
                                                           line1:[self.currentFolder displayName]
                                                           line2:[DateUtil displayDateRange:self.startDate date2:self.endDate]
                                                      rightImage:[UIImage imageNamed:@"arrow-down.png"]];
        self.navigationItem.titleView = navButton;
    }
}



#pragma mark - Calendar view presenter delegate

// Display event detail in next screen
// All 3 views use this delegate method to display the event detail view
- (void)displayEventDetail:(NPEvent *)e {
    // Do nothing if the slide menu is there.
    if (self.sharersMenu != nil && [self.sharersMenu isMenuOpen]) {
        return;
    }
    
    [self clearDayViewScreen];
    [self performSegueWithIdentifier:@"OpenEvent" sender:[e copy]];
}

// Delegate call to retrieve data
- (void)requestDataToRefreshView {
    [self retrieveEntryList];
}

// Delegate call to delete an event
- (void)deleteEvent:(NPEvent *)event {
    for (NPEvent *e in self.currentEntryList.entries) {
        if ([e.entryId isEqualToString:event.entryId] && e.recurId == event.recurId) {
            e.status = ENTRY_STATUS_DELETED;
        }
    }
    
    // Prompt based on whether it is recurring or not.
    if ([event isRecurring]) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];

        actionSheet.title = NSLocalizedString(@"This is a recurring event",);
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete only this event",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete this and all future ones",)];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete all",)];
        
        actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
        [actionSheet showFromToolbar:self.navigationController.toolbar];
        
    } else {
        [self.eventService deleteEvent:event];
        [self.currentEntryList deleteFromList:event];
        [self refreshViewWithNewData];
    }
}

// Confirms the deletion of a recurring event
- (void)actionSheet:(UIActionSheet *)sender clickedButtonAtIndex:(NSInteger)index {
    NPEvent *eventToDelete = nil;
    for (NPEvent *event in self.currentEntryList.entries) {
        if (event.status == ENTRY_STATUS_DELETED) {
            eventToDelete = event;
            break;
        }
    }
    
    if (eventToDelete != nil) {
        if (index == 0) {                       // Only this event
            eventToDelete.recurUpdateOption = ONE;
        } else if (index == 1) {                // this and future
            eventToDelete.recurUpdateOption = FUTURE;
        } else if (index == 2) {                // all
            eventToDelete.recurUpdateOption = ALL;
        } else {                                // Cancel
            [sender dismissWithClickedButtonIndex:index animated:YES];
            return;
        }
        
        [self.eventService deleteEvent:eventToDelete];
        
        // For a recurring event, the handling the refresh entries is in service result delegate call.
        // Here we just make some temp effect
        eventToDelete.status = ENTRY_STATUS_DELETED;
        [self.currentEntryList deleteFromList:eventToDelete];
        [self refreshViewWithNewData];
    }
}


// Just refresh the view with self.currentEntryList.
- (void)refreshViewWithNewData {
    if (self.viewType == DayView) {
        [self.dayViewHelper refreshView:_selectedDate inFolder:self.currentFolder withEntryList:self.currentEntryList];

    } else if (self.viewType == MonthView) {
        [self.monthViewHelper clearMonthViewData];

    } else if (self.viewType == AgendaView) {
        [self.agendaViewHelper refreshView:self.currentFolder startDate:self.startDate endDate:self.endDate withEntryList:self.currentEntryList];
    }
}



#pragma mark - view calls

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;

    // Add navigation bar right button
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [self retrieveSharersList];
    }

    self.eventService = [[EventService alloc] init];
    self.eventService.serviceDelegate = self;
    self.eventService.accessInfo = [self.currentFolder.accessInfo copy];
    
    if (_selectedDate == nil) {
        _selectedDate = [[NSDate alloc] init];
    }
    
    if (self.startDate == nil || self.endDate == nil) {
        [self getDetaultDateRange];
    }
    
    // Initialize segmentation control
    self.viewSegments = [[UISegmentedControl alloc] initWithItems:@[NSLocalizedString(@"Day",),
                                                                    NSLocalizedString(@"Month",),
                                                                    NSLocalizedString(@"Agenda",)]];
    [self.viewSegments addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents: UIControlEventValueChanged];

    UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:self.viewSegments];
    [self.toolbarItemsLoadedInStoryboard setObject:segmentItem forKey:TOOLBAR_ITEM_VIEW_SWITCHER];
    
    // Initialize entry list service
    self.entryListService = [[EntryListService alloc] init];
    self.entryListService.serviceDelegate = self;
    
    // Add the observer to handle entry update and deletion.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryListUpdatedNotification:) name:N_ENTRY_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryDeletedNotification:) name:N_ENTRY_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEntryMovedNotification:) name:N_ENTRY_MOVED object:nil];
    
    [self initCalendarViews:YES];
    
    [self retrieveEntryList];
}

- (void)handleEntryMovedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPEntry class]]) {
        
        NPEntry *movedEntry = (NPEntry*)notification.object;
        
        if (movedEntry.folder.moduleId == self.currentFolder.moduleId) {
            DLog(@"CalendarViewController received notification for module %i moved entry %@ ", movedEntry.folder.moduleId, movedEntry.entryId);
            [self.currentEntryList updateEntryInList:movedEntry];
        }
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:N_ENTRY_MOVED object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;

    if (self.viewType == DayView) {
        self.viewSegments.selectedSegmentIndex = 0;
    } else if (self.viewType == MonthView) {
        self.viewSegments.selectedSegmentIndex = 1;
    } else if (self.viewType == AgendaView) {
        self.viewSegments.selectedSegmentIndex = 2;
    }


    // Check if the lastAccessTime is too old, and the day view should be reloaded with today's info.
    BOOL tooOldNeedsRefresh = NO;
    if (self.lastAccessTime != nil) {
        NSDate *now = [[NSDate alloc] init];
        NSTimeInterval timeInterval = [now timeIntervalSinceDate:self.lastAccessTime];
        NSInteger hoursBetweenDates = timeInterval/3600;
        
        if (hoursBetweenDates > 4) {
            tooOldNeedsRefresh = YES;

            // Reset the viewing dates
            _selectedDate = now;
            [self getDetaultDateRange];
            
            // For day view, we need to clear all daily views previously created.
            if (self.dayViewHelper != nil) {
                [self.dayViewHelper.dayScrollView removeFromSuperview];
                [self.dayViewHelper clearDataAndRefreshDayView:_selectedDate inFolder:self.currentFolder];
                
                // Only add subview when the current displayed view matches.
                if (self.viewType == DayView) {
                    [self.view addSubview:self.dayViewHelper.dayScrollView];
                }
            }
        }
    }
    
    [self setViewTitle];

    if (tooOldNeedsRefresh || self.currentEntryList == nil) {
        [self retrieveEntryList];
    }
}

// ------------------------------------------------------------------------------------------------
// Init all calendar views.
//
// refreshAll decides whether to remove existing view helper and create new ones.
// It is only used when screen is rotated.
// ------------------------------------------------------------------------------------------------
- (void)initCalendarViews:(BOOL)refreshAll {
    if (refreshAll) {
        if (self.dayViewHelper != nil) {
            [self.dayViewHelper.dayScrollView removeFromSuperview];
            self.dayViewHelper = nil;
        }
        if (self.agendaViewHelper != nil) {
            [self.agendaViewHelper.agendaTableView removeFromSuperview];
            self.agendaViewHelper = nil;
            self.listSearchDisplayController = nil;
        }
        if (self.monthViewHelper != nil) {
            [self.monthViewHelper.monthView removeFromSuperview];
            [self.monthViewHelper cleanup];
            self.monthViewHelper = nil;
        }
    }

    CGRect rect;
    
    if (self.viewType == DayView) {
        // Initialize the day view
        self.dayViewHelper = [[DayViewHelper alloc] initWithDate:_selectedDate];
        self.dayViewHelper.controllerDelegate = self;
        
        [self.view addSubview:self.dayViewHelper.dayScrollView];
    }
    
    else if (self.viewType == MonthView) {
//        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
//            rect = [ViewDisplayHelper contentViewRect:(64.0 - 20.0) heightAdjustment:20.0];
//        } else {
//            rect = [ViewDisplayHelper contentViewRect:(52.0 - 10.0) heightAdjustment:10.0];
//        }
        
        rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
        
        self.monthViewHelper = [[MonthViewHelper alloc] initWithFrame:rect parentView:self.view];
        self.monthViewHelper.controllerDelegate = self;
        
        [self.view addSubview:self.monthViewHelper.monthView];
        [self.monthViewHelper.monthView scrollToDate:[NSDate date] animated:NO];
    }
    
    else if (self.viewType == AgendaView) {
        // Initialize the agenda view

        self.agendaViewHelper = [[AgendaViewHelper alloc] initWithFrame:rect];
        self.agendaViewHelper.controllerDelegate = self;
        rect = self.agendaViewHelper.agendaTableView.frame;
        
//        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
//            rect = [ViewDisplayHelper contentViewRect:64.0 heightAdjustment:0.0];
//        } else {
//            rect = [ViewDisplayHelper contentViewRect:52.0 heightAdjustment:0.0];
//        }
        
        rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
        
        self.agendaViewHelper.agendaTableView.frame = rect;
        
        [self.view addSubview:self.agendaViewHelper.agendaTableView];
        
        // Initialize search display controller
        if (self.listSearchDisplayController == nil) {
            self.listSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.agendaViewHelper.searchBar contentsController:self];
            self.agendaViewHelper.searchBar.delegate = self;
            self.listSearchDisplayController.searchResultsDelegate = self;
            self.listSearchDisplayController.searchResultsDataSource = self;
            self.listSearchDisplayController.searchResultsTableView.delegate = self;
        }

    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Use lastAccessTime to keep track of the last time when the journal is in view.
    self.lastAccessTime = [[NSDate alloc] init];
}


- (void)viewDidUnload {
    [self.monthViewHelper cleanup];
    self.monthViewHelper = nil;
    self.dayViewHelper = nil;
    self.agendaViewHelper = nil;
    [super viewDidUnload];
}


- (BOOL)didRotate:(NSNotification *)notification {
    if ([super didRotate:notification]) {
        if (self.dateSelector != nil || self.drsvc != nil) {
            [self dismissSemiModalView];            // Clear any date/range selector.
        }

        [self clearDayViewScreen];
        [self initCalendarViews:YES];
        [self retrieveEntryList];
        return YES;
    }
    
    return NO;
}


/* ------------------------------------------------------------------------------------------------
 * Day view
 * ------------------------------------------------------------------------------------------------
 */

#pragma mark - date selector delegate

- (void)inputValueSelectorCancelled {
    self.navigationController.toolbarHidden = NO;
}

// Delegate for date selector.
- (void)didSelectedDate:(NSString*)ymd {
    self.navigationController.toolbarHidden = NO;
    
    [self dismissSemiModalView];
    self.dateSelector = nil;

    _selectedDate = [DateUtil parseFromYYYYMMDD:ymd];
    
    // Create some animation
    UIView *currentDayView = self.dayViewHelper.dayScrollView;
    [UIView transitionWithView:currentDayView duration:0.5 options:UIViewAnimationOptionTransitionCurlUp animations:^{
        currentDayView.alpha = 0;
        
    } completion:^(BOOL finished) {
        [currentDayView removeFromSuperview];
        
        self.dayViewHelper = [[DayViewHelper alloc] initWithDate:_selectedDate];
        self.dayViewHelper.controllerDelegate = self;
        [self.view addSubview:self.dayViewHelper.dayScrollView];
        
        
        [self retrieveEntryList];
    }];
}

- (void)clearDayViewScreen {
//    [self.dateSelector slideOff];
//    self.navigationController.toolbarHidden = NO;
}

/* ------------------------------------------------------------------------------------------------
 * Month view
 * ------------------------------------------------------------------------------------------------
 */


/* ------------------------------------------------------------------------------------------------
 * Agenda view
 * ------------------------------------------------------------------------------------------------
 */

#pragma mark - date range selector delegate

- (void)dateRangeSelected:(NSDate*)startDate endDate:(NSDate*)endDate {
    [self dismissSemiModalView];
    
    self.drsvc = nil;

    self.startDate = startDate;
    self.endDate = endDate;
    
    [UserPrefUtil setWeekRange:[[NSDate alloc] init] fromDate:self.startDate toDate:self.endDate];    
    [self retrieveEntryList];
}

- (void)getDetaultDateRange {
    NSArray *weekRange = [UserPrefUtil getWeekRange];
    
    if (weekRange != nil) {
        DLog(@"Stored week range: %@ - %@", [weekRange objectAtIndex:0], [weekRange objectAtIndex:1]);
        NSInteger weeksBackward = [[weekRange objectAtIndex:0] integerValue];
        NSInteger weeksForward = [[weekRange objectAtIndex:1] integerValue];
        
        if (weeksForward == 0) {
            weeksForward = weeksForward + 4;
        }
        
        NSDate *today = [[NSDate alloc] init];
        
        NSDate *date1 = [DateUtil addWeeks:today weeks:-weeksBackward];
        NSDate *date2 = [DateUtil addWeeks:today weeks:weeksForward];
        
        self.startDate = [DateUtil getFirstDayOfWeek:date1];
        self.endDate = [DateUtil getLastDayOfWeek:date2];
        
    } else {
        NSArray* dates = [DateUtil findMonthStartEndDate:[NSDate date]];
        self.startDate = [dates objectAtIndex:0];
        self.endDate = [dates objectAtIndex:1];
    }
}


/* ------------------------------------------------------------------------------------------------
 * Search result display controller tableview
 * ------------------------------------------------------------------------------------------------
 */

#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    [self.entryListService searchEntries:searchBar.text templateId:event inFolder:self.currentFolder pageId:1 countPerPage:0];
}


#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.searchResultList.entries.count > 0) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResultList.entries.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    return 55.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchResultList.entries.count - 1 < indexPath.row) {
        return nil;
    }
    NPEvent *evt = [NPEvent eventFromEntry:[self.searchResultList.entries objectAtIndex:indexPath.row]];
    
    static NSString *CellIdentifier = @"EventListCell";
    EventListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[EventListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell showEvent:evt];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NPEvent *e = [self.searchResultList.entries objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"OpenEvent" sender:e];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)refreshSearchResultTable {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedEvents = [self.searchResultList.entries sortedArrayUsingDescriptors:sortDescriptors];
    self.searchResultList.entries = [NSMutableArray arrayWithArray:sortedEvents];
    
    [self unDimSearchTable];

    [self.listSearchDisplayController.searchResultsTableView reloadData];
}


#pragma mark - memory warning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (self.viewType != DayView && self.dayViewHelper != nil) {
        DLog(@"Remove day view...");
        [self.dayViewHelper.dayScrollView removeFromSuperview];
        self.dayViewHelper = nil;
    }

    if (self.viewType != MonthView && self.monthViewHelper != nil) {
        DLog(@"Remove month view...");
        [self.monthViewHelper cleanup];
        self.monthViewHelper = nil;
    }
    
    if (self.viewType != AgendaView && self.agendaViewHelper != nil) {
        DLog(@"Remove agenda view...");
        [self.agendaViewHelper.agendaTableView removeFromSuperview];
        self.agendaViewHelper = nil;
        self.listSearchDisplayController = nil;
    }
    
    self.childCalendarViewController = nil;
}


// Locally implemented and called in BaseEntryListViewController:viewWillAppear
- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (self.currentFolder.folderId == ROOT_FOLDER) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
        [items addObject:[UIBarButtonItem spacer]];
        
        if ([self.currentFolder.accessInfo iAmOwner]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        } else {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_UNSHARE]];
        }
        
    } else {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_FOLDER_PICKER]];
        [items addObject:[UIBarButtonItem spacer]];
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_VIEW_SWITCHER]];
        [items addObject:[UIBarButtonItem spacer]];
        if ([self.currentFolder.accessInfo iCanWrite]) {
            [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:TOOLBAR_ITEM_ADD]];
        }
    }
    
    self.toolbarItems = items;
}


#pragma mark - handle the notifications

- (void)handleEntryListUpdatedNotification:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NPEvent class]]) {
        DLog(@"Received notification on updated event: %@", (NPEvent*)notification.object);
        
        // Retrieve the list from server if this is update on a recurring event because multiple instances
        // can be afftected.
        
        [self retrieveEntryList];
    }
}

// Event deleted from the detail screen
- (void)handleEntryDeletedNotification:(NSNotification*)notification {
    DLog(@"CalendarViewController received notification for module %i deleted entry...", self.currentFolder.moduleId);
    
    if ([notification.object isKindOfClass:[NPEvent class]]) {
        
        NPEvent *deletedEvent = (NPEvent*)notification.object;
        
        DLog(@"Handle notification on deleted entry: %@", deletedEvent);
        
        if (deletedEvent.folder.moduleId != self.currentFolder.moduleId) {                 // Make sure I'm the right notification receiver.
            return;
        }
        
        if (self.viewType == MonthView) {
            // For month view, request the helper to refresh
            [self.monthViewHelper clearMonthViewData];

        } else {
            [self retrieveEntryList];
        }
    }
}

@end
