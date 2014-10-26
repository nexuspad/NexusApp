//
//  DTNotePadView.m
//  Notepad
//
//  Created by Oliver Drobnik on 6/3/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "DTNotePadView.h"

#import "LinesView.h"
#import "VerticalLinesView.h"

@implementation DTNotePadView

@synthesize textView = _textView, delegate;

- (void)setup
{
	self.autoresizesSubviews = YES;
	self.clipsToBounds = YES;
	
	UIImage *topImage = [UIImage imageNamed:@"Notepaper_top.png"];
	UIImage *middleImage = [UIImage imageNamed:@"Notepaper_middle.png"];
	UIImage *bottomImage = [UIImage imageNamed:@"Notepaper_bottom.png"];
	
	
	topImageView = [[UIImageView alloc] initWithImage:topImage];
	middleImageView = [[UIImageView alloc] initWithImage:middleImage];
	bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
	
	topImageView.frame = CGRectMake(0, 0, self.bounds.size.width, topImageView.image.size.height);
	middleImageView.frame = CGRectMake(0, topImageView.image.size.height, self.bounds.size.width, self.bounds.size.height - topImageView.bounds.size.height - bottomImageView.bounds.size.height);
	bottomImageView.frame = CGRectMake(0, self.bounds.size.height - bottomImageView.image.size.height, self.bounds.size.width, bottomImageView.bounds.size.height);
	
	
	topImageView.contentMode = UIViewContentModeTopLeft;
	topImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	middleImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	middleImageView.contentMode = UIViewContentModeScaleToFill;
	[self addSubview:middleImageView];
	
	bottomImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	bottomImageView.contentMode = UIViewContentModeTopLeft;
	
	linesView = [[LinesView alloc] initWithFrame:CGRectZero];
	linesView.userInteractionEnabled = NO;
	linesView.contentMode = UIViewContentModeRedraw;
	//linesView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	
	[self addSubview:linesView];
	
	
	verticalLinesView = [[VerticalLinesView alloc] initWithFrame:CGRectZero];
	verticalLinesView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	verticalLinesView.opaque = NO;
	verticalLinesView.contentMode = UIViewContentModeRedraw;
	verticalLinesView.backgroundColor = [UIColor clearColor];
	[self addSubview:verticalLinesView];
	
	_textView = [[UITextView alloc] initWithFrame:CGRectMake(24.0, 8.0, middleImageView.bounds.size.width - 24.0, bottomImageView.frame.origin.y - 8.0)];
	_textView.contentInset = UIEdgeInsetsMake(8.0, 0, 0, 0);
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:_textView];
	
	
	_textView.delegate = self;
	_textView.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0];
	_textView.opaque = NO;
	_textView.backgroundColor = [UIColor clearColor];
	
	[_textView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
	
	[self addSubview:topImageView];
	[self addSubview:bottomImageView];
	
	[self scrollViewDidScroll:_textView];  // to line up initial lines with contentInset
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(liftMainViewWhenKeybordAppears:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnMainViewToInitialposition:) name:UIKeyboardWillHideNotification object:nil];
	
	
	verticalLinesView.frame = middleImageView.frame;
	linesView.frame = middleImageView.frame;
}


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		
		[self setup];
    }
    return self;
}

- (void)awakeFromNib
{
	[self setup];
}


- (void)dealloc 
{
	[_textView removeObserver:self forKeyPath:@"contentSize"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Scrolling
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGPoint offset = scrollView.contentOffset;
	linesView.transform = CGAffineTransformMakeTranslation(0, -offset.y);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	CGSize newSize = [[change objectForKey:@"new"] CGSizeValue];
	
	linesView.frame = CGRectMake(linesView.frame.origin.x, linesView.frame.origin.y, newSize.width + 124.0, newSize.height + self.bounds.size.height);
}

#pragma mark Keyboard
// http://stackoverflow.com/questions/1951826/move-up-uitoolbar	 

- (void) liftMainViewWhenKeybordAppears:(NSNotification*)aNotification{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
	
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
	//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
	//    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];  // < 3.2: UIKeyboardBoundsUserInfoKey
	//#else	
	//    [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];  // < 3.2: UIKeyboardBoundsUserInfoKey
	//#endif	
	
	NSString *osVersion = [[UIDevice currentDevice] systemVersion];
	if ([osVersion hasPrefix:@"3.1"])
	{
		[[userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] getValue: &keyboardFrame];
		CGPoint keyboardCenter;
		[[userInfo valueForKey:@"UIKeyboardCenterEndUserInfoKey"] getValue: &keyboardCenter];
		keyboardFrame = CGRectMake(keyboardFrame.origin.x, keyboardCenter.y - keyboardFrame.size.height/2, keyboardFrame.size.width, keyboardFrame.size.height);
	}
	else
	{
		// 3.2+
		[[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];			
	}
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
	
	// convert from window coords to view
	keyboardFrame = [self convertRect:keyboardFrame fromView:self.window];
	
	CGFloat visibleHeight = keyboardFrame.origin.y - _textView.frame.origin.y;
	
	CGRect textFrame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, visibleHeight);
    [self.textView setFrame:textFrame];
	
    [UIView commitAnimations];
}

- (void) returnMainViewToInitialposition:(NSNotification*)aNotification{
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
	//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_3_2
	//    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];  // < 3.2: UIKeyboardBoundsUserInfoKey
	//#else	
	//    [[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];  // < 3.2: UIKeyboardBoundsUserInfoKey
	//#endif	
	
	NSString *osVersion = [[UIDevice currentDevice] systemVersion];
	if ([osVersion hasPrefix:@"3.1"])
	{
		[[userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] getValue: &keyboardFrame];
		CGPoint keyboardCenter;
		[[userInfo valueForKey:@"UIKeyboardCenterEndUserInfoKey"] getValue: &keyboardCenter];
		keyboardFrame = CGRectMake(keyboardFrame.origin.x, keyboardCenter.y - keyboardFrame.size.height/2, keyboardFrame.size.width, keyboardFrame.size.height);
	}
	else
	{
		// 3.2+
		[[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];			
	}
	
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
	
	// convert from window coords to view
	keyboardFrame = [self convertRect:keyboardFrame fromView:self.window];

	// set to original frame
	_textView.frame = CGRectMake(24.0, 8.0, middleImageView.bounds.size.width - 24.0, bottomImageView.frame.origin.y - 8.0);

    [UIView commitAnimations];
}

#pragma mark textView

- (void)textViewDidChange:(UITextView *)textView
{
	if ([delegate respondsToSelector:@selector(notePadViewDidChange:)])
	{
		[delegate notePadViewDidChange:self];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([delegate respondsToSelector:@selector(notePadViewDidBeginEditing)]) {
        [delegate notePadViewDidBeginEditing];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if ([delegate respondsToSelector:@selector(notePadViewDidEndEditing:)])
	{
		[delegate notePadViewDidEndEditing:self];
	}
}

@end
