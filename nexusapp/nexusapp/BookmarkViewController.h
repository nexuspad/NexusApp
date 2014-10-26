//
//  BookmarkViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryDetailTableViewController.h"
#import "NPBookmark.h"
#import "NoteCell.h"

@interface BookmarkViewController : EntryDetailTableViewController

@property (nonatomic, strong) NPBookmark *bookmark;

@end
