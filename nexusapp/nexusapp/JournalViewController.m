//
//  JournalViewController.m
//  nexuspad
//
//  Created by Ren Liu on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JournalViewController.h"
#import "JournalListController.h"
#import "DateUtil.h"
#import "EntryActionResult.h"
#import "UIBarButtonItem+NPUtil.h"
#import "EmailEntryViewController.h"
#import "UIViewController+NPUtil.h"
#import "UIViewController+KNSemiModal.h"
#import "DropdownButton.h"
#import "JournalService.h"


@interface JournalViewController ()
@property (nonatomic, strong) JournalService *journalService;
@property (nonatomic, strong) InputDateSelectorView *dateSelector;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *dashboardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *todayButton;

@property (nonatomic, strong) NSMutableDictionary *journals;
@property (nonatomic, strong) NSMutableDictionary *journalPadsByDate;

@property (nonatomic, strong) NSDate *lastAccessTime;

@property BOOL orientationChanged;

@property (nonatomic, strong) NSString *currentJournalYmd;

@end

static UIColor *YELLOW_BACKGROUND_COLOR;

@implementation JournalViewController

@synthesize dashboardButton;
@synthesize entryService, journals = _journals, journalPadsByDate = _journalPadsByDate;
@synthesize journalScrollView = _journalScrollView;

- (void)retrieveTextContentByDate:(NSDate*)date {
    if ([DateUtil isToday:date]) {
        self.todayButton.enabled = NO;
        self.todayButton.title = @"";
    } else {
        self.todayButton.enabled = YES;
        self.todayButton.title = NSLocalizedString(@"Today",);
    }
    
    DropdownButton *navButton = [[DropdownButton alloc] init:self action:@selector(selectJournalDate:)
                                                       line1:[DateUtil displayEventWeekdayAndDate:date]
                                                       line2:nil
                                                  rightImage:[UIImage imageNamed:@"arrow-down.png"]];
    self.navigationItem.titleView = navButton;

    
    if (self.journalService == nil) {
        self.journalService = [[JournalService alloc] init];
        self.journalService.serviceDelegate = self;
    }
    
    [self.journalService getJournal:PLANNER_MODULE forDate:date];
}

- (void)updateServiceResult:(id)serviceResult {
    [ViewDisplayHelper dismissWaiting:self.view];
    
    if ([serviceResult isKindOfClass:[NPEntry class]]) {
        NPJournal *j = [NPJournal journalFromEntry:serviceResult];
        [self setJournalObject:j];
        DTNotePadView *page = [self getOrInitJournalNotePad:j.ymd];
        page.textView.text = j.note;
        
    } else if ([serviceResult isKindOfClass:[EntryActionResult class]]) {
        EntryActionResult *actionResponse = (EntryActionResult*)serviceResult;
        NPJournal *j = [NPJournal journalFromEntry:actionResponse.entry];
        [self setJournalObject:j];

        if (actionResponse.success == NO) {
            DLog(@"Failed to save the journal entry for date:%@", [j.createTime description]);
        }
    }
}

- (void)serviceError:(ServiceResult*)serviceResult
{
    NSLog(@"NPService returned error: %@", [serviceResult description]);
    [ViewDisplayHelper dismissWaiting:self.view];
}


- (NPJournal*)getJournalObject:(NSString*)ymd {
    if (_journals == nil) {
        _journals = [[NSMutableDictionary alloc] init];
    }

    if ([_journals objectForKey:ymd] == nil) {
        NPJournal *j = [[NPJournal alloc] initJournal:[DateUtil parseFromYYYYMMDD:ymd]];
        [j setOwnerAccessInfo:[[AccessEntitlement accountOwner] userId]];
        [_journals setObject:j forKey:ymd];
    }
    
    return [_journals objectForKey:ymd];
}

- (void)setJournalObject:(NPJournal*)journal {
    if (_journals == nil) {
        _journals = [[NSMutableDictionary alloc] init];
    }
    
    [_journals setObject:journal forKey:[DateUtil convertToYYYYMMDD:journal.createTime]];
}

- (DTNotePadView*)getOrInitJournalNotePad:(NSString*)ymd {
    if (_journalPadsByDate == nil) {
        _journalPadsByDate = [[NSMutableDictionary alloc] init];
    }
    
    DLog(@"Get journal page for %@", ymd);
    
    DTNotePadView *pad = [_journalPadsByDate objectForKey:ymd];
    
    if (pad == nil) {
        CGRect rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];
        rect.origin.x = 0;
        rect.origin.y = 0;
        pad = [[DTNotePadView alloc] initWithFrame:rect];
        pad.tag = [ymd integerValue];
        
        pad.delegate = self;

        [_journalPadsByDate setObject:pad forKey:ymd];
    }

    return pad;
}


- (NSDate*)getActiveJournalDate {
    if (_journalScrollView == nil) {
        return [[NSDate alloc] init];
    }
    
    DTNotePadView *activeJournalPage = (DTNotePadView*)[_journalScrollView activePage];
    if (activeJournalPage == nil) {
        return [[NSDate alloc] init];
    }
    
    NSString *ymd = [NSString stringWithFormat:@"%li", (long)activeJournalPage.tag];
    
    DLog(@"Active journal date is %@", ymd);
    
    return [DateUtil parseFromYYYYMMDD:ymd];
}


- (void)saveJournal:(id)sender {
    [self.view endEditing:YES];
    
    NSDictionary *journalsCopy = [_journals copy];

    for (NSString *ymd in journalsCopy) {
        NPJournal *j = [journalsCopy objectForKey:ymd];
        DLog(@"Save journal on: %@", ymd);
        [self.journalService addOrUpdateEntry:j];
    }
}


#pragma mark - input date selector

// Delegate for date selector. This is called from both data picker and JournalListController
- (void)didSelectedDate:(id)sender {
    NSString *ymd = (NSString*)sender;
    [self initJournalScrollView:[DateUtil parseFromYYYYMMDD:ymd]];

    if (self.dateSelector.isVisible == YES) {   // didSelectedDate may be called in JournalListController, so check before calling dismissSemiModalView
        self.dateSelector.isVisible = NO;
        [self dismissSemiModalView];
    }
}

- (void)inputValueSelectorCancelled {
}

#pragma mark - DTNotePadView delegate

- (void)notePadViewDidChange:(DTNotePadView *)notePadView {
    NPJournal *j = [_journals objectForKey:[NSString stringWithFormat:@"%li", (long)notePadView.tag]];
    if (j == nil) {
        j = [[NPJournal alloc] initJournal:[[NSDate alloc] init]];
    }
    
    j.note = notePadView.textView.text;
    j.localModifiedTime = [[NSDate alloc] init];
    
    [_journals setObject:j forKey:[NSString stringWithFormat:@"%li", (long)notePadView.tag]];
}


- (void)notePadViewDidBeginEditing {
}


// This is called after clearing the screen.
- (void)notePadViewDidEndEditing:(DTNotePadView *)notePadView {
    NPJournal *j = [_journals objectForKey:[NSString stringWithFormat:@"%li", (long)notePadView.tag]];
    j.note = notePadView.textView.text;
    j.localModifiedTime = [[NSDate alloc] init];
    [self.journalService addOrUpdateEntry:j];
}


#pragma mark - scrollview delegate

- (id)getLeftPageView:(NSInteger)pageViewTag {
    DLog(@"Display journal at index %li", (long)pageViewTag);
    
    [self clearScreen];
    
    NSString *ymd = [NSString stringWithFormat:@"%li", (long)pageViewTag];
    NSDate *activeDate = [DateUtil parseFromYYYYMMDD:ymd];
    [self retrieveTextContentByDate:activeDate];

    NSDate *previousDate = [DateUtil addDays:activeDate days:-1];

    // This page will be put to the left side of the active page.
    DTNotePadView *page = [self getOrInitJournalNotePad:[DateUtil convertToYYYYMMDD:previousDate]];

    // Remove the buffered page to the far right
    NSDate *twoDaysAfterActiveDate = [DateUtil addDays:activeDate days:2];
    ymd = [DateUtil convertToYYYYMMDD:twoDaysAfterActiveDate];
    DLog(@"Remove buffered note page for %@", ymd);
    [self.journalPadsByDate removeObjectForKey:ymd];
    
    return page;
}

- (id)getRightPageView:(NSInteger)pageViewTag {
    DLog(@"Display journal at index %li", (long)pageViewTag);

    [self clearScreen];

    NSString *ymd = [NSString stringWithFormat:@"%li", (long)pageViewTag];
    NSDate *activeDate = [DateUtil parseFromYYYYMMDD:ymd];
    [self retrieveTextContentByDate:activeDate];

    NSDate *nextDate = [DateUtil addDays:activeDate days:1];
    
    // This page will be put to the right side of the active page
    DTNotePadView *page = [self getOrInitJournalNotePad:[DateUtil convertToYYYYMMDD:nextDate]];
    
    // Remove the bufferred page to the far left
    NSDate *twoDaysBeforeActiveDate = [DateUtil addDays:activeDate days:-2];
    ymd = [DateUtil convertToYYYYMMDD:twoDaysBeforeActiveDate];
    DLog(@"Remove buffered note page for %@", ymd);
    [self.journalPadsByDate removeObjectForKey:ymd];

    return page;
}

- (void)clearScreen {
    // Hide the keyboard
    [self.view endEditing:YES];
    
    if (self.dateSelector.isVisible == YES) {
        self.dateSelector.isVisible = NO;
        [self dismissSemiModalView];
    }
}

#pragma mark - create scrollview

- (void)initJournalScrollView:(NSDate*)forDate {
    // Clear the buffer if the initial date is not in there
    NSString *ymdKey = [DateUtil convertToYYYYMMDD:forDate];
    if ([self.journalPadsByDate objectForKey:ymdKey] == nil) {
        DLog(@"Clear the buffer...");
        [self.journalPadsByDate removeAllObjects];
    }

    NSMutableArray *initialPages = [[NSMutableArray alloc] initWithCapacity:3];
    
    NSDate *previousDate = [DateUtil addDays:forDate days:-1];
    DTNotePadView *previousDatePad = [self getOrInitJournalNotePad:[DateUtil convertToYYYYMMDD:previousDate]];
    [initialPages addObject:previousDatePad];
    
    DTNotePadView *activePad = [self getOrInitJournalNotePad:[DateUtil convertToYYYYMMDD:forDate]];
    [initialPages addObject:activePad];
    
    NSDate *nextDate = [DateUtil addDays:forDate days:1];
    DTNotePadView *nextDatePad = [self getOrInitJournalNotePad:[DateUtil convertToYYYYMMDD:nextDate]];
    [initialPages addObject:nextDatePad];
    
    CGRect rect;

    // self.edgesForExtendedLayout = UIRectEdgeNone;
//    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
//        rect = [ViewDisplayHelper contentViewRect:64.0 heightAdjustment:0];
//    } else {
//        rect = [ViewDisplayHelper contentViewRect:52.0 heightAdjustment:0];
//    }
    
    rect = [ViewDisplayHelper contentViewRect:0 heightAdjustment:0];

    NPScrollView *oldScrollViewPad = _journalScrollView;
    
    // There is no need to specify an starting index here because journal view is endless.
    if (oldScrollViewPad != nil) {
        // Create some animation
        [UIView transitionWithView:oldScrollViewPad duration:0.5 options:UIViewAnimationOptionTransitionCurlUp animations:^{
            oldScrollViewPad.alpha = 0;
            
        } completion:^(BOOL finished) {

            NPScrollView *newScrollViewPad = [[NPScrollView alloc] initWithPageViews:rect
                                                                           pageViews:initialPages
                                                                       startingIndex:99
                                                                     backgroundColor:YELLOW_BACKGROUND_COLOR];
            newScrollViewPad.dataDelegate = self;
            _journalScrollView = newScrollViewPad;
            [self.view addSubview:_journalScrollView];
            
            DTNotePadView *activeNotePad = (DTNotePadView*)[_journalScrollView activePage];
            DLog(@"what's on page: %li", (long)activeNotePad.tag);
            
            [oldScrollViewPad removeFromSuperview];

            [self retrieveTextContentByDate:forDate];
        }];

    } else {

        _journalScrollView = [[NPScrollView alloc] initWithPageViews:rect
                                                           pageViews:initialPages
                                                       startingIndex:99
                                                     backgroundColor:YELLOW_BACKGROUND_COLOR];
        _journalScrollView.dataDelegate = self;
        
        [self.view addSubview:_journalScrollView];
        
        [self retrieveTextContentByDate:forDate];
    }
}


- (IBAction)openJournalMonthView:(id)sender {
    [self performSegueWithIdentifier:@"OpenMonthList" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSDate *currentDate = [self getActiveJournalDate];
    
    if ([segue.identifier isEqualToString:@"OpenMonthList"]) {
        JournalListController *journalListController = [[segue.destinationViewController viewControllers] lastObject];
        [journalListController setStartDate:currentDate];
        journalListController.delegate = self;
    }
}

- (IBAction)openTodaysJournal:(id)sender {
    [self initJournalScrollView:[[NSDate alloc] init]];
}

- (IBAction)selectJournalDate:(id)sender
{    
    if (self.dateSelector == nil) {
        self.dateSelector = [[InputDateSelectorView alloc] init:self.view asInputView:NO];
        self.dateSelector.delegate = self;
    }
    
    [self.dateSelector selectDate:[self getActiveJournalDate]];

    [self.view endEditing:YES];

    self.dateSelector.isVisible = YES;
    [self presentSemiView:self.dateSelector withOptions:@{
                                                          KNSemiModalOptionKeys.pushParentBack    : @(YES),
                                                          KNSemiModalOptionKeys.animationDuration : @(0.3),
                                                          KNSemiModalOptionKeys.shadowOpacity     : @(0.3),
                                                          }];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.hidesBackButton = YES;

    if (self.dashboardButton == nil) {
        self.dashboardButton = [UIBarButtonItem dashboardButtonPlain:self action:@selector(backToDashboard)];
    }
    
    self.navigationItem.leftBarButtonItem = self.dashboardButton;
    
    // Journal could still be loaded even the app is in different place.
    // Check if the lastAccessTime is too old, and the journal should be reloaded with today's info.
    if (self.lastAccessTime != nil ) {
        NSDate *now = [[NSDate alloc] init];
        NSTimeInterval distanceBetweenDates = [now timeIntervalSinceDate:self.lastAccessTime];
        NSInteger hoursBetweenDates = distanceBetweenDates/3600;

        if (hoursBetweenDates > 18) {
            DLog(@"The last access time is too old. Reload the journal. last access: %@, now: %@", self.lastAccessTime, now);

            _journalPadsByDate = nil;
            
            // Need to remove the current scrollview
            [_journalScrollView removeFromSuperview];
            
            [self initJournalScrollView:now];

        } else {
            DropdownButton *navButton = [[DropdownButton alloc] init:self action:@selector(selectJournalDate:)
                                                               line1:[DateUtil displayEventWeekdayAndDate:[self getActiveJournalDate]]
                                                               line2:nil
                                                          rightImage:[UIImage imageNamed:@"arrow-down.png"]];
            self.navigationItem.titleView = navButton;
        }
    }
    
    // This is needed for situation like this:
    // - In journal view portrait
    // - Go to journal list view and change to landscape
    // - Go back to journal view, so we need to watch the orientation and make sure it's correctly set up.
    //
    if (self.orientationChanged) {
        // Chuck them all and re-create pads.
        _journalPadsByDate = nil;
        
        // Need to remove the current scrollview
        [_journalScrollView removeFromSuperview];
        
        [self initJournalScrollView:[self getActiveJournalDate]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if (self.saveButton == nil) {
        self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveJournal:)];
    }
    self.navigationItem.rightBarButtonItem = self.saveButton;
    
    // Color taken from Notepaper_middle.png
    YELLOW_BACKGROUND_COLOR = [UIColor colorWithRed:248.0/256 green:247.0/256 blue:216.0/256 alpha:1.0];
    
    self.view.backgroundColor = YELLOW_BACKGROUND_COLOR;

    // Use TODAY when the view is freshly loaded
    [self initJournalScrollView:[NSDate date]];
}

- (void)viewDidUnload {
    self.dashboardButton = nil;
    [super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Make sure saving it before view disappers
    [self saveJournal:nil];
    
    // Use lastAccessTime to keep track of the last time when the journal is in view.
    self.lastAccessTime = [[NSDate alloc] init];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
    }
    else {
    }
    self.orientationChanged = YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    self.orientationChanged = NO;

    // Chuck them all and re-create pads.
    _journalPadsByDate = nil;
    
    // Need to remove the current scrollview
    [_journalScrollView removeFromSuperview];

    [self initJournalScrollView:[self getActiveJournalDate]];

    [self clearScreen];
    [self.dateSelector removeFromSuperview];
    self.dateSelector = nil;
    
    if (self.dateSelector.isVisible == YES) {
        [self dismissSemiModalView];
    }
}
@end
