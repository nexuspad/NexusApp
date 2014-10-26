//
//  InputWeekSelector.m
//  nexuspad
//
//  Created by Ren Liu on 8/14/12.
//
//

#import "InputWeekSelector.h"
#import "DateUtil.h"
#import "ViewDisplayHelper.h"

@interface InputWeekSelector()
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *weekPicker;
@property (nonatomic, strong) NSMutableArray *weeks;
@property (nonatomic, strong) NSDate *weekStartDate;
@property (nonatomic, strong) NSDate *weekEndDate;
@end

@implementation InputWeekSelector

@synthesize weekPicker, weeks;
@synthesize weekStartDate = _weekStartDate, weekEndDate = _weekEndDate;
@synthesize delegate;


- (id)initWithToolBar:(UIView*)parentView startDate:(NSDate*)startDate endDate:(NSDate*)endDate {
    
    self = [super init];

    if (startDate != nil && endDate != nil) {
        _weekStartDate = startDate;
        _weekEndDate = endDate;
    } else {
        NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        _weekStartDate = [DateUtil getFirstDayOfWeek:[NSDate date]];
        NSDateComponents *componentsForAdd6Days = [[NSDateComponents alloc] init];
        [componentsForAdd6Days setDay:6];
        _weekEndDate = [cal dateByAddingComponents:componentsForAdd6Days toDate:_weekStartDate options:0];
    }

    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper offsetYPosition], [ViewDisplayHelper screenWidth], 304.0f);
    self = [self init];
    [self setFrame:offScreen];
    
    // Create a tool bar on top
    self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.0, 0.0, [ViewDisplayHelper screenWidth], 44.0)];

    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                  target: self
                                                                                  action: @selector(cancel)];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                           target: nil
                                                                           action: nil];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                target: self
                                                                                action: @selector(done)];
    
    NSMutableArray* toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:cancelButton];
    [toolbarItems addObject:space];
    [toolbarItems addObject:doneButton];
    self.toolbar.items = toolbarItems;
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:self.toolbar];
    
    [self initPickerSource];
    self.weekPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 44.0f, [ViewDisplayHelper screenWidth], 260.0f)];
    self.weekPicker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.weekPicker.showsSelectionIndicator = YES;
    self.weekPicker.delegate = self;
    
    self.weekPicker.backgroundColor = [UIColor whiteColor];

    [self addSubview:self.weekPicker];
    
    [self slideIn:parentView];
    
    return self;
}

- (void)cancel
{
    [self slideOff];
    if ([self.delegate respondsToSelector:@selector(inputWeekSelectorCancelled)]) {
        [self.delegate inputWeekSelectorCancelled];
    }
}

- (void)done
{
    [self.delegate didSelectWeek:[NSArray arrayWithObjects:self.weekStartDate, self.weekEndDate, nil]];
    [self slideOff];
}

- (void)slideOff
{
    self.isVisible = NO;
    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper offsetYPosition], [ViewDisplayHelper screenWidth], 304.0f);
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.4];
    [self setFrame:offScreen];
    [UIView commitAnimations];
}

- (void)slideIn:(UIView*)parentView
{
    [self.weekPicker reloadAllComponents];
    [self.weekPicker selectRow:8 inComponent:0 animated:YES];
    
    self.isVisible = YES;
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.4];
    float yPos = parentView.frame.size.height - 304.0f + 44.0f;     // 44 is added to cover the toolbar
    [self setFrame:CGRectMake(0.0f, yPos, [ViewDisplayHelper screenWidth], 304.0f)];
    [UIView commitAnimations];
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray *week = [self.weeks objectAtIndex:row];
    NSDate *date1 = [week objectAtIndex:0];
    NSDate *date2 = [week objectAtIndex:1];
    
    return [NSString stringWithFormat:@"%@ - %@", [DateUtil displayDate:date1], [DateUtil displayDate:date2]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSArray *week = [self.weeks objectAtIndex:row];
    self.weekStartDate = [week objectAtIndex:0];
    self.weekEndDate = [week objectAtIndex:1];
}


#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.weeks count];
}

- (void)initPickerSource
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    NSDateComponents *componentsForReduceOneWeek = [[NSDateComponents alloc] init];
    [componentsForReduceOneWeek setWeekOfMonth:-1];
  
    NSDateComponents *componentsForAddOneWeek = [[NSDateComponents alloc] init];
    [componentsForAddOneWeek setWeekOfMonth:1];
    
    NSDateComponents *componentsForAdd6Days = [[NSDateComponents alloc] init];
    [componentsForAdd6Days setDay:6];
    
    self.weeks = [[NSMutableArray alloc] initWithCapacity:17];
    
    NSDate *currentWeekStart = self.weekStartDate;
    NSDate *currentWeekEnd = self.weekEndDate;
    NSArray *currentWeek = [NSArray arrayWithObjects:currentWeekStart, currentWeekEnd, nil];
    
    NSDate *weekStart = [currentWeek objectAtIndex:0];
    NSMutableArray *previousWeeks = [[NSMutableArray alloc] initWithCapacity:8];
    for (int i=0; i<8; i++) {
        NSDate *newWeekStart = [cal dateByAddingComponents:componentsForReduceOneWeek toDate:weekStart options:0];
        NSDate *newWeekEnd = [cal dateByAddingComponents:componentsForAdd6Days toDate:newWeekStart options:0];
        [previousWeeks addObject:[NSArray arrayWithObjects:newWeekStart, newWeekEnd, nil]];
        weekStart = newWeekStart;
    }

    NSEnumerator *enumerator = [previousWeeks reverseObjectEnumerator];
    for (id element in enumerator) {
        [self.weeks addObject:element];
    }
    
    [self.weeks addObject:currentWeek];

    weekStart = [currentWeek objectAtIndex:0];
    for (int i=0; i<8; i++) {
        NSDate *newWeekStart = [cal dateByAddingComponents:componentsForAddOneWeek toDate:weekStart options:0];
        NSDate *newWeekEnd = [cal dateByAddingComponents:componentsForAdd6Days toDate:newWeekStart options:0];
        [self.weeks addObject:[NSArray arrayWithObjects:newWeekStart, newWeekEnd, nil]];
        weekStart = newWeekStart;
    }
}

@end
