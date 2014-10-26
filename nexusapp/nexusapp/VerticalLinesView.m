//
//  VerticalLinesView.m
//  iWoman
//
//  Created by Oliver Drobnik on 3/19/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "VerticalLinesView.h"


@implementation VerticalLinesView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	UIColor *verticalLineColor = [UIColor colorWithRed:169.0/255.0 green:130.0/255.0 blue:89.0/255.0 alpha:0.9];
	
	CGContextSetShouldAntialias(ctx, NO);
	
	CGContextSetLineWidth(ctx, 1.0);

	
	[verticalLineColor set];
	
	CGContextMoveToPoint(ctx, 21, 0);
	CGContextAddLineToPoint(ctx, 21, self.bounds.size.height);
	CGContextStrokePath(ctx);
	
	CGContextMoveToPoint(ctx, 23, 0);
	CGContextAddLineToPoint(ctx, 23, self.bounds.size.height);
	CGContextStrokePath(ctx);
}

@end
