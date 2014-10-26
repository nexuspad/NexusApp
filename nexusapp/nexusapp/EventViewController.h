//
//  EventViewController.h
//  nexuspad
//
//  Created by Ren Liu on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntryDetailTableViewController.h"
#import "NPEvent.h"
#import "NoteCell.h"
#import "EventService.h"

@interface EventViewController : EntryDetailTableViewController

@property (nonatomic, strong) EventService *eventService;

@property (nonatomic, strong) NPEvent *event;


@end
