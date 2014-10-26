//
//  RecurrenceEditorViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RecurrenceEditorViewController.h"
#import "UIView+FindFirstResponder.h"
#import "DateUtil.h"
#import "ViewDisplayHelper.h"


@interface RecurrenceEditorViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *patternNoRepeatCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *patternDailyCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *patternWeekdayDailyCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *patternWeeklyCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *patternMonthlyCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *patternYearlyCell;

// Repeat interval
@property (strong, nonatomic) IBOutlet UITableViewCell *repeatIntervalCell;
@property (strong, nonatomic) IBOutlet UILabel *intervalCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *intervalUnitLabel;
@property (strong, nonatomic) IBOutlet UIStepper *intervalStepper;

// Repeat end
@property (weak, nonatomic) IBOutlet UITableViewCell *recurCountCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *recurEndCell;

@property (weak, nonatomic) IBOutlet UITextField *repeatEndDateTextField;
@property (weak, nonatomic) IBOutlet UILabel *repeatTimeTextLabel;

@property (strong, nonatomic) IBOutlet UIStepper *repeatTimesStepper;
@property (strong, nonatomic) IBOutlet UILabel *repeatForeverLabel;
@property (strong, nonatomic) IBOutlet UISwitch *repeatForeverSwitch;

@property (strong, nonatomic) IBOutlet UITableViewCell *repeatForeverCell;
@end

@implementation RecurrenceEditorViewController
@synthesize repeatEndDateTextField;
@synthesize repeatTimeTextLabel;
@synthesize patternNoRepeatCell;
@synthesize patternDailyCell;
@synthesize patternWeeklyCell;
@synthesize patternMonthlyCell;
@synthesize patternYearlyCell;
@synthesize patternWeekdayDailyCell;
@synthesize recurCountCell;
@synthesize recurEndCell;

@synthesize recurrence = _recurrence;

#pragma mark - Handle input changes

- (IBAction)repeatIntervalStepperValueChanged:(UIStepper*)sender {
    int value = (int)[sender value];
    self.recurrence.interval = value;
    self.intervalCountLabel.text = [NSString stringWithFormat:@"%i", value];
}


- (IBAction)repeatTimesStepperValueChanged:(UIStepper*)sender
{
    int value = (int)[sender value];
    self.recurrence.recurrenceTimes = value;
    self.repeatTimeTextLabel.text = [NSString stringWithFormat:@"%i", value];
    
    // Reset repeat end date to nil
    self.recurrence.endDate = nil;
    self.repeatEndDateTextField.text = @"";
}

- (void)inputAccessoryViewDidCancel:(id)sender
{
    [self.view endEditing:YES];
}

- (void)inputAccessoryViewDidFinish:(id)sender
{
    self.repeatEndDateTextField.text = [DateUtil displayDate:self.recurrence.endDate];
    [self.view endEditing:YES];
}

- (void)recurEndDateChanged:(UIDatePicker*)datePicker
{
    self.recurrence.endDate = datePicker.date;
    
    // Reset repeat times to blank
    self.repeatTimesStepper.value = 1;
    self.repeatTimeTextLabel.text = @"";
}

- (IBAction)cancelRecurrence:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneRecurrence:(id)sender
{
    [self.entryUpdateDelegate updateEventRecurrence:self.recurrence];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.recurrence.pattern == norepeat) {
        return 1;
    } else {
        return 3;
    }
}

- (void)darkerFont:(UILabel*)label {
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textColor = [UIColor blackColor];
}

- (void)lighterFont:(UILabel*)label {
    label.font = [UIFont systemFontOfSize:16.0];
    label.textColor = [UIColor grayColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 0) {
                self.patternNoRepeatCell.textLabel.text = NSLocalizedString(@"No repeat",);
                if (self.recurrence.pattern == norepeat) {
                    [self darkerFont:self.patternNoRepeatCell.textLabel];
                    self.patternNoRepeatCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternNoRepeatCell.textLabel];
                    self.patternNoRepeatCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternNoRepeatCell;
                
            } else if (indexPath.row == 1) {
                self.patternDailyCell.textLabel.text = NSLocalizedString(@"Repeat daily",);
                if (self.recurrence.pattern == daily) {
                    [self darkerFont:self.patternDailyCell.textLabel];
                    self.patternDailyCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternDailyCell.textLabel];
                    self.patternDailyCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternDailyCell;

            } else if (indexPath.row == 2) {
                self.patternWeekdayDailyCell.textLabel.text = NSLocalizedString(@"Repeat daily on weekdays",);
                if (self.recurrence.pattern == weekdaily) {
                    [self darkerFont:self.patternWeekdayDailyCell.textLabel];
                    self.patternWeekdayDailyCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternWeekdayDailyCell.textLabel];
                    self.patternWeekdayDailyCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternWeekdayDailyCell;
                
            } else if (indexPath.row == 3) {
                self.patternWeeklyCell.textLabel.text = NSLocalizedString(@"Repeat weekly",);
                if (self.recurrence.pattern == weekly) {
                    [self darkerFont:self.patternWeeklyCell.textLabel];
                    self.patternWeeklyCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternWeeklyCell.textLabel];
                    self.patternWeeklyCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternWeeklyCell;

            } else if (indexPath.row == 4) {
                self.patternMonthlyCell.textLabel.text = NSLocalizedString(@"Repeat monthly",);
                if (self.recurrence.pattern == monthly) {
                    [self darkerFont:self.patternMonthlyCell.textLabel];
                    self.patternMonthlyCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternMonthlyCell.textLabel];
                    self.patternMonthlyCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternMonthlyCell;

            } else if (indexPath.row == 5) {
                self.patternYearlyCell.textLabel.text = NSLocalizedString(@"Repeat yearly",);
                if (self.recurrence.pattern == yearly) {
                    [self darkerFont:self.patternYearlyCell.textLabel];
                    self.patternYearlyCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    [self lighterFont:self.patternYearlyCell.textLabel];
                    self.patternYearlyCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.patternYearlyCell;
            }

        }
        case 1:
        {
            self.intervalCountLabel.text = [NSString stringWithFormat:@"%i", self.recurrence.interval];

            if (self.recurrence.pattern == daily || self.recurrence.pattern == weekdaily) {
                self.intervalUnitLabel.text = NSLocalizedString(@"day(s)",);
            }
            else if (self.recurrence.pattern == weekly) {
                self.intervalUnitLabel.text = NSLocalizedString(@"week(s)",);
            }
            else if (self.recurrence.pattern == monthly) {
                self.intervalUnitLabel.text = NSLocalizedString(@"month(s)",);
            }
            else if (self.recurrence.pattern == yearly) {
                self.intervalUnitLabel.text = NSLocalizedString(@"year(s)",);
            }
            
            return self.repeatIntervalCell;
        }
        case 2:
        {
            if ([self.repeatForeverSwitch isOn]) {
                if (indexPath.row == 0) {
                    return self.repeatForeverCell;
                }

            } else {
                if (indexPath.row == 0) {
                    if (self.recurrence.recurrenceTimes > 1) {
                        self.repeatTimeTextLabel.text = [NSString stringWithFormat:@"%i", self.recurrence.recurrenceTimes];
                        self.repeatTimesStepper.value = self.recurrence.recurrenceTimes;
                    } else if (self.recurrence.endDate != nil){
                        self.repeatTimeTextLabel.text = @"";
                        self.repeatTimesStepper.value = 1;
                    } else {
                        self.repeatTimeTextLabel.text = @"1";
                        self.repeatTimesStepper.value = 1;
                    }
                    return self.recurCountCell;
                    
                } else if (indexPath.row == 1){
                    
                    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                    datePicker.datePickerMode = UIDatePickerModeDate;
                    self.repeatEndDateTextField.inputView = datePicker;
                    [datePicker addTarget:self action:@selector(recurEndDateChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    [self addInputViewToolbar:self.repeatEndDateTextField];
                    
                    if (_recurrence.endDate != nil) {
                        self.repeatEndDateTextField.text = [DateUtil displayDate:_recurrence.endDate];
                    }
                    
                    return self.recurEndCell;
                    
                } else if (indexPath.row == 2) {
                    if (_recurrence.recurForever) {
                        [self.repeatForeverSwitch setOn:YES];
                    } else {
                        [self.repeatForeverSwitch setOn:NO];
                    }
                    return self.repeatForeverCell;
                }
            }
        }
        default:
            break;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 6;

        case 1:
            return 1;

        case 2:
            if ([self.repeatForeverSwitch isOn]) {
                return 1;
            }
            return 3;
            
        default:
            break;
    }
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.recurrence.pattern = norepeat;

        } else if (indexPath.row == 1) {
            self.recurrence.pattern = daily;
            
        } else if (indexPath.row == 2) {
            self.recurrence.pattern = weekdaily;
            
        } else if (indexPath.row == 3) {
            self.recurrence.pattern = weekly;

        } else if (indexPath.row == 4) {
            self.recurrence.pattern = monthly;

        } else if (indexPath.row == 5) {
            self.recurrence.pattern = yearly;
        }
        
        [self.tableView reloadData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 32.0;
    }
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section==0)
        return 1.0;

    return 30.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [ViewDisplayHelper emptyViewFiller];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    
    if (_recurrence.recurForever) {
        [self.repeatForeverSwitch setOn:YES];
    } else {
        [self.repeatForeverSwitch setOn:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    
    [self.repeatForeverSwitch addTarget:self action:@selector(updateRepeatForever:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload
{
    [self setRecurCountCell:nil];
    [self setRecurEndCell:nil];
    [self setPatternNoRepeatCell:nil];
    [self setPatternDailyCell:nil];
    [self setPatternWeeklyCell:nil];
    [self setPatternMonthlyCell:nil];
    [self setPatternYearlyCell:nil];
    [self setRepeatEndDateTextField:nil];
    [self setRepeatTimeTextLabel:nil];
    [self setPatternWeekdayDailyCell:nil];
    [super viewDidUnload];
}


- (void)updateRepeatForever:(id)sender {
    if ([sender isOn]) {
        _recurrence.recurForever = YES;
        self.repeatForeverLabel.text = NSLocalizedString(@"Repeat forever",);
    } else {
        _recurrence.recurForever = NO;
        self.repeatForeverLabel.text = NSLocalizedString(@"Or repeat forever",);
    }
    
    [self.tableView reloadData];
}

- (void)addInputViewToolbar:(UITextField*)textField;
{
    UIToolbar *pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 44)];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self action:@selector(inputAccessoryViewDidFinish:)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self action:@selector(inputAccessoryViewDidCancel:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [pickerToolbar setItems:[NSArray arrayWithObjects:cancelButton, flexibleSpace, doneButton, nil] animated:NO];
    
    textField.inputAccessoryView = pickerToolbar;
}


@end
