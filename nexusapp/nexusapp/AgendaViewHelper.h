//
//  AgendaViewPresenter.h
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import <Foundation/Foundation.h>
#import "EntryList.h"
#import "CalendarViewPresenterDelegate.h"

@interface AgendaViewHelper : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<CalendarViewPresenterDelegate> controllerDelegate;

@property (nonatomic, strong) UITableView *agendaTableView;
@property (nonatomic, strong) UISearchBar *searchBar;

- (id)initWithFrame:(CGRect)frame;

@property (nonatomic, strong) NPFolder *folder;

- (void)refreshView:(NPFolder*)inFolder startDate:(NSDate*)startDate endDate:(NSDate*)endDate withEntryList:(EntryList*)withEntryList;

@end
