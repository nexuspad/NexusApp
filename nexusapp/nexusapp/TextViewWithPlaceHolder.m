//
//  TextViewWithPlaceHolder.m
//  nexuspad
//
//  Created by Ren Liu on 7/29/12.
//
//

#import "TextViewWithPlaceHolder.h"
#import "ViewDisplayHelper.h"
#import "UIColor+NPColor.h"
#import "UIBarButtonItem+NPUtil.h"


@interface TextViewWithPlaceHolder()
@property (nonatomic, strong) NSString *realText;

- (void)beginEditing:(NSNotification*) notification;
- (void)endEditing:(NSNotification*) notification;
@end


@implementation TextViewWithPlaceHolder

@synthesize realText;
@synthesize placeholder;

#pragma mark -
#pragma mark Initialisation

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self awakeFromNib];
    }
    return self;
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginEditing:) name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditing:) name:UITextViewTextDidEndEditingNotification object:self];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [ViewDisplayHelper screenWidth], 32)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    
    UIBarButtonItem *closeItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"arrow-down-black.png"]
                                                            target:self
                                                            action:@selector(doneText:)];

    [toolbar setItems:[NSArray arrayWithObjects:flexibleSpace, closeItem, nil] animated:NO];
    self.inputAccessoryView = toolbar;
    
    self.contentInset = UIEdgeInsetsMake(0, -4, 0, 0);
}

- (void)doneText:(id)sender {
    [self resignFirstResponder];
}

#pragma mark -
#pragma mark Setter/Getters

- (NSString*)text {
    NSString* text = [super text];
    if ([text isEqualToString:self.placeholder]) return nil;
    return text;
}

- (void)setText:(NSString *)text {
    if ([text isEqualToString:@""] || text == nil) {
        super.text = self.placeholder;
    } else {
        super.text = text;
        self.realText = text;
    }

    if ([super.text isEqualToString:self.placeholder]) {
        self.textColor = [UIColor npLightGrey];
    } else {
        self.textColor = [UIColor blackColor];
    }
}

- (void)beginEditing:(NSNotification*)notification {
    if ([super.text isEqualToString:self.placeholder]) {
        super.text = nil;
        self.textColor = [UIColor blackColor];
    }
}

- (void)endEditing:(NSNotification*)notification {
    if ([super.text isEqualToString:@""] || self.text == nil) {
        super.text = self.placeholder;
        self.textColor = [UIColor npLightGrey];
    }
}


@end
