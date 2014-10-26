//
//  LoadingOverlayController.m
//  nexuspad
//
//  Created by Ren Liu on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoadingOverlayView.h"
#import <QuartzCore/QuartzCore.h>

@interface LoadingOverlayView()
@end

@implementation LoadingOverlayView

@synthesize loadingIndicator = _loadingIndicator;

- (id)init
{
    self = [super init];
    
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        self.loadingIndicator = [[UIActivityIndicatorView alloc] init];
        
        self.loadingIndicator.frame = CGRectMake(0, 0, 40, 40);

        self.loadingIndicator.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5f];
        self.loadingIndicator.clipsToBounds = NO;
        
        self.loadingIndicator.layer.cornerRadius = 4;
        self.loadingIndicator.layer.masksToBounds = NO;

        [self addSubview:self.loadingIndicator];
    }
    
    return self;
}

- (void)show:(UIView*)containerView {
    [self.loadingIndicator startAnimating];

//
// Cannot use auto layout here because translatesAutoresizingMaskIntoConstraints has to be set to NO
// And when adding this view to a UITableView, we get Assertion failure in -[UITableView layoutSublayersOfLayer:]
//

//    self.translatesAutoresizingMaskIntoConstraints = NO;
//    NSLayoutConstraint *cx = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
//    [containerView addConstraint:cx];
//    NSLayoutConstraint *cy = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
//    [containerView addConstraint:cy];

    float dx = (containerView.bounds.size.width - 40.0)/2;
    float dy = (containerView.bounds.size.height -  40.0)/2;    
    CGRect viewRect = CGRectMake(dx, dy, 40.0, 40.0);
    self.frame = viewRect;
    
    [containerView addSubview:self];
}

@end
