//
//  DateRangeSelectorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DateRangeSelectorViewController.h"
#import "ViewDisplayHelper.h"
#import "DateUtil.h"
#import "UIColor+NPColor.h"

typedef enum{none, selectmonth, selectweek, selectdates} SelectionType;

@interface DateRangeSelectorViewController ()
@property (strong, nonatomic) IBOutlet UITableViewCell *selectMonthWeekCell;
@property (strong, nonatomic) IBOutlet KHFlatButton *selectMonthButton;
@property (strong, nonatomic) IBOutlet KHFlatButton *selectWeeksButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *dateRangeCell;
@property (strong, nonatomic) IBOutlet KHFlatButton *doneButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *doneCell;
@property (strong, nonatomic) IBOutlet UITextField *startDateTextField;
@property (strong, nonatomic) IBOutlet UITextField *endDateTextField;
@property (nonatomic, strong) InputMonthSelector *monthSelector;
@property (nonatomic, strong) InputWeekSelector *weekSelector;
@property (nonatomic, strong) InputDateSelectorView *dateSelector;
@end

@implementation DateRangeSelectorViewController

@synthesize weekSelector, monthSelector, dateSelector;

@synthesize startDate = _startDate, endDate = _endDate, delegate;

- (id)init {
    self = [super init];
    return self;
}

- (void)setStartEndDates:(NSDate*)startDate endDate:(NSDate*)endDate
{
    _startDate = startDate;
    _endDate = endDate;
}

- (IBAction)selectMonthButtonTapped:(id)sender {
    if (self.monthSelector != nil) {
        [self.monthSelector slideIn:self.view];
    } else {
        NSArray *ymd = [DateUtil getYmd:[NSDate date]];
        self.monthSelector = [[InputMonthSelector alloc] initWithToolBar:self.view
                                                           preselectYear:[[ymd objectAtIndex:0] intValue]
                                                          preselectMonth:[[ymd objectAtIndex:1] intValue]];
        self.monthSelector.delegate = self;
        [self.view addSubview:self.monthSelector];
    }
}

- (IBAction)selectWeekButtonTapped:(id)sender {
    if (self.weekSelector != nil) {
        [self.weekSelector slideIn:self.view];
        
    } else {
        self.weekSelector = [[InputWeekSelector alloc] initWithToolBar:self.view
                                                             startDate:nil
                                                               endDate:nil];
        self.weekSelector.delegate = self;
        [self.view addSubview:self.weekSelector];
    }
}

- (IBAction)doneButtonTapped:(id)sender {
    if ([self.startDate compare:self.endDate] == NSOrderedDescending) {
        [self.delegate dateRangeSelected:self.startDate endDate:self.startDate];
    } else {
        [self.delegate dateRangeSelected:self.startDate endDate:self.endDate];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 2;
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"SELECT DATE RANGE",);
    }
    
    return @"";
}

#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            self.startDateTextField.text = [DateUtil displayDate:self.startDate];
            self.endDateTextField.text = [DateUtil displayDate:self.endDate];            
            return self.dateRangeCell;

        } else if (indexPath.row == 1) {
            return self.selectMonthWeekCell;
        }

    } else if (indexPath.section == 1) {
        return self.doneCell;
    }
    
    return nil;
}


- (void)didSelectMonth:(id)value {
    NSString *ym = (NSString*)value;

    NSRange range = NSMakeRange(0, 4);
    int year = [[ym substringWithRange:range] intValue];
    range = NSMakeRange(4, 2);
    int month = [[ym substringWithRange:range] intValue];
    
    NSArray *dates = [DateUtil findMonthStartEndDate:year month:month];
    self.startDate = [dates objectAtIndex:0];
    self.endDate = [dates objectAtIndex:1];
    
    self.startDateTextField.text = [DateUtil displayDate:self.startDate];
    self.endDateTextField.text = [DateUtil displayDate:self.endDate];
}


- (void)didSelectWeek:(id)value {
    NSArray *weekDays = (NSArray*)value;
    self.startDate = [weekDays objectAtIndex:0];
    self.endDate = [weekDays objectAtIndex:1];
    
    self.startDateTextField.text = [DateUtil displayDate:self.startDate];
    self.endDateTextField.text = [DateUtil displayDate:self.endDate];
}


- (void)didSelectedDate:(id)sender {
    NSString *value = (NSString*)sender;

    if ([self.startDateTextField isFirstResponder]) {
        NSDate *selectedDate = [DateUtil parseFromYYYYMMDD:value];
        self.startDate = selectedDate;
        self.startDateTextField.text = [DateUtil displayDate:selectedDate];
        [self.endDateTextField becomeFirstResponder];
        
    } else if ([self.endDateTextField isFirstResponder]) {
        NSDate *selectedDate = [DateUtil parseFromYYYYMMDD:value];
        self.endDate = selectedDate;
        self.endDateTextField.text = [DateUtil displayDate:selectedDate];
    }
    
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.monthSelector slideOff];
    [self.weekSelector slideOff];
    
    return YES;
}

#pragma mark - Table view delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    if (self.dateSelector == nil) {
        self.dateSelector = [[InputDateSelectorView alloc] initWithToolBar:self.view asInputView:YES];
        self.dateSelector.delegate = self;
    }
    self.startDateTextField.inputView = self.dateSelector;
    self.startDateTextField.delegate = self;
    self.endDateTextField.inputView = self.dateSelector;
    self.endDateTextField.delegate = self;
    
    // This has to be specifically set. Probably due to the way view controller is initialized in CalendarEventController (instantiateViewControllerWithIdentifier)
    self.doneButton.layer.cornerRadius = 3.0;
    
    self.selectMonthButton.layer.cornerRadius = 3.0;
    self.selectWeeksButton.layer.cornerRadius = 3.0;
}

- (void)viewDidUnload
{
    [self setSelectMonthWeekCell:nil];
    [self setStartDateTextField:nil];
    [self setEndDateTextField:nil];
    [self setDateRangeCell:nil];
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.dateSelector.isVisible) {
        [self.dateSelector slideOff];
        [self.dateSelector slideIn];
    }
    
    if (self.monthSelector.isVisible) {
        [self.monthSelector slideOff];
        [self.monthSelector slideIn:self.view];
    }
    
    if (self.weekSelector.isVisible) {
        [self.weekSelector slideOff];
        [self.weekSelector slideIn:self.view];
    }
}

- (IBAction)cancelSelector:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)finishSelectingDateRange:(id)sender
{
    if ([self.startDate compare:self.endDate] == NSOrderedDescending) {
        [self.delegate dateRangeSelected:self.startDate endDate:self.startDate];
    } else {
        [self.delegate dateRangeSelected:self.startDate endDate:self.endDate];
    }
}

@end
