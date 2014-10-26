//
//  EventListViewCell.h
//  nexusapp
//
//  Created by Ren Liu on 2/5/13.
//
//

#import <UIKit/UIKit.h>
#import "NPEvent.h"

@interface EventListViewCell : UITableViewCell

- (void)showEvent:(NPEvent*)evt;

@end
