#import "CalendarMonthView.h"
#import "CalendarMonthHeaderCell.h"
#import "CalendarMonthRowCell.h"

#import "DateUtil.h"
#import "NPEvent.h"
#import "UIColor+NPColor.h"

static float LABEL_HEIGHT = 12.0;

@interface CalendarMonthView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *eventColorLabelsByDate;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CalendarMonthHeaderCell *headerView;

@end


@implementation CalendarMonthView

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self addSubview:_tableView];
    
    return self;
}

- (void)dealloc;
{
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

- (NSCalendar *)calendar;
{
    if (!_calendar) {
        self.calendar = [NSCalendar currentCalendar];
    }
    return _calendar;
}

- (Class)headerCellClass;
{
    if (!_headerCellClass) {
        self.headerCellClass = [CalendarMonthHeaderCell class];
    }
    return _headerCellClass;
}

- (Class)rowCellClass;
{
    if (!_rowCellClass) {
        self.rowCellClass = [CalendarMonthRowCell class];
    }
    return _rowCellClass;
}

- (Class)cellClassForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        return [self headerCellClass];
    } else {
        return [self rowCellClass];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor;
{
    [super setBackgroundColor:backgroundColor];
    [self.tableView setBackgroundColor:backgroundColor];
}

- (void)setFirstDate:(NSDate *)firstDate;
{
    // clamp to the beginning of its month
    _firstDate = [self clampDate:firstDate toComponents:NSCalendarUnitMonth|NSCalendarUnitYear];
}

- (void)setLastDate:(NSDate *)lastDate;
{
    // clamp to the end of its month
    NSDate *firstOfMonth = [self clampDate:lastDate toComponents:NSCalendarUnitMonth|NSCalendarUnitYear];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    offsetComponents.month = 1;
    offsetComponents.day = -1;
    _lastDate = [self.calendar dateByAddingComponents:offsetComponents toDate:firstOfMonth options:0];
}

- (void)setSelectedDate:(NSDate *)newSelectedDate;
{    
    // clamp to beginning of its day
    NSDate *startOfDay = [self clampDate:newSelectedDate toComponents:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear];
    
    if ([self.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] &&
        ![self.delegate calendarView:self shouldSelectDate:startOfDay])
    {
        return;
    }

    // Unselect the previous selected button
    [[self cellForRowAtDate:_selectedDate] selectColumnForDate:nil];
    
    // Select a new cell
    [[self cellForRowAtDate:startOfDay] selectColumnForDate:startOfDay];
    
    NSIndexPath *newIndexPath = [self indexPathForRowAtDate:startOfDay];
    CGRect newIndexPathRect = [self.tableView rectForRowAtIndexPath:newIndexPath];
    CGRect scrollBounds = self.tableView.bounds;
    
    if (self.pagingEnabled) {
        CGRect sectionRect = [self.tableView rectForSection:newIndexPath.section];
        [self.tableView setContentOffset:sectionRect.origin animated:YES];

    } else {
        if (CGRectGetMinY(scrollBounds) > CGRectGetMinY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (CGRectGetMaxY(scrollBounds) < CGRectGetMaxY(newIndexPathRect)) {
            [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
    
    _selectedDate = startOfDay;
    
    if ([self.delegate respondsToSelector:@selector(calendarView:didSelectDate:)]) {
        [self.delegate calendarView:self didSelectDate:startOfDay];
    }
}

- (void)clearSelectedDate {
    // Remove the selected date
    [[self cellForRowAtDate:_selectedDate] selectColumnForDate:nil];
    
    _selectedDate = nil;
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated
{
    NSInteger section = [self sectionForDate:date];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
                          atScrollPosition:UITableViewScrollPositionTop animated:animated];
}

- (CalendarMonthHeaderCell *)makeHeaderCellWithIdentifier:(NSString *)identifier;
{
    CalendarMonthHeaderCell *cell = [[[self headerCellClass] alloc] initWithCalendar:self.calendar reuseIdentifier:identifier];
    cell.backgroundColor = [UIColor whiteColor];
    cell.calendarView = self;
    return cell;
}

#pragma mark Calendar calculations

- (NSDate *)firstOfMonthForSection:(NSInteger)section;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.month = section;
    return [self.calendar dateByAddingComponents:offset toDate:self.firstDate options:0];
}

- (CalendarMonthRowCell *)cellForRowAtDate:(NSDate *)date;
{
    return (CalendarMonthRowCell *)[self.tableView cellForRowAtIndexPath:[self indexPathForRowAtDate:date]];
}


- (NSInteger)sectionForDate:(NSDate *)date;
{
  return [self.calendar components:NSCalendarUnitMonth fromDate:self.firstDate toDate:date options:0].month;
}


- (NSIndexPath *)indexPathForRowAtDate:(NSDate *)date {
    if (!date) {
        return nil;
    }
    
    NSInteger section = [self sectionForDate:date];
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];
    
    NSInteger firstWeek = [self.calendar components:NSCalendarUnitWeekOfMonth fromDate:firstOfMonth].weekOfMonth;
    NSInteger targetWeek = [self.calendar components:NSCalendarUnitWeekOfMonth fromDate:date].weekOfMonth;

    return [NSIndexPath indexPathForRow:1 + targetWeek - firstWeek inSection:section];
}


#pragma mark UIView

- (void)layoutSubviews {
    if (self.headerView) {
        [self.headerView removeFromSuperview];
        self.headerView = nil;
    }
    self.tableView.frame = self.bounds;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + [self.calendar components:NSCalendarUnitMonth fromDate:self.firstDate toDate:self.lastDate options:0].month;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:section];
    
    // ios bug. Have to use NSWeekCalendarUnit so it works in ios 7.
    NSRange rangeOfWeeks = [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSCalendarUnitMonth forDate:firstOfMonth];
    
    return rangeOfWeeks.length + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        static NSString *identifier = @"header";
        CalendarMonthHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [self makeHeaderCellWithIdentifier:identifier];
        }
        
        return cell;
        
    } else {
        static NSString *identifier = @"row";
        CalendarMonthRowCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

        if (!cell) {
            cell = [[[self rowCellClass] alloc] initWithCalendar:self.calendar reuseIdentifier:identifier];
            cell.calendarView = self;
        }
        
        if (indexPath.row == 1) {
            /*
             * Try to get the data when the first row of the month is in sight (scroll down).
             */
            NSDate *firstDateOfMonth = [self firstOfMonthForSection:indexPath.section];
            NSString *ym = [DateUtil convertToYYYYMM:firstDateOfMonth];

            [self.delegate doWantToRequestEventDataForMonth:ym];
            
        } else {
            /*
             * Try to get the data when the last row of the month is in sight (scroll up).
             */
            BOOL isBottomRow = (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1);
            if (isBottomRow) {
                NSDate *firstDateOfMonth = [self firstOfMonthForSection:indexPath.section];
                NSString *ym = [DateUtil convertToYYYYMM:firstDateOfMonth];

                [self.delegate doWantToRequestEventDataForMonth:ym];
            }
        }

        return cell;
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDate *firstOfMonth = [self firstOfMonthForSection:indexPath.section];

    [(CalendarMonthBaseCell *)cell setFirstOfMonth:firstOfMonth];
    
    if (indexPath.row > 0) {
        NSInteger ordinalityOfFirstDay = [self.calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitWeekOfMonth forDate:firstOfMonth];
        
        NSDateComponents *dateComponents = [NSDateComponents new];
        dateComponents.day = 1 - ordinalityOfFirstDay;
        dateComponents.weekOfMonth = indexPath.row - 1;
        
        NSDate *rowStartDate = [self.calendar dateByAddingComponents:dateComponents toDate:firstOfMonth options:0];

        [(CalendarMonthRowCell *)cell setupRowForTheWeek:rowStartDate];
        
        [(CalendarMonthRowCell *)cell selectColumnForDate:self.selectedDate];
        
        BOOL isBottomRow = (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1);
        
        [(CalendarMonthRowCell *)cell setBottomRow:isBottomRow];
        
        NSDateFormatter *ymdFormatter = [[NSDateFormatter alloc] init];
        [ymdFormatter setDateFormat:@"yyyyMMdd"];
        NSString *todayYmd = [ymdFormatter stringFromDate:[NSDate date]];
        
        CalendarMonthRowCell *rowCell = (CalendarMonthRowCell *)cell;
        
        for (UIButton *buttonCell in rowCell.dayButtons) {
            [self addEventLabel:buttonCell];
            
            // Decorate the "today" cell
            // There is some duplicate effort here.
            if (buttonCell.tag == [todayYmd intValue]) {
                if ([buttonCell isEnabled]) {
                    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor defaultBlue]};
                    
                    // TODO fix this here.
                    if (buttonCell.titleLabel.text != nil)
                        [buttonCell setAttributedTitle:[[NSAttributedString alloc] initWithString:buttonCell.titleLabel.text attributes:attributes]
                                              forState:UIControlStateNormal];                    
                }
                
            } else {
                // UIColor copied from TSQCalendarCell.m line 44
                [buttonCell setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                [buttonCell setBackgroundColor:[UIColor whiteColor]];
                [buttonCell setAttributedTitle:nil forState:UIControlStateNormal];
            }
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self cellClassForRowAtIndexPath:indexPath] cellHeight];
}


#pragma mark UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.pagingEnabled) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:*targetContentOffset];
        // If the target offset is at the third row or later, target the next month; otherwise, target the beginning of this month.
        NSInteger section = indexPath.section;
        if (indexPath.row > 2) {
            section++;
        }
        CGRect sectionRect = [self.tableView rectForSection:section];
        *targetContentOffset = sectionRect.origin;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.delegate didScrollMonthView];
    [self clearSelectedDate];
}

- (NSDate *)clampDate:(NSDate *)date toComponents:(NSUInteger)unitFlags {
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    return [self.calendar dateFromComponents:components];
}


// Reload the table with fresh data
- (void)refreshCalendarMonthView:(NSDictionary *)eventsArrByMonths {

    for (NSString *ym in eventsArrByMonths) {
        NSArray *events = [eventsArrByMonths objectForKey:ym];
        
        NSDate *fromDate = [DateUtil parseFromYYYYMMDD:[NSString stringWithFormat:@"%@01", ym]];

        // clear the color labels for the month
        for (int i=1; i<=31; i++) {
            NSString *ymd = [NSString stringWithFormat:@"%@%02i", ym, i];
            
            if ([self.eventColorLabelsByDate objectForKey:ymd] != nil) {
                [self.eventColorLabelsByDate removeObjectForKey:ymd];
            }
        }
        
        if (self.eventColorLabelsByDate == nil) {
            self.eventColorLabelsByDate = [[NSMutableDictionary alloc] init];
        }
    
        // Add the events' color labels
        for (NPEvent *event in events) {
            NSString *hexColor = @"#336699";
            if (event.colorLabel != nil) {
                hexColor = [event.colorLabel copy];
            }
            
            NSString *ymd = [DateUtil convertToYYYYMMDD:event.startTime];

            if ([self.eventColorLabelsByDate objectForKey:ymd] == nil) {
                NSMutableArray *colorLabels = [[NSMutableArray alloc] init];
                [colorLabels addObject:hexColor];
                [self.eventColorLabelsByDate setObject:colorLabels forKey:ymd];

            } else {
                NSMutableArray *colorLabels = [self.eventColorLabelsByDate objectForKey:ymd];
                if (![colorLabels containsObject:hexColor]) {
                    [colorLabels addObject:hexColor];
                }
            }
        }
        
        NSIndexPath *indexPath = [self indexPathForRowAtDate:fromDate];
        
        //
        // Only reload the section for the month
        //
        // It's possible that some event has an invalid date which falls out of range, such as 1970-01-01 (nil start time)
        if (indexPath != nil) {
            NSRange range = NSMakeRange(indexPath.section, 1);
            NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
            
            NSLog(@"Refresh month view: %@ with section: %@", ym, section);
            
            // reloadSections causes memory leak
            [self.tableView reloadSections:section withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}


- (void)addEventLabel:(UIButton*)buttonCell {
    // Remove the previoud dots
    // Always need to do this first because some date cells are not for the current month, so
    // when the cells are re-used, the previous dots need to be cleared.
    for (int i=900; i<905; i++) {
        UIView *previousLabel = [buttonCell viewWithTag:i];
        if (previousLabel != nil) {
            [previousLabel removeFromSuperview];
            previousLabel = nil;
        }
    }
    
    if (![buttonCell isEnabled] || buttonCell.tag == 0) {
        return;
    }

    NSMutableArray *colorLabels = [self.eventColorLabelsByDate objectForKey:[NSString stringWithFormat:@"%li", (long)buttonCell.tag]];
    
    if (colorLabels != nil && colorLabels.count > 0) {
        NSInteger labelCount = colorLabels.count;
        
        // Space constraint
        if (labelCount > 4) {
            labelCount = 4;
        }
        
        CGRect r = buttonCell.bounds;
        
        for (int i=0; i<labelCount; i++) {
            float x = r.size.width/labelCount*i;
            float y = r.size.height - LABEL_HEIGHT;
            
            CGRect labelRect = CGRectMake(x, y, floor(r.size.width/labelCount), LABEL_HEIGHT);
            
            UILabel *dot = [[UILabel alloc] initWithFrame:labelRect];
            
            dot.tag = 900 + i;
            
            dot.text = @"•";
            dot.textColor = [UIColor colorFromHexString:[colorLabels objectAtIndex:i]];
            dot.font = [UIFont boldSystemFontOfSize:18.0];
            dot.textAlignment = NSTextAlignmentCenter;

            [buttonCell addSubview:dot];
        }

        r.origin.y += 29;
        r.size.height -= 31;
    }
}

@end
