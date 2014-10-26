//
//  InputMonthSelector.m
//  nexuspad
//
//  Created by Ren Liu on 8/13/12.
//
//

#import "InputMonthSelector.h"
#import "ViewDisplayHelper.h"

static float selectorHeight = 304.0f;

@interface InputMonthSelector()
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *monthPicker;
@property (nonatomic, strong) NSMutableArray *years;
@property (nonatomic, strong) NSMutableArray *months;
@property NSInteger selectedYear;
@property NSInteger selectedMonth;
@end

@implementation InputMonthSelector

@synthesize delegate;

- (id)initWithToolBar:(UIView*)parentView preselectYear:(int)preselectYear preselectMonth:(int)preselectMonth;
{
    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper offsetYPosition], [ViewDisplayHelper screenWidth], selectorHeight);
    self = [self init];
    [self setFrame:offScreen];
    
    // Create a tool bar on top
    self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.0, 0.0, [ViewDisplayHelper screenWidth], 44.0)];

    [self.toolbar setBarStyle:UIBarStyleDefault];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
                                                                                  target: self
                                                                                  action: @selector(cancel)];
    
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                                           target: nil
                                                                           action: nil];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select",)
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(done)];

        
    NSMutableArray* toolbarItems = [NSMutableArray array];
    [toolbarItems addObject:cancelButton];
    [toolbarItems addObject:space];
    [toolbarItems addObject:doneButton];

    self.toolbar.items = toolbarItems;
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:self.toolbar];
    
    [self initPickerSource];
    
    self.monthPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 44.0f, [ViewDisplayHelper screenWidth], 260.0f)];
    self.monthPicker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.monthPicker.showsSelectionIndicator = YES;
    self.monthPicker.delegate = self;
    
    self.monthPicker.backgroundColor = [UIColor whiteColor];

    [self addSubview:self.monthPicker];
    
    self.selectedYear = preselectYear;
    self.selectedMonth = preselectMonth;

    [self slideIn:parentView];
    
    return self;
}

- (void)cancel
{
    [self slideOff];
    if ([self.delegate respondsToSelector:@selector(inputMonthSelectorCancelled)]) {
        [self.delegate inputMonthSelectorCancelled];
    }
}

- (void)done
{
    NSString *ym = [NSString stringWithFormat:@"%li%02li", (long)self.selectedYear, (long)self.selectedMonth];
    [self.delegate didSelectMonth:ym];
    [self slideOff];
}

- (void)slideOff
{
    self.isVisible = NO;
    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper offsetYPosition], [ViewDisplayHelper screenWidth], selectorHeight);
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.4];
    [self setFrame:offScreen];
    [UIView commitAnimations];
}

- (void)slideIn:(UIView*)parentView
{
    [self.monthPicker reloadAllComponents];
    if (self.selectedYear != 0 && self.selectedMonth > 0 && self.selectedMonth <= 12) {
        int row = 0;
        for (NSString *year in self.years) {
            if ([year intValue] == self.selectedYear) {
                [self.monthPicker selectRow:row inComponent:0 animated:NO];
            }
            row++;
        }
        [self.monthPicker selectRow:self.selectedMonth-1 inComponent:1 animated:NO];
    }
    
    self.isVisible = YES;
    [UIView beginAnimations:@"animatePickerView" context:nil];
    [UIView setAnimationDuration:0.5];
    
    float yPos = parentView.frame.size.height - selectorHeight + 44.0f;     // 44 is added to cover the toolbar
    [self setFrame:CGRectMake(0.0f, yPos, [ViewDisplayHelper screenWidth], selectorHeight)];
    
    [parentView bringSubviewToFront:self];

    [UIView commitAnimations];
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return [self.years objectAtIndex:row];
    } else if (component == 1) {
        return [self.months objectAtIndex:row];
    }
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (component == 0) {
        self.selectedYear = [[self.years objectAtIndex:row] intValue];
    } else if (component == 1) {
        self.selectedMonth = row + 1;
    }
}


#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return [self.years count];
    } else if (component == 1) {
        return [self.months count];
    }
    return 0;
}

- (void)initPickerSource
{
    self.years = [[NSMutableArray alloc] initWithCapacity:10];
    for (int i=2010; i<2020; i++) {
        [self.years addObject:[NSString stringWithFormat:@"%i", i]];
    }
    
    self.months = [[NSMutableArray alloc] initWithCapacity:12];
    [self.months addObject:NSLocalizedString(@"January",)];
    [self.months addObject:NSLocalizedString(@"February",)];
    [self.months addObject:NSLocalizedString(@"March",)];
    [self.months addObject:NSLocalizedString(@"April",)];
    [self.months addObject:NSLocalizedString(@"May",)];
    [self.months addObject:NSLocalizedString(@"June",)];
    [self.months addObject:NSLocalizedString(@"July",)];
    [self.months addObject:NSLocalizedString(@"August",)];
    [self.months addObject:NSLocalizedString(@"September",)];
    [self.months addObject:NSLocalizedString(@"October",)];
    [self.months addObject:NSLocalizedString(@"November",)];
    [self.months addObject:NSLocalizedString(@"December",)];
}


@end
