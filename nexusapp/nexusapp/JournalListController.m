//
//  JournalListController.m
//  nexuspad
//
//  Created by Ren Liu on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NPJournal.h"
#import "JournalListController.h"
#import "DateUtil.h"
#import "JournalViewController.h"
#import "UILabel+NPUtil.h"
#import "UserManager.h"
#import "UITableView+NPAnime.h"
#import "UITableViewCell+NPUtil.h"


@interface JournalListController ()
@property (nonatomic, strong) InputMonthSelector *monthSelector;
@property (nonatomic, strong) UILabel *emptyListLabel;
@end

@implementation JournalListController

@synthesize startDate, endDate;


// Overwrite the displayEntryList method in EntryListController
- (void)retrieveEntryList {
    [super retrieveEntryList];

    if (self.currentEntryList == nil) {
        self.currentEntryList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:journal];
    }

    NSArray *datesArr = [DateUtil findMonthStartEndDate:self.startDate];
    
    self.startDate = [datesArr objectAtIndex:0];
    self.endDate = [datesArr objectAtIndex:1];
    
    [self.entryListService getEntriesByDateRange:journal inFolder:self.currentFolder startDate:self.startDate endDate:self.endDate];
    
    self.navigationItem.title = [DateUtil displayMonthAndYear:self.startDate];
}


// Basic handling of Service Result. Only handles EntryList result.
- (void)updateServiceResult:(id)serviceResult
{
    [super updateServiceResult:serviceResult];
    
    /*
     * 1. Load the regular returned entry list into table. Load more is handled in EntryListFolderViewController
     * 2. Handle "load more" for search result.
     */
    
    if ([serviceResult isKindOfClass:[EntryList class]]) {
        EntryList *returnedList = (EntryList*)serviceResult;
        
        // Filter out the journal entries who have empty body
        NSMutableArray *journals = [[NSMutableArray alloc] init];
        for (NPJournal *j in returnedList.entries) {
            if (j.note.length > 0) {
                [journals addObject:j];
            }
        }

        // Reverse the journals so the latest one can be shown on top.
        returnedList.entries = [[NSMutableArray alloc] initWithCapacity:journals.count];
        NSEnumerator *enumerator = [journals reverseObjectEnumerator];
        
        for (id element in enumerator) {
            [returnedList.entries addObject:element];
        }

        
        if (![returnedList isSearchResult]) {                                           // Regular listing result
            
            if ([returnedList isNotEmpty]) {
                [self.emptyListLabel removeFromSuperview];

                if (returnedList.pageId <= 1) {
                    self.currentEntryList = [returnedList copy];
                    DLog(@"Initial query result %@", [self.currentEntryList description]);
                    
                    [self.entryListTable reloadData];
                }
                
            } else {
                [self.entryListTable addSubview:self.emptyListLabel];

                self.currentEntryList = [returnedList copy];
                [self.entryListTable reloadData];
            }
            
        } else {                                                                        // Search result
            
            if (self.searchResultList == nil) {
                self.searchResultList = [[EntryList alloc] initList:self.currentFolder entryTemplateId:journal];
            }
            
            if (returnedList.pageId > 1) {
                [self.searchResultList.entries addObjectsFromArray:returnedList.entries];
                DLog(@"More search query %@", [returnedList description]);
                
            } else {
                self.searchResultList = [returnedList copy];
                DLog(@"Initial search query %@", [self.searchResultList description]);
            }
            
            [self unDimSearchTable];
            [self.listSearchDisplayController.searchResultsTableView reloadData];
        }
    }
}


// Delegate for month selector.
- (void)didSelectMonth:(NSString*)ym
{
    NSRange range = NSMakeRange(0, 4);
    int year = [[ym substringWithRange:range] intValue];
    range = NSMakeRange(4, 2);
    int month = [[ym substringWithRange:range] intValue];
    
    NSArray *dates = [DateUtil findMonthStartEndDate:year month:month];
    self.startDate = [dates objectAtIndex:0];
    self.endDate = [dates objectAtIndex:1];
    
    [self retrieveEntryList];
    
    [self setListToolbarItems];
}

#pragma mark - search delegate
- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
    [ViewDisplayHelper displayWaiting:self.view messageText:@""];
    [self.entryListService searchEntries:self.searchBar.text templateId:journal inFolder:self.currentFolder pageId:1 countPerPage:0];
}


#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isSearchTableView:tableView]) {
        NSInteger count = [self.searchResultList.entries count];
        if ([self hasMoreSearchResultToLoad:tableView]) {
            return count + 1;
        }
        return count;
        
    } else {
        return self.currentEntryList.entries.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Empty list message cell
    if (self.currentEntryList.entries.count == 0) {
        return [UITableViewCell emptyListMessageCell:NSLocalizedString(@"No journals in this month.", )];
    }
    
    NPJournal *journalEntry = nil;

    if ([self isSearchTableView:tableView]) {
        journalEntry = [self.searchResultList.entries objectAtIndex:indexPath.row];
    } else {
        journalEntry = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }
    
    static NSString *CellIdentifier = @"EntryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
        
    cell.textLabel.text = journalEntry.note;
    
    NSDate *d = [DateUtil parseFromYYYYMMDD:journalEntry.ymd];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [DateUtil displayWeekday:d], [DateUtil displayDate:d]];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NPJournal *journalEntry = nil;
    
    if ([self isSearchTableView:tableView]) {
        journalEntry = [self.searchResultList.entries objectAtIndex:indexPath.row];
    } else {
        journalEntry = [self.currentEntryList.entries objectAtIndex:indexPath.row];
    }
    
    if (self.delegate) {
        [self.delegate didSelectedDate:journalEntry.ymd];
    }

    // Have to do this. Otherwise the app crashes.
    if ([self isSearchTableView:tableView]) {
        [self.listSearchDisplayController setActive:NO];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Delete the journal at the row
    
    NPJournal *journalEntry = nil;

    if ([self isSearchTableView:tableView]) {
        journalEntry = [self.searchResultList.entries objectAtIndex:indexPath.row];
        [self.searchResultList deleteFromList:journalEntry];

    } else {
        journalEntry = [self.currentEntryList.entries objectAtIndex:indexPath.row];
        [self.currentEntryList deleteFromList:journalEntry];
    }

    [self.entryService deleteEntry:journalEntry];
    
    NSArray *deleteIndexPaths = [NSArray arrayWithObject:indexPath];
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}

- (IBAction)thisMonthButtonTapped:(id)sender {
    [self didSelectMonth:[DateUtil convertToYYYYMM:[[NSDate alloc] init]]];
}

- (IBAction)selectMonth:(id)sender
{
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

- (BOOL)searchLocal {
    return NO;
}

- (void)viewDidLoad {
    self.currentFolder = [NPFolder initRootFolder:PLANNER_MODULE accessInfo:[[UserManager instance] defaultAccessInfo]];

    [super viewDidLoad];
    
    [self initPullRefresh:self.entryListTable];

    //self.entryListTable.tableHeaderView = self.searchBar;

    
    if (self.emptyListLabel == nil) {
        self.emptyListLabel = [[UILabel alloc] init];
        self.emptyListLabel.text = NSLocalizedString(@"No journal in this month.",);
        self.emptyListLabel.textColor = [UIColor lightGrayColor];
    }
    
    CGRect rect = self.entryListTable.frame;
    rect.origin.x = 12.0;
    rect.origin.y = 44.0;
    rect.size.height = 44.0;
    
    self.emptyListLabel.frame = rect;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationItem.title = [DateUtil displayMonthAndYear:self.startDate];
    [self retrieveEntryList];
    [self setListToolbarItems];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.monthSelector.isVisible) {
        [self.monthSelector slideOff];
        [self.monthSelector slideIn:self.view];
    }
}

- (IBAction)closeMonthView:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)setListToolbarItems {
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if (![[DateUtil convertToYYYYMM:self.startDate] isEqualToString:[DateUtil convertToYYYYMM:[[NSDate alloc] init]]]) {
        [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:@"10"]];
    }
    
    [items addObject:[UIBarButtonItem spacer]];
    [items addObject:[self.toolbarItemsLoadedInStoryboard objectForKey:@"11"]];

    self.toolbarItems = items;
}

@end
