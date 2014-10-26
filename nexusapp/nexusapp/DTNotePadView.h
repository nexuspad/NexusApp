//
//  DTNotePadView.h
//  Notepad
//
//  Created by Oliver Drobnik on 6/3/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LinesView, VerticalLinesView, DTNotePadView;

@protocol DTNotePadViewDelegate <NSObject>

@optional
- (void)notePadViewDidChange:(DTNotePadView *)notePadView;
- (void)notePadViewDidBeginEditing;
- (void)notePadViewDidEndEditing:(DTNotePadView *)notePadView;

@end



@interface DTNotePadView : UIView  <UITextViewDelegate, UIScrollViewDelegate>
{
	UITextView *_textView;
	LinesView *linesView;
	VerticalLinesView *verticalLinesView;
	
	UIImageView *topImageView;
	UIImageView *middleImageView;
	UIImageView *bottomImageView;	
}

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, assign) id <DTNotePadViewDelegate> delegate;


@end
