#import "CalendarMonthHeaderCell.h"

static const CGFloat TSQCalendarMonthHeaderCellMonthsHeight = 20.f;
static NSDateFormatter *dayFormatter;

@interface CalendarMonthHeaderCell ()

@property (nonatomic, strong) NSDateFormatter *monthDateFormatter;

@end


@implementation CalendarMonthHeaderCell

- (id)initWithCalendar:(NSCalendar *)calendar reuseIdentifier:(NSString *)reuseIdentifier;
{
    self = [super initWithCalendar:calendar reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    [self createHeaderLabels];
    
    return self;
}


+ (CGFloat)cellHeight;
{
    return 65.0f;
}

- (NSDateFormatter *)monthDateFormatter;
{
    if (!_monthDateFormatter) {
        _monthDateFormatter = [NSDateFormatter new];
        _monthDateFormatter.calendar = self.calendar;
        
        NSString *dateComponents = @"yyyyLLLL";
        _monthDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
    }
    return _monthDateFormatter;
}

- (void)createHeaderLabels;
{
    NSDate *referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = 1;
    NSMutableArray *headerLabels = [NSMutableArray arrayWithCapacity:self.daysInWeek];
    
    if (dayFormatter == nil) {
        dayFormatter = [[NSDateFormatter alloc] init];
    }

    dayFormatter.calendar = self.calendar;
    dayFormatter.dateFormat = @"cccccc";
    
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        [headerLabels addObject:@""];
    }
    
    // Weekday name labels
    for (NSUInteger index = 0; index < self.daysInWeek; index++) {
        NSInteger ordinality = [self.calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitWeekOfMonth forDate:referenceDate];
        
        UILabel *label = [[UILabel alloc] initWithFrame:self.frame];
        
        label.textAlignment = NSTextAlignmentCenter;
        label.text = [dayFormatter stringFromDate:referenceDate];
        label.font = [UIFont boldSystemFontOfSize:12.f];
        label.backgroundColor = [UIColor whiteColor];
        
        label.textColor = [UIColor grayColor];
        [label sizeToFit];
        headerLabels[ordinality - 1] = label;
        [self.contentView addSubview:label];
        
        referenceDate = [self.calendar dateByAddingComponents:offset toDate:referenceDate options:0];
    }
    
    // Month Year label
    self.headerLabels = headerLabels;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.textColor = [UIColor darkGrayColor];
}

- (void)layoutSubviews;
{
    [super layoutSubviews];

    CGRect bounds = self.contentView.bounds;
    bounds.size.height -= TSQCalendarMonthHeaderCellMonthsHeight;
    self.textLabel.frame = CGRectOffset(bounds, 0.0f, 5.0f);
}

- (void)layoutViewsForColumnAtIndex:(NSUInteger)index inRect:(CGRect)rect;
{
    UILabel *label = self.headerLabels[index];
    CGRect labelFrame = rect;
    labelFrame.size.height = TSQCalendarMonthHeaderCellMonthsHeight;
    labelFrame.origin.y = self.bounds.size.height - TSQCalendarMonthHeaderCellMonthsHeight;
    label.frame = labelFrame;
}

- (void)setFirstOfMonth:(NSDate *)firstOfMonth;
{
    [super setFirstOfMonth:firstOfMonth];
    self.textLabel.text = [self.monthDateFormatter stringFromDate:firstOfMonth];
    self.accessibilityLabel = self.textLabel.text;
}

@end
