//
//  EventService.h
//  NexusAppCore
//
//  Created by Ren Liu on 8/2/13.
//  Copyright (c) 2013 Ren Liu. All rights reserved.
//

#import "EntryService.h"
#import "NPEvent.h"

@interface EventService : EntryService

- (void)getEventDetail:(NPEvent*)event;
- (void)addOrUpdateEvent:(NPEvent*)event;
- (void)deleteEvent:(NPEvent*)event;

@end
