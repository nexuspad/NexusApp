//
//  MessageView.m
//  nexusapp
//
//  Created by Ren Liu on 2/5/13.
//
//

#import "MessageView.h"

@implementation MessageView

- (id)initWithMessage:(NSString*)messageText messageImage:(UIImage*)image viewTag:(int)viewTag
{    
    self = [super init];

    self.tag = viewTag;
    self.backgroundColor = [UIColor whiteColor];
    
    self.multipleTouchEnabled = YES;
    self.scrollEnabled = YES;
    self.directionalLockEnabled = YES;
    self.canCancelContentTouches = YES;
    self.delaysContentTouches = YES;
    self.clipsToBounds = YES;
    self.alwaysBounceVertical = YES;
    self.bounces = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;

    UILabel *viewMessageLabel = [[UILabel alloc] init];

    [viewMessageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    viewMessageLabel.textAlignment = NSTextAlignmentCenter;
    viewMessageLabel.font = [UIFont boldSystemFontOfSize:18];
    viewMessageLabel.textColor = [UIColor lightGrayColor];
    viewMessageLabel.text = messageText;
    viewMessageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    viewMessageLabel.numberOfLines = 0;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.backgroundColor = [UIColor redColor];
    [wrapperView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [wrapperView addSubview:viewMessageLabel];
    [wrapperView addSubview:imageView];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(viewMessageLabel, imageView);
    
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:|[imageView][viewMessageLabel]"
                            options:NSLayoutFormatAlignAllCenterX
                            metrics:nil
                            views:viewsDictionary];
    
    [wrapperView addConstraints:constraints];
    
    [wrapperView layoutIfNeeded];

    [self addSubview:wrapperView];
    
    [self layoutIfNeeded];

    float xOffset = viewMessageLabel.frame.size.width / 2;
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:wrapperView
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.f constant:-xOffset];
    
    [self addConstraint:c];
    
    c = [NSLayoutConstraint constraintWithItem:wrapperView
                                     attribute:NSLayoutAttributeCenterY
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeCenterY
                                    multiplier:1.f constant:-50.f];
    
    [self addConstraint:c];

    
//    UIView *superview = self;
//
//    NSDictionary *variables = NSDictionaryOfVariableBindings(wrapperView, superview);
//    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[wrapperView]"
//                                                                        options: NSLayoutFormatAlignAllCenterX
//                                                                        metrics:nil
//                                                                        views:variables];
//    
//    [self addConstraints:constraints];
//
//    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[wrapperView]"
//                                                                   options: NSLayoutFormatAlignAllCenterY
//                                                                   metrics:nil
//                                                                     views:variables];
//    
//    [self addConstraints:constraints];
    
//    UIView *superview = self;
//
//    NSDictionary *variables = NSDictionaryOfVariableBindings(viewMessageLabel, superview);
//    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[viewMessageLabel]"
//                                                                    options: NSLayoutFormatAlignAllCenterX
//                                                                    metrics:nil
//                                                                    views:variables];
//    
//    [self addConstraints:constraints];
//    
//    constraints =
//    [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[viewMessageLabel]"
//                                            options: NSLayoutFormatAlignAllCenterY
//                                            metrics:nil
//                                              views:variables];
//    [self addConstraints:constraints];
//    
//    variables = NSDictionaryOfVariableBindings(imageView, superview);
//    constraints =
//    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[imageView]"
//                                            options: NSLayoutFormatAlignAllCenterX
//                                            metrics:nil
//                                              views:variables];
//    
//    [self addConstraints:constraints];
//    
//    constraints =
//    [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[imageView]"
//                                            options: NSLayoutFormatAlignAllCenterY
//                                            metrics:nil
//                                              views:variables];
//    [self addConstraints:constraints];
    
    return self;
}

@end
