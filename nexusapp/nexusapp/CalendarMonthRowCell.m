#import "CalendarMonthRowCell.h"
#import "CalendarMonthView.h"
#import "UIColor+NPColor.h"

@interface CalendarMonthRowCell ()

//@property (nonatomic, strong) NSArray *notThisMonthButtons;
@property (nonatomic, strong) UIButton *todayButton;
@property (nonatomic, strong) UIView *selectedOverlay;

@property (nonatomic, assign) NSInteger indexOfTodayButton;
@property (nonatomic, assign) NSInteger indexOfSelectedButton;

@property (nonatomic, strong) NSDateFormatter *dayFormatter;
@property (nonatomic, strong) NSDateFormatter *accessibilityFormatter;

@property (nonatomic, strong) NSDateComponents *todayDateComponents;
@property (nonatomic) NSInteger monthOfBeginningDate;

@end


@implementation CalendarMonthRowCell

- (id)initWithCalendar:(NSCalendar *)calendar reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithCalendar:calendar reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)configureButton:(UIButton *)button;
{
    button.titleLabel.font = [UIFont boldSystemFontOfSize:19.f];
    button.adjustsImageWhenDisabled = NO;
    [button setTitleColor:self.textColor forState:UIControlStateNormal];
}

- (void)createDayButtons;
{
    NSMutableArray *dayButtons = [NSMutableArray arrayWithCapacity:self.daysInWeek];

    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        // np_start the button with was 320. why? change it to 320/7
        CGRect rect = self.contentView.bounds;
        rect.size.width = rect.size.width/7;
        UIButton *button = [[UIButton alloc] initWithFrame:rect];
        button.backgroundColor = [UIColor whiteColor];
        
        [button addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [dayButtons addObject:button];
        [self.contentView addSubview:button];
        [self configureButton:button];
        [button setTitleColor:[self.textColor colorWithAlphaComponent:0.5f] forState:UIControlStateDisabled];
    }
    self.dayButtons = dayButtons;
}

- (void)createTodayButton;
{
    self.todayButton = [[UIButton alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.todayButton];
    [self configureButton:self.todayButton];
    [self.todayButton addTarget:self action:@selector(todayButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [self.todayButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.todayButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f / [UIScreen mainScreen].scale);
}

- (void)createSelectedView;
{
    CGRect rect = self.contentView.bounds;
    self.selectedOverlay = [[UIView alloc] initWithFrame:rect];
    [self.contentView addSubview:self.selectedOverlay];

    [self.selectedOverlay setAccessibilityTraits:UIAccessibilityTraitSelected|self.selectedOverlay.accessibilityTraits];

    self.selectedOverlay.backgroundColor = [UIColor colorFromHexString:@"#99ccff33"];
    
    self.indexOfSelectedButton = -1;
}

- (void)setupRowForTheWeek:(NSDate *)date;
{
    _beginningDate = date;
    
    if (!self.dayButtons) {
        [self createDayButtons];
        [self createSelectedView];
    }

    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;

    self.todayButton.hidden = YES;
    self.indexOfTodayButton = -1;
    self.selectedOverlay.hidden = YES;
    self.indexOfSelectedButton = -1;

    // A formatter to help create the tags
    NSDateFormatter *ymdFormatter = [[NSDateFormatter alloc] init];
    [ymdFormatter setDateFormat:@"yyyyMMdd"];
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSString *title = [self.dayFormatter stringFromDate:date];
        NSString *accessibilityLabel = [self.accessibilityFormatter stringFromDate:date];
        
        [self.dayButtons[index] setTitle:title forState:UIControlStateNormal];
        [self.dayButtons[index] setAccessibilityLabel:accessibilityLabel];
        
        NSDateComponents *thisDateComponents = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:date];

        NSInteger thisDayMonth = thisDateComponents.month;

        /*
         * Do not display the dates from the previous month.
         */
        if (self.monthOfBeginningDate != thisDayMonth) {
            UIButton *button = self.dayButtons[index];
            button.backgroundColor = [UIColor whiteColor];
            [button setTitle:@"" forState:UIControlStateDisabled];
            button.enabled = NO;
            button.tag = 0;
            
        } else {
            UIButton *button = self.dayButtons[index];
            button.enabled = ![self.calendarView.delegate respondsToSelector:@selector(calendarView:shouldSelectDate:)] || [self.calendarView.delegate calendarView:self.calendarView shouldSelectDate:date];
        }
        
        NSString *ymd = [ymdFormatter stringFromDate:date];
        [self.dayButtons[index] setTag:[ymd intValue]];

        date = [self.calendar dateByAddingComponents:offset toDate:date options:0];
    }
}

- (void)setBottomRow:(BOOL)bottomRow;
{
    UIImageView *backgroundImageView = (UIImageView *)self.backgroundView;
    if ([backgroundImageView isKindOfClass:[UIImageView class]] && _bottomRow == bottomRow) {
        return;
    }

    _bottomRow = bottomRow;
    
    self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    
    [self setNeedsLayout];
}

- (void)dateButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = [self.dayButtons indexOfObject:sender];
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    
    self.calendarView.selectedDate = selectedDate;        
}

- (void)todayButtonPressed:(id)sender;
{
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = self.indexOfTodayButton;
    NSDate *selectedDate = [self.calendar dateByAddingComponents:offset toDate:self.beginningDate options:0];
    self.calendarView.selectedDate = selectedDate;
}

- (void)layoutSubviews;
{
    if (!self.backgroundView) {
        [self setBottomRow:NO];
    }
    
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect {
    rect.origin.y += 0.8;
    rect.size.height -= (self.bottomRow ? 2.0f : 1.0f) * 0.8;

    UIButton *dayButton = self.dayButtons[index];
    
    dayButton.frame = rect;

    if (self.indexOfTodayButton == (NSInteger)index) {
        self.todayButton.frame = rect;
    }
    if (self.indexOfSelectedButton == (NSInteger)index) {
        self.selectedOverlay.frame = rect;
    }
}

- (void)selectColumnForDate:(NSDate *)date;
{
    if (!date && self.indexOfSelectedButton == -1) {
        return;
    }

    NSInteger newIndexOfSelectedButton = -1;
    if (date) {
        NSInteger thisDayMonth = [self.calendar components:NSCalendarUnitMonth fromDate:date].month;
        if (self.monthOfBeginningDate == thisDayMonth) {
            newIndexOfSelectedButton = [self.calendar components:NSCalendarUnitDay fromDate:self.beginningDate toDate:date options:0].day;
            if (newIndexOfSelectedButton >= (NSInteger)self.daysInWeek) {
                newIndexOfSelectedButton = -1;
            }
        }
    }

    self.indexOfSelectedButton = newIndexOfSelectedButton;
    
    if (newIndexOfSelectedButton >= 0) {
        self.selectedOverlay.hidden = NO;
// Ren - somehow have to comment this out to fix the number overlay bug.
//        [self.selectedButton setTitle:[self.dayButtons[newIndexOfSelectedButton] currentTitle] forState:UIControlStateNormal];
//        self.selectedButton.titleLabel.backgroundColor = [UIColor clearColor];
        [self.selectedOverlay setAccessibilityLabel:[self.dayButtons[newIndexOfSelectedButton] accessibilityLabel]];
    } else {
        self.selectedOverlay.hidden = YES;
    }
    
    [self setNeedsLayout];
}

- (NSArray*)np_buttonCells {
    return self.dayButtons;
}


- (NSDateFormatter *)dayFormatter;
{
    if (!_dayFormatter) {
        _dayFormatter = [NSDateFormatter new];
        _dayFormatter.calendar = self.calendar;
        _dayFormatter.dateFormat = @"d";
    }
    return _dayFormatter;
}

- (NSDateFormatter *)accessibilityFormatter;
{
    if (!_accessibilityFormatter) {
        _accessibilityFormatter = [NSDateFormatter new];
        _accessibilityFormatter.calendar = self.calendar;
        _accessibilityFormatter.dateStyle = NSDateFormatterLongStyle;
    }
    return _accessibilityFormatter;
}

- (NSInteger)monthOfBeginningDate;
{
    if (!_monthOfBeginningDate) {
        _monthOfBeginningDate = [self.calendar components:NSCalendarUnitMonth fromDate:self.firstOfMonth].month;
    }
    return _monthOfBeginningDate;
}

- (void)setFirstOfMonth:(NSDate *)firstOfMonth;
{
    [super setFirstOfMonth:firstOfMonth];
    self.monthOfBeginningDate = 0;
}

- (NSDateComponents *)todayDateComponents;
{
    if (!_todayDateComponents) {
        self.todayDateComponents = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];
    }
    return _todayDateComponents;
}


- (NSDate *)clampDate:(NSDate *)date toComponents:(NSUInteger)unitFlags
{
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    return [self.calendar dateFromComponents:components];
}

@end
