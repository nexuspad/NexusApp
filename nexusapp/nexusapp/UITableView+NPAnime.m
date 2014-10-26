//
//  UITableView+NPAnime.m
//  nexusapp
//
//  Created by Ren Liu on 9/4/13.
//
//

#import "UITableView+NPAnime.h"

@implementation UITableView (NPAnime)

- (void)reloadData:(BOOL)animated
{
    [self reloadData];
    
    if (animated) {
        
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromBottom];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setFillMode:kCAFillModeBoth];
        [animation setDuration:.3];
        [[self layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
        
    }
}

@end
