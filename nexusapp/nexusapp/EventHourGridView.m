//
//  DayEventView.m
//  nexuspad
//
//  Created by Ren Liu on 7/31/12.
//
//

#import "EventHourGridView.h"
#import "DateUtil.h"
#import "ViewDisplayHelper.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+NPColor.h"

@implementation EventHourGridView

@synthesize event = _event;

- (id)initWithFrameAndEvent:(CGRect)frame event:(NPEvent*)anEvent
{
    self = [super initWithFrame:frame];

    if (self) {
        NSString *evtTitle = nil;
        if (anEvent.allDayEvent) {
            evtTitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"All day",), anEvent.title];
        } else if (anEvent.singleTimeEvent) {
            evtTitle = [NSString stringWithFormat:@"%@ %@", [anEvent eventDisplayTime], anEvent.title];
        } else {
            evtTitle = [NSString stringWithFormat:@"%@", anEvent.title];
        }
        
        UIColor *eventBgColor = [[UIColor colorFromHexString:anEvent.colorLabel] colorWithAlphaComponent:0.65];
        
        self.backgroundColor = eventBgColor;
        self.layer.borderColor = [[UIColor colorFromHexString:anEvent.colorLabel] colorWithAlphaComponent:0.85].CGColor;
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        
        CGRect labelRect = CGRectMake(4.0, 4.0, frame.size.width, 15.0);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:labelRect];
        titleLabel.text = evtTitle;
        titleLabel.font = [UIFont systemFontOfSize:12.0];
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor textColorFromBackground:eventBgColor];
        
        [self addSubview:titleLabel];
    }
    
    self.event = [anEvent copy];

    return self;
}

@end
