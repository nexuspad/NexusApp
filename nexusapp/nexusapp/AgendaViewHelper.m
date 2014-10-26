//
//  AgendaViewPresenter.m
//  nexusapp
//
//  Created by Ren Liu on 10/9/13.
//
//

#import "AgendaViewHelper.h"
#import "UserPrefUtil.h"
#import "DateUtil.h"
#import "NPEvent.h"
#import "UITableView+NPAnime.h"
#import "UITableViewCell+NPUtil.h"
#import "EventListViewCell.h"
#import "UIColor+NPColor.h"

#define REFRESH_HEADER_HEIGHT 52.0f

@interface AgendaViewHelper ()
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSMutableArray *sectionTitles;
@property (nonatomic, strong) NSMutableArray *eventListBySection;
@property (nonatomic, strong) NSMutableArray *emptyCellIndexPaths;
@property (nonatomic, strong) NSIndexPath *loadMoreIndexPath;

@property (nonatomic, strong) UIView *refreshHeaderView;
@property (nonatomic, strong) UILabel *refreshLabel;
@property (nonatomic, strong) UIImageView *refreshArrow;
@property (nonatomic, strong) UIActivityIndicatorView *refreshSpinner;
@property (nonatomic, strong) NSString *textPull;
@property (nonatomic, strong) NSString *textRelease;
@property (nonatomic, strong) NSString *textLoading;

@property BOOL isDragging;
@property BOOL isLoading;

@property NSMutableDictionary *dots;
@property NSDate *today;

@end

@implementation AgendaViewHelper

@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner, isDragging, isLoading, dots = _dots, today = _today;


- (id)initWithFrame:(CGRect)frame {
    self = [super init];
    
    self.agendaTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.agendaTableView.dataSource = self;
    self.agendaTableView.delegate = self;

    self.searchBar = [[UISearchBar alloc] init];
    
    self.searchBar.frame = CGRectMake(0, 0, 0, 44.0);
    self.agendaTableView.tableHeaderView = self.searchBar;
    
    [self initPullRefresh];

    return self;
}

- (void)refreshView:(NPFolder*)inFolder startDate:(NSDate*)startDate endDate:(NSDate*)endDate withEntryList:(EntryList*)withEntryList {
    self.folder = inFolder;
    
    BOOL isLoadingMore = NO;
    
    if ([endDate compare:self.endDate] == NSOrderedDescending) {
        isLoadingMore = YES;
    }
    
    self.startDate = startDate;
    self.endDate = endDate;

    // Remove the NSIndexPath markers
    [self.emptyCellIndexPaths removeAllObjects];
    self.loadMoreIndexPath = nil;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedEvents = [withEntryList.entries sortedArrayUsingDescriptors:sortDescriptors];
    
    // A dictionary that has the section title as key, and an array of events as value
    NSMutableDictionary *sectionedEvents = [[NSMutableDictionary alloc] init];
    
    // Get all the sections
    self.sectionTitles = [[NSMutableArray alloc] init];
    
    for (NPEvent *theEvent in sortedEvents) {
        NSString *sectionTitle = [DateUtil displayEventWeekdayAndDate:theEvent.startTime];
        if (![self.sectionTitles containsObject:sectionTitle]) {
            [self.sectionTitles addObject:sectionTitle];   
        }
        [sectionedEvents setObject:[[NSMutableArray alloc] init] forKey:sectionTitle];
    }
    
    NSDate *now = [NSDate date];
    NSInteger scrollToSectionId = 0;
    NSInteger scrollToRowId = 0;
    BOOL foundPosition = NO;

    for (NPEvent *theEvent in sortedEvents) {
        NSString *sectionTitle = [DateUtil displayEventWeekdayAndDate:theEvent.startTime];
        [[sectionedEvents objectForKey:sectionTitle] addObject:theEvent];
        
        // The very first event that happens at a later time than now
        if (!foundPosition) {
            if ([theEvent.startTime compare:now] == NSOrderedDescending) {
                scrollToSectionId = [self.sectionTitles indexOfObject:sectionTitle];
                scrollToRowId = [[sectionedEvents objectForKey:sectionTitle] indexOfObject:theEvent];
                foundPosition = YES;
            }
        }
    }
    
    self.eventListBySection = [[NSMutableArray alloc] init];
    for (NSString* sectionTitle in self.sectionTitles) {
        [self.eventListBySection addObject:[sectionedEvents objectForKey:sectionTitle]];
    }

    // Reset this so it won't get too old.
    _today = nil;
    
    [self.agendaTableView reloadData];
    
    // Scroll to somewhere close to today
    if (!isLoadingMore) {
        if (scrollToSectionId != 0 || scrollToRowId != 0) {
            [self.agendaTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollToRowId inSection:scrollToSectionId]
                                        atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }        
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.eventListBySection count] + 1;         // An extra section for "load more" cell
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoadMoreSection:section]) {
        self.loadMoreIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        return 1;
        
    } else {
        
        NSInteger rowCount = [[self.eventListBySection objectAtIndex:section] count];
        
        if (rowCount == 0) {
            rowCount = 1;
            NSIndexPath *emptyCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
            
            if (self.emptyCellIndexPaths == nil) {
                self.emptyCellIndexPaths = [[NSMutableArray alloc] init];
            }
            
            [self.emptyCellIndexPaths addObject:emptyCellIndexPath];
        }
        
        return rowCount;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isLoadMoreSection:section]) {
        return @"";
    }
    return [self.sectionTitles objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath {
    return 55.0;
}

// Remove the bottom line
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isEmptyCellIndexPaths:indexPath]) {
        return [UITableViewCell emptyListMessageCell:NSLocalizedString(@"Nothing scheduled",)];
        
    } else if ([indexPath isEqual:self.loadMoreIndexPath]) {
        static NSString *CellIdentifier = @"LoadMoreCell";
        
        UITableViewCell *loadMoreCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (loadMoreCell == nil) {
            loadMoreCell = [UITableViewCell loadMoreCell];
        }
        
        return loadMoreCell;
        
    } else {
        NPEvent *evt = [[self.eventListBySection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];        
        static NSString *CellIdentifier = @"EventListCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        cell.textLabel.text = evt.title;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        cell.detailTextLabel.text = evt.eventTimeText;
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        
        cell.imageView.image = [self getDot:evt.colorLabel];
        
        if ([evt isPastEventToDate:[self getToday]]) {
            cell.textLabel.textColor = [UIColor grayColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }

        cell.textLabel.backgroundColor = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor whiteColor];
        
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:self.loadMoreIndexPath]) {
        [self.controllerDelegate getMoreEventsForAgendaView];
        
    } else {
        NPEvent *e = [[self.eventListBySection objectAtIndex:indexPath.section]objectAtIndex:indexPath.row];
        [self.controllerDelegate displayEventDetail:e];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:self.loadMoreIndexPath]) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the entry at row
        NPEvent *deleteEvent = [[[self.eventListBySection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] copy];
        [self.controllerDelegate deleteEvent:deleteEvent];
    }
}

- (BOOL)isLoadMoreSection:(NSInteger)sectionId {
    if (sectionId == self.eventListBySection.count) {
        return YES;
    }
    return NO;
}

- (BOOL)isEmptyCellIndexPaths:(NSIndexPath*)indexPath {
    for (NSIndexPath *aPath in self.emptyCellIndexPaths) {
        if ([aPath isEqual:indexPath]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - pull refresh and scroll handling

- (void)initPullRefresh {
    textPull = NSLocalizedString(@"Pull down to refresh...",);
    textRelease = NSLocalizedString(@"Release to refresh...",);
    textLoading = NSLocalizedString(@"Refreshing...",);
    
    self.refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 320, REFRESH_HEADER_HEIGHT)];
    self.refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    refreshLabel.text = self.textPull;
    refreshLabel.textColor = [UIColor textColorFromBackground:self.agendaTableView.backgroundColor];
    refreshLabel.textAlignment = NSTextAlignmentCenter;
    
    if ([refreshLabel.textColor isEqual:[UIColor blackColor]]) {
        refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blackArrow.png"]];
    } else {
        refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteArrow.png"]];
    }
    
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    
    [self.refreshHeaderView addSubview:refreshLabel];
    [self.refreshHeaderView addSubview:refreshArrow];
    [self.refreshHeaderView addSubview:refreshSpinner];
    
    [self.agendaTableView addSubview:self.refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.isLoading) return;
    self.isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isLoading) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0) {
            self.agendaTableView.contentInset = UIEdgeInsetsZero;
        } else if (scrollView.contentOffset.y >= [self pullRefreshOffsetThreshold]) {
            self.agendaTableView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
        }
        
    } else if (self.isDragging && scrollView.contentOffset.y < 0) {
        
        // Update the arrow direction and label
        [UIView animateWithDuration:0.25 animations:^{
            if (scrollView.contentOffset.y < [self pullRefreshOffsetThreshold]) {
                // User is scrolling above the header
                
                refreshLabel.text = self.textRelease;
                refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
                
            } else {
                // User is scrolling somewhere within the header
                refreshLabel.text = self.textPull;
                refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }
        }];
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
    
    if (maximumOffset - currentOffset <= -30) {
        // Handles the load more
        [self.controllerDelegate getMoreEventsForAgendaView];

    } else {
        // Handles pull refresh
        if (self.isLoading) return;
        self.isDragging = NO;
        
        if (scrollView.contentOffset.y <= [self pullRefreshOffsetThreshold]) {
            // Released above the header
            [self startLoading];
        }
    }
}


- (float)pullRefreshOffsetThreshold {
    float refreshOffsetThreadhold = REFRESH_HEADER_HEIGHT;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        refreshOffsetThreadhold += 20;
    }
    
    return -refreshOffsetThreadhold;
}

- (void)startLoading {
    self.isLoading = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3
                     animations:^{
                         //self.draggableView.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
                         refreshLabel.text = self.textLoading;
                         refreshArrow.hidden = YES;
                         [refreshSpinner startAnimating];
                     }];
    
    // Refresh action!
    [self pullRefresh];
}

- (void)stopLoading {
    self.isLoading = NO;
    
    // Hide the header
    [UIView animateWithDuration:0.3
                     animations:^{
                         if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                             self.agendaTableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0);
                         } else {
                             self.agendaTableView.contentInset = UIEdgeInsetsZero;
                         }
                         
                         refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
                     }
                     completion:^(BOOL finished) {
                         [self performSelector:@selector(stopLoadingComplete)];
                     }];
}

- (void)stopLoadingComplete {
    // Reset the header
    refreshLabel.text = self.textPull;
    refreshArrow.hidden = NO;
    [refreshSpinner stopAnimating];
}

- (void)pullRefresh {
    DLog(@"Start pull refreshing action...");
    [self.controllerDelegate requestDataToRefreshView];
    // Don't forget to call stopLoading at the end.
    [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0.5];
}


- (UIImage*)getDot:(NSString*)colorHexStr {
    UIImage *dot = nil;
    
    if (_dots == nil) {
        _dots = [[NSMutableDictionary alloc] init];
    }
    
    if ([_dots objectForKey:colorHexStr] != nil) {
        return [_dots objectForKey:colorHexStr];

    } else {
        UIGraphicsBeginImageContext(CGSizeMake(15.0f, 15.0f));
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(contextRef, [[UIColor colorFromHexString:colorHexStr] CGColor]);
        CGContextFillEllipseInRect(contextRef,(CGRectMake (0.f, 0.f, 15.0f, 15.0f)));
        dot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [_dots setObject:dot forKey:colorHexStr];
        return dot;
    }
}

- (NSDate*)getToday {
    if (_today == nil) {
        _today = [DateUtil startOfDate:[NSDate date]];
    }
    return _today;
}

@end
