//
//  JournalViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntryService.h"
#import "LayoutConstants.h"
#import "NPJournal.h"
#import "InputDateSelectorView.h"
#import "DTNotePadView.h"
#import "NPScrollView.h"

@interface JournalViewController : UIViewController
                                                    <DateSelectedDelegate,
                                                    NPDataServiceDelegate,
                                                    UIGestureRecognizerDelegate,
                                                    DTNotePadViewDelegate,
                                                    NPScrollViewPageDataDelegate>

@property (nonatomic, strong) AccessEntitlement *accessInfo;

@property (nonatomic, strong) EntryService *entryService;

@property (strong, nonatomic) NPScrollView *journalScrollView;

- (IBAction)selectJournalDate:(id)sender;

@end
