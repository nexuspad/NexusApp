//
//  DashboardController.m
//  nexuspad
//
//  Created by Ren Liu on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "UserManager.h"
#import "DashboardController.h"
#import "BaseEntryListViewController.h"
#import "ContactListController.h"
#import "BookmarkListController.h"
#import "CalendarViewController.h"
#import "PhotoListController.h"
#import "DocListController.h"
#import "UIColor+NPColor.h"
#import "UserPrefUtil.h"
#import "AddressbookService.h"


@interface DashboardController()
@property (weak, nonatomic) IBOutlet UITableViewCell *contactCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *calendarCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *docCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *photoCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *bookmarkCell;

@property (nonatomic, strong) ContactListController *contactController;
@property (nonatomic, strong) CalendarViewController *calendarController;
@property (nonatomic, strong) DocListController *docController;
@property (nonatomic, strong) PhotoListController *photoController;
@property (nonatomic, strong) BookmarkListController *bookmarkController;

@property int activeModule;
@property (nonatomic, strong) NSMutableDictionary *modulesOpened;
@end

@implementation DashboardController

@synthesize contactCell;
@synthesize calendarCell;
//@synthesize journalCell;
@synthesize docCell;
@synthesize photoCell;
@synthesize bookmarkCell;

#pragma mark - View lifecycle

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *)indexPath
{
    return 52.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            self.contactCell.imageView.image = [UIImage imageNamed:@"contact.png"];
            self.contactCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
            self.contactCell.textLabel.text = NSLocalizedString(@"Contacts",);
//            self.contactCell.textLabel.shadowColor = [UIColor whiteColor];
//            self.contactCell.textLabel.shadowOffset = CGSizeMake(0, 2);
            return self.contactCell;

        case 1:
            self.calendarCell.imageView.image = [UIImage imageNamed:@"calendar.png"];
            self.calendarCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
            self.calendarCell.textLabel.text = NSLocalizedString(@"Events and To-dos",);
//            self.calendarCell.textLabel.shadowColor = [UIColor whiteColor];
//            self.calendarCell.textLabel.shadowOffset = CGSizeMake(0, 2);
            return self.calendarCell;

//        case 2:
//            self.journalCell.imageView.image = [UIImage imageNamed:@"journal.png"];
//            self.journalCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
//            self.journalCell.textLabel.text = NSLocalizedString(@"My Journal",);
////            self.journalCell.textLabel.shadowColor = [UIColor whiteColor];
////            self.journalCell.textLabel.shadowOffset = CGSizeMake(0, 2);
//            return self.journalCell;

        case 2:
            self.docCell.imageView.image = [UIImage imageNamed:@"doc.png"];
            self.docCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
            self.docCell.textLabel.text = NSLocalizedString(@"Docs and Notes",);
//            self.docCell.textLabel.shadowColor = [UIColor whiteColor];
//            self.docCell.textLabel.shadowOffset = CGSizeMake(0, 2);
            return self.docCell;

        case 3:
            self.photoCell.imageView.image = [UIImage imageNamed:@"photo.png"];
            self.photoCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
            self.photoCell.textLabel.text = NSLocalizedString(@"Photos",);
//            self.photoCell.textLabel.shadowColor = [UIColor whiteColor];
//            self.photoCell.textLabel.shadowOffset = CGSizeMake(0, 2);
            return self.photoCell;

        case 4:
            self.bookmarkCell.imageView.image = [UIImage imageNamed:@"bookmark.png"];
            self.bookmarkCell.imageView.frame = CGRectMake(0, 0, 44.0, 44.0);
            self.bookmarkCell.textLabel.text = NSLocalizedString(@"Bookmarks",);
//            self.bookmarkCell.textLabel.shadowColor = [UIColor whiteColor];
//            self.bookmarkCell.textLabel.shadowOffset = CGSizeMake(0, 2);
            return self.bookmarkCell;

        default:
            break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorFromHexString:@"eeeeee"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccessEntitlement *accessInfo = [[UserManager instance] defaultAccessInfo];

    switch (indexPath.row) {
        case 0:
        {
            self.activeModule = CONTACT_MODULE;
            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];

            if (self.contactController == nil) {
                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_contact" bundle:nil];
                self.contactController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"ContactList"];
                self.contactController.currentFolder = [NPFolder initRootFolder:CONTACT_MODULE accessInfo:accessInfo];

            } else {
                //self.contactController.currentEntryList = nil;
            }

            [self.navigationController pushViewController:self.contactController animated:YES];
            
            break;
        }
        case 1:
        {
            self.activeModule = CALENDAR_MODULE;
            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];

            if (self.calendarController == nil) {
                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_calendar" bundle:nil];
                self.calendarController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"CalendarView"];
                self.calendarController.currentFolder = [NPFolder initRootFolder:CALENDAR_MODULE accessInfo:accessInfo];
            } else {
                self.calendarController.currentEntryList = nil;
            }

            if ([UserPrefUtil getPreference:PREF_LAST_CALENDAR_VIEW] != nil) {
                self.calendarController.viewType = [(NSNumber*)[UserPrefUtil getPreference:PREF_LAST_CALENDAR_VIEW] intValue];
            }

            [self.navigationController pushViewController:self.calendarController animated:YES];
            
            break;
        }
//        case 2:
//        {
//            self.activeModule = PLANNER_MODULE;
//            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];
//
//            if (self.journalController == nil) {
//                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_journal" bundle:nil];
//                self.journalController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"JournalDayView"];
//            }
//            self.journalController.accessInfo = [accessInfo copy];
//            [self.navigationController pushViewController:self.journalController animated:YES];
//
//            break;
//        }
        case 2:
        {
            self.activeModule = DOC_MODULE;
            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];

            if (self.docController == nil) {
                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_doc" bundle:nil];
                self.docController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"DocList"];
                self.docController.currentFolder = [NPFolder initRootFolder:DOC_MODULE accessInfo:accessInfo];
            } else {
                self.docController.currentEntryList = nil;
            }
            
            [self.navigationController pushViewController:self.docController animated:YES];

            break;
        }
        case 3:
        {
            self.activeModule = PHOTO_MODULE;
            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];

            if (self.photoController == nil) {
                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_photo" bundle:nil];
                self.photoController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"PhotoList"];
                self.photoController.currentFolder = [NPFolder initRootFolder:PHOTO_MODULE accessInfo:accessInfo];
            } else {
                self.photoController.currentEntryList = nil;
            }

            [self.navigationController pushViewController:self.photoController animated:YES];
            
            break;
        }
        case 4:
        {
            self.activeModule = BOOKMARK_MODULE;
            [self.modulesOpened setObject:[[NSDate alloc] init] forKey:[NSNumber numberWithInt:self.activeModule]];

            if (self.bookmarkController == nil) {
                UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_bookmark" bundle:nil];
                self.bookmarkController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"BookmarkList"];
                self.bookmarkController.currentFolder = [NPFolder initRootFolder:BOOKMARK_MODULE accessInfo:accessInfo];
            } else {
                self.bookmarkController.currentEntryList = nil;
            }

            [self.navigationController pushViewController:self.bookmarkController animated:YES];
            
            break;
        }
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // This will create a "invisible" footer
    return 0.01f;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    Account *currentAcct = [[AccountManager instance] getCurrentLoginAcct];
    
    if (currentAcct.firstName.length > 0) {
        self.navigationItem.title = [currentAcct firstName];
        self.navigationController.navigationBar.topItem.title = [currentAcct firstName];
        
    } else if (currentAcct.userName.length > 0) {
        self.navigationItem.title = [currentAcct userName];
        self.navigationController.navigationBar.topItem.title = [currentAcct userName];
        
    } else {
        self.navigationItem.title = NSLocalizedString(@"Home",);
        self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Home",);
    }
    
    // Set the current user
    [[UserManager instance] setCurrentUser:currentAcct];

    self.tableView.backgroundColor = [UIColor colorFromHexString:@"eeeeee"];
    
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        // Somehow this has to be set (though it's also done in AppDelegate) because after opening
        // the lightbox and navigate back, the toolbar changes to default background color.
        self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    }
    
    [self freeSomeMemory:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.modulesOpened == nil) {
        self.modulesOpened = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidUnload
{
    [self setContactCell:nil];
    [self setCalendarCell:nil];
    [self setDocCell:nil];
    [self setPhotoCell:nil];
    [self setBookmarkCell:nil];
    
    self.contactController = nil;
    self.calendarController = nil;
    self.docController = nil;
    self.photoController = nil;
    self.bookmarkController = nil;
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    [self freeSomeMemory:YES];
}

- (void)freeSomeMemory:(BOOL)memoryWarning {
    if (memoryWarning) {
        if (self.activeModule != DOC_MODULE) {
            [self removeController:DOC_MODULE];
        }
        
        if (self.activeModule != PHOTO_MODULE) {
            [self removeController:PHOTO_MODULE];
        }
        
        if (self.activeModule != BOOKMARK_MODULE) {
            [self removeController:BOOKMARK_MODULE];
        }
        
        if (self.activeModule != CONTACT_MODULE) {
            [self removeController:CONTACT_MODULE];
        }
        
        if (self.activeModule != PLANNER_MODULE) {
            [self removeController:PLANNER_MODULE];
        }
        
        if (self.activeModule != CALENDAR_MODULE) {
            [self removeController:CALENDAR_MODULE];
        }
    
    } else {
        if (self.modulesOpened.count > 1) {
            NSArray *sortedKeys = [self.modulesOpened keysSortedByValueUsingComparator: ^(NSDate *t1, NSDate *t2) {
                return [t1 compare:t2];
            }];
            
            int oldestModule = [[sortedKeys firstObject] intValue];
            if (oldestModule != self.activeModule) {
                [self removeController:oldestModule];
            }
        }
    }
}

- (void)removeController:(int)moduleId {
    if (moduleId == CONTACT_MODULE) {
        DLog(@"]]]]]]]] Free up contact controller...");
        [self.contactController cleanupData];
        self.contactController = nil;
        [self.modulesOpened removeObjectForKey:[NSNumber numberWithInt:CONTACT_MODULE]];

    } else if (moduleId == CALENDAR_MODULE) {
        DLog(@"]]]]]]]] Free up calendar controller...");
        [self.calendarController cleanupData];
        self.calendarController = nil;
        [self.modulesOpened removeObjectForKey:[NSNumber numberWithInt:CALENDAR_MODULE]];

    } else if (moduleId == DOC_MODULE) {
        DLog(@"]]]]]]]] Free up doc controller...");
        [self.docController cleanupData];
        self.docController = nil;
        [self.modulesOpened removeObjectForKey:[NSNumber numberWithInt:DOC_MODULE]];

    } else if (moduleId == PHOTO_MODULE) {
        DLog(@"]]]]]]]] Free up photo controller...");
        [self.photoController cleanupData];
        self.photoController = nil;
        [self.modulesOpened removeObjectForKey:[NSNumber numberWithInt:PHOTO_MODULE]];

    } else if (moduleId == BOOKMARK_MODULE) {
        DLog(@"]]]]]]]] Free up bookmark controller...");
        [self.bookmarkController cleanupData];
        self.bookmarkController = nil;
        [self.modulesOpened removeObjectForKey:[NSNumber numberWithInt:BOOKMARK_MODULE]];
    }
}

@end
