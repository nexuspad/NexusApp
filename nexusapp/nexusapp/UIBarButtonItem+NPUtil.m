//
//  UIBarButtonItem+ImageButton.m
//  nexuspad
//
//  Created by Ren Liu on 9/1/12.
//
//

#import "UIBarButtonItem+NPUtil.h"
#import "KHFlatButton.h"
#import "UIColor+NPColor.h"

NSString* const TOOLBAR_ITEM_MOVE_ENTRY         = @"11";
NSString* const TOOLBAR_ITEM_FAVORITE_ENTRY     = @"14";
NSString* const TOOLBAR_ITEM_EMAIL_ENTRY        = @"12";
NSString* const TOOLBAR_ITEM_DELETE_ENTRY       = @"13";

@implementation UIBarButtonItem (NPUtil)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image target:(id)target action:(SEL)action
{
    UIButton *baseButn = [UIButton buttonWithType:UIButtonTypeCustom];

    [baseButn setFrame:CGRectMake(0.0f, 0.0f, image.size.width, image.size.height)];
    baseButn.showsTouchWhenHighlighted = YES;
    [baseButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [baseButn setImage:image forState:UIControlStateNormal];

    return [[UIBarButtonItem alloc] initWithCustomView:baseButn];
}

+ (UIBarButtonItem*)richEditorToolbarButton:(UIImage*)image target:(id)target action:(SEL)action
{
    UIButton *baseButn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [baseButn setFrame:CGRectMake(0.0f, 0.0f, 32, 32)];
    
    [baseButn.layer setCornerRadius:4.0f];
    [baseButn.layer setMasksToBounds:YES];
    [baseButn.layer setBorderWidth:1.0f];
    [baseButn.layer setBorderColor:[[UIColor lightBlue] CGColor]];
//    baseButn.backgroundColor = [UIColor redColor];
    
    baseButn.showsTouchWhenHighlighted = YES;
    
    [baseButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    //[baseButn addTarget:target action:action forControlEvents:UIControlEventTouchDown];

    [baseButn setImage:image forState:UIControlStateNormal];
        
    return [[UIBarButtonItem alloc] initWithCustomView:baseButn];
}

+ (UIBarButtonItem*)refreshButton:(id)target action:(SEL)action
{
    UIBarButtonItem *dashboardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:target action:action];
    dashboardButton.tag = 888;
    
    return dashboardButton;
}

+ (UIBarButtonItem*)dashboardButton:(id)target action:(SEL)action;
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-to-dashboard.png"] style:UIBarButtonItemStylePlain target:target action:action];
}

+ (UIBarButtonItem*)dashboardButtonPlain:(id)target action:(SEL)action;
{
    UIButton *baseButn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [baseButn setFrame:CGRectMake(0.0f, 0.0f, 40.0, 40)];
    
    baseButn.showsTouchWhenHighlighted = YES;
    [baseButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"back-to-dashboard.png"]];
    [baseButn addSubview:imageView];
    
    imageView.autoresizingMask = UIViewAutoresizingNone;
    imageView.contentMode = UIViewContentModeCenter;
    imageView.center = baseButn.center;

    UIBarButtonItem *dashboardButton = [[UIBarButtonItem alloc] initWithCustomView:baseButn];
    dashboardButton.tag = 999;
    
    return dashboardButton;
}

+ (UIBarButtonItem*)goToParentFolderButton:(id)target action:(SEL)action parentFolder:(NSString*)parentFolder {
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"go-up.png"] forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0.0, 0.0, 175.0, 31)];

    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(24.0, 5, 150, 20)];
    [label setText:parentFolder];
    label.textAlignment = NSTextAlignmentLeft;
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [button addSubview:label];

    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    UIBarButtonItem *barButton= [[UIBarButtonItem alloc] initWithCustomView:button];
                                 
    return barButton;
}

+ (UIBarButtonItem*)goBackButton:(id)target action:(SEL)action
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"] style:UIBarButtonItemStylePlain target:target action:action];
    backButton.title = @"GO back";
    return backButton;
    
//    UIImage *image = [UIImage imageNamed:@"backbutton.png"];
//    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//    [button setBackgroundImage:[image stretchableImageWithLeftCapWidth:25 topCapHeight:0] forState:UIControlStateNormal];
//    [button setTitle:@"GO back" forState:UIControlStateNormal];
//    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
//    [button.titleLabel setFont:font];
//    [button.titleLabel setShadowColor:[UIColor whiteColor]];
//    [button.titleLabel setShadowOffset:CGSizeMake(0, 1)];
//    CGSize size = [button.titleLabel.text sizeWithFont:font];
//    float titleWidth = size.width;
//    //Add 15 to the width for a left-right buffer
//    [button setFrame:CGRectMake(0.0, 0.0, titleWidth+15, image.size.height)];
//    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
//    
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
//
//    return backButton;
}


+ (UIBarButtonItem*)khFlatButton:(id)target action:(SEL)action title:(NSString*)title rect:(CGRect)rect backgroundColor:(UIColor*)backgroundColor
{
    KHFlatButton *khButn = [KHFlatButton buttonWithFrame:rect withTitle:title backgroundColor:backgroundColor];
    [khButn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return [[UIBarButtonItem alloc] initWithCustomView:khButn];
}


+ (UIBarButtonItem*)spacer {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                         target:nil
                                                         action:nil];
}

@end
