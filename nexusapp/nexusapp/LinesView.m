//
//  LinesView.m
//  iWoman
//
//  Created by Oliver Drobnik on 3/19/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "LinesView.h"


@implementation LinesView

- (id) initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.userInteractionEnabled = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	
	return self;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	UIColor *horizontalLineColor = [UIColor colorWithRed:166.0/255.0 green:166.0/255.0 blue:166.0/255.0 alpha:0.5];
	
	
	[horizontalLineColor set];
	
	CGFloat y = 34;
	
	CGContextSetShouldAntialias(ctx, NO);
	
	CGContextSetLineWidth(ctx, 0.5);
	
	while (y<self.bounds.size.height)
	{
		CGContextMoveToPoint(ctx, 0, y);
		CGContextAddLineToPoint(ctx, self.bounds.size.width, y);
		CGContextStrokePath(ctx);
		
		y+=22.0;
	}
}

@end
