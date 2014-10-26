//
//  DayEventView.h
//  nexuspad
//
//  Created by Ren Liu on 7/31/12.
//
//

#import <UIKit/UIKit.h>
#import "NPEvent.h"

@interface EventHourGridView : UIView

@property (nonatomic, strong) NPEvent* event;

- (id)initWithFrameAndEvent:(CGRect)frame event:(NPEvent*)event;

@end
