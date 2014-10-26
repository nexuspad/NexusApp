//
//  InputDateSelectorView.m
//  nexuspad
//
//  Created by Ren Liu on 7/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InputDateSelectorView.h"
#import "ViewDisplayHelper.h"
#import "UIColor+NPColor.h"
#import "UIBarButtonItem+NPUtil.h"

static float TOOLBAR_HEIGHT = 32.0;

@interface InputDateSelectorView ()
@property BOOL asInputView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) TKCalendarMonthView *tkDatePickerView;
@property (nonatomic, strong) UIView *parentView;
@end

@implementation InputDateSelectorView

@synthesize delegate;

// The date picker is just created and presented by others like using presentSemiView.
- (id)init:(UIView*)parentView asInputView:(BOOL)asInputView {
    self = [super init];
    
    self.asInputView = asInputView;
    self.parentView = parentView;
    
    // Add date picker
    self.tkDatePickerView = [[TKCalendarMonthView alloc] init];
    self.tkDatePickerView.delegate = self;
    [self addSubview:self.tkDatePickerView];

    self.frame = self.tkDatePickerView.frame;

    return self;
}

// The date picker is created and presented by itself.
- (id)initWithToolBar:(UIView*)parentView asInputView:(BOOL)asInputView {
    self = [super init];
    
    self.asInputView = asInputView;
    self.parentView = parentView;
    
    // Create a toolbar on top
    self.toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.0, 0.0, [ViewDisplayHelper screenWidth], TOOLBAR_HEIGHT)];

    // Transparent toolbar
    [self.toolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIBarPositionAny
                          barMetrics:UIBarMetricsDefault];

    [self.toolbar setShadowImage:[UIImage new]
              forToolbarPosition:UIToolbarPositionAny];
    
    [self.toolbar setBarStyle:UIBarStyleDefault];
    self.toolbar.translucent = YES;
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
    UIBarButtonItem *closeItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"arrow-down-black.png"]
                                                            target:self
                                                            action:@selector(cancel)];


    NSMutableArray* toolbarItems = [NSMutableArray array];

    [toolbarItems addObject:spacer];
    [toolbarItems addObject:closeItem];
    self.toolbar.items = toolbarItems;
    [self addSubview:self.toolbar];
    
    // Add date picker    
    self.tkDatePickerView = [[TKCalendarMonthView alloc] init];
    self.tkDatePickerView.delegate = self;
    [self addSubview:self.tkDatePickerView];
    
    CGRect offScreen = CGRectMake(0.0f, [ViewDisplayHelper offsetYPosition], [ViewDisplayHelper screenWidth], 348.0f);
    offScreen.size.height = TOOLBAR_HEIGHT + self.tkDatePickerView.frame.size.height;
    
    self.frame = offScreen;

    [self slideIn];

    return self;
}

- (void)selectDate:(NSDate*)date {
    [self.tkDatePickerView selectDate:date];
}

- (void)cancel {
    if (self.asInputView) {
        [self.parentView endEditing:YES];
    } else {
        [self slideOff];
        if ([self.delegate respondsToSelector:@selector(inputDateSelectorCancelled)]) {
            [self.delegate inputDateSelectorCancelled];
        }
    }
}

- (void)slideOff {
    self.isVisible = NO;
    
    CGRect offScreen = self.frame;
    offScreen.origin.y = [ViewDisplayHelper offsetYPosition];
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.4];
    [self setFrame:offScreen];
    [UIView commitAnimations];
}

- (void)slideIn {
    self.isVisible = YES;
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.5];

    [self.parentView bringSubviewToFront:self];

    float yPos = self.parentView.frame.size.height - self.frame.size.height;
    self.frame = CGRectMake(0.0f, yPos, [ViewDisplayHelper screenWidth], self.frame.size.height);

    // center the datepicker
    CGSize size = self.frame.size;
    [self.tkDatePickerView setCenter:CGPointMake(size.width/2, size.height/2 + TOOLBAR_HEIGHT/2)];
    
    [UIView commitAnimations];
}


#pragma mark TKCalendarMonthViewDelegate

// Make sure the self view height is adjusted according to the tkDatePickerView. Otherwise, the bottom row is hidden beneath the screen.
- (void)calendarMonthView:(TKCalendarMonthView *)monthView monthDidChange:(NSDate *)month animated:(BOOL)animated {
    CGRect rect = self.frame;
    
    if (self.toolbar != nil) {
        rect.size.height = TOOLBAR_HEIGHT + self.tkDatePickerView.frame.size.height;
    } else {
        rect.size.height = self.tkDatePickerView.frame.size.height;
    }

    if (!self.asInputView) {
        float yPos = self.parentView.frame.size.height - rect.size.height;
        rect.origin.y = yPos;
    }

    self.frame = rect;
}

- (void)calendarMonthView:(TKCalendarMonthView*)monthView didSelectDate:(NSDate*)date {    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *selectedYmd = [dateFormatter stringFromDate:date];
    
    [self.delegate didSelectedDate:selectedYmd];
}

+ (CGSize)getInputViewSize {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGSizeMake(320.0, 260.0);
    }
    
    return CGSizeMake(320.0, 260.0);
}

@end
