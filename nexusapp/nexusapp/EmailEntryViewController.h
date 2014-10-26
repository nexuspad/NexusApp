//
//  EmailEntryViewController.h
//  nexuspad
//
//  Created by Ren Liu on 9/9/12.
//
//

#import <UIKit/UIKit.h>
#import "NPEntry.h"
#import "EntryService.h"
#import "EntryViewInfoDelegate.h"

@interface EmailEntryViewController : UITableViewController <UITextFieldDelegate, NPDataServiceDelegate>

@property (nonatomic, strong) NPEntry *theEntry;

@property (nonatomic, strong) id<EntryViewInfoDelegate> promptDelegate;

@end
