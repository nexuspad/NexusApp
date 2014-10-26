//
//  SlideMenuViewController.m
//  nexusapp
//
//  Created by Ren Liu on 11/30/13.
//
//

#import "SlideMenu.h"
#import "BaseEntryListViewController.h"

#define MENU_IMAGE @"menu-button"

@interface SlideMenu ()
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, assign) CGPoint draggingPoint;
@property (nonatomic, strong) UIPanGestureRecognizer *menuPanRecognizer;
@end

@implementation SlideMenu
@synthesize tapRecognizer = _tapRecognizer, panRecognizer = _panRecognizer, draggingPoint = _draggingPoint, menuPanRecognizer = _menuPanRecognizer;

- (UIView*)navigationView {
    BaseEntryListViewController *parentViewController = (BaseEntryListViewController*)self.menuDelegate;
    return parentViewController.navigationController.view;
}


- (void)selectedMenu:(Menu)menu withCompletion:(void (^)())completion {
	if ([self isMenuOpen]) {
		[self closeMenuWithCompletion:nil];

	} else {
        [self openMenu:menu withDuration:MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
    }
}

- (void)closeMenuWithCompletion:(void (^)())completion {
	[self closeMenuWithDuration:MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
}

- (void)clearMenu {
	[self.navigationView removeGestureRecognizer:self.tapRecognizer];
    [self.navigationView removeGestureRecognizer:self.panRecognizer];
    [self.menuView removeFromSuperview];
    [self.menuView removeGestureRecognizer:self.menuPanRecognizer];
    [self.menuView removeFromSuperview];
}


- (void)openMenu:(Menu)menu withDuration:(float)duration andCompletion:(void (^)())completion {
	[self.navigationView addGestureRecognizer:self.tapRecognizer];
    [self.navigationView addGestureRecognizer:self.panRecognizer];
    [self.menuView addGestureRecognizer:self.menuPanRecognizer];
	
    if ([self isPortrait]) {
        CGRect rect = CGRectMake(MENU_OFFSET, 20.0, [ViewDisplayHelper screenWidth] - MENU_OFFSET, [ViewDisplayHelper screenHeight]);
        self.menuView.frame = rect;

    } else if ([self isLandscapeRight]) {
        float menuSize = [ViewDisplayHelper screenHeight];
        CGRect rect = CGRectMake(0, [ViewDisplayHelper screenWidth] - menuSize, menuSize, menuSize);
        self.menuView.frame = rect;
        self.menuView.transform = CGAffineTransformMakeRotation(M_PI_2);

    } else {
        float menuSize = [ViewDisplayHelper screenHeight];
        CGRect rect = CGRectMake(20, 0, menuSize, menuSize);
        self.menuView.frame = rect;
        self.menuView.transform = CGAffineTransformMakeRotation(M_PI + M_PI_2);
    }
    
    [self.navigationView.window insertSubview:self.menuView atIndex:0];

    
    // Base on the menu location, slide away the navigationView
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
                         
                         if ([self isPortrait]) {
                             CGRect rect = self.navigationView.frame;
                             rect.origin.x = (menu == MenuLeft) ? (rect.size.width - MENU_OFFSET) : ((rect.size.width - MENU_OFFSET )* -1);
                             self.navigationView.frame = rect;

                         } else {
                             CGRect rect = self.navigationView.frame;
                             rect.origin.y = [self menuOffsetLandscape];
                             self.navigationView.frame = rect;
                             
                         }
					 }
					 completion:^(BOOL finished) {
						 if (completion)
							 completion();
					 }];
}

- (void)closeMenuWithDuration:(float)duration andCompletion:(void (^)())completion {
	[self.navigationView removeGestureRecognizer:self.tapRecognizer];
    [self.navigationView removeGestureRecognizer:self.panRecognizer];
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
                         
                         if ([self isPortrait]) {
                             CGRect rect = self.navigationView.frame;
                             rect.origin.x = 0;
                             self.navigationView.frame = rect;

                         } else {
                             CGRect rect = self.navigationView.frame;
                             rect.origin.y = 0;
                             self.navigationView.frame = rect;
                             
                         }
					 }
					 completion:^(BOOL finished) {
						 if (completion)
							 completion();
					 }];
}

- (BOOL)isMenuOpen {
    if ([self isPortrait]) {
        return (self.navigationView.frame.origin.x == 0) ? NO : YES;
    } else {
        return (self.navigationView.frame.origin.y == 0) ? NO : YES;
    }
}

#pragma mark - Gesture Recognizing -

- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer {
	[self closeMenuWithCompletion:nil];
}

- (void)viewPanDetected:(UIPanGestureRecognizer *)aPanRecognizer {
	static NSInteger velocityForFollowingDirection = 1000;
	
	CGPoint translation = [aPanRecognizer translationInView:aPanRecognizer.view];
    CGPoint velocity = [aPanRecognizer velocityInView:aPanRecognizer.view];
	
    if (aPanRecognizer.state == UIGestureRecognizerStateBegan) {
		self.draggingPoint = translation;

    } else if (aPanRecognizer.state == UIGestureRecognizerStateChanged) {
        if ([self isPortrait]) {
            NSInteger movement = translation.x - self.draggingPoint.x;
            CGRect rect = self.navigationView.frame;
            rect.origin.x += movement;
            
            if (rect.origin.x >= self.minXForDragging && rect.origin.x <= self.maxXForDragging)
                self.navigationView.frame = rect;
            
            self.draggingPoint = translation;
            
        } else {
            NSInteger movement = translation.y - self.draggingPoint.y;
            CGRect rect = self.navigationView.frame;
            rect.origin.y += movement;
            
            if (rect.origin.y >= self.minXForDragging && rect.origin.y <= self.maxXForDragging)
                self.navigationView.frame = rect;
            
            self.draggingPoint = translation;
        }

	} else if (aPanRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self isPortrait]) {
            NSInteger currentX = self.navigationView.frame.origin.x;
            NSInteger currentXOffset = (currentX > 0) ? currentX : currentX * -1;
            NSInteger positiveVelocity = (velocity.x > 0) ? velocity.x : velocity.x * -1;
            
            // If the speed is high enough follow direction
            if (positiveVelocity >= velocityForFollowingDirection) {
                // Moving Right
                if (velocity.x > 0)
                {
                    if (currentX > 0) {
                        [self selectedMenu:(velocity.x > 0) ? MenuLeft : MenuRight withCompletion:nil];
                    } else {
                        [self closeMenuWithDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
                    }
                }
                // Moving Left
                else
                {
                    if (currentX > 0) {
                        [self closeMenuWithCompletion:nil];
                    } else {
                        [self openMenu:(velocity.x > 0) ? MenuLeft : MenuRight withDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
                    }
                }
            } else {
                if (currentXOffset < self.navigationView.frame.size.width/2)
                    [self closeMenuWithCompletion:nil];
                else
                    [self selectedMenu:(currentX > 0) ? MenuLeft : MenuRight withCompletion:nil];
            }
            
        } else {
            NSInteger currentY = self.navigationView.frame.origin.y;
            NSInteger currentYOffset = (currentY > 0) ? currentY : currentY * -1;
            NSInteger positiveVelocity = (velocity.y > 0) ? velocity.y : velocity.y * -1;
            
            // If the speed is high enough follow direction
            if (positiveVelocity >= velocityForFollowingDirection) {
                // Moving "Down", which is left in Landscape mode
                if (velocity.y > 0)
                {
                    if (currentY > 0) {
                        [self selectedMenu:(velocity.y > 0) ? MenuLeft : MenuRight withCompletion:nil];
                    } else {
                        [self closeMenuWithDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
                    }
                }
                // Moving Left
                else
                {
                    if (currentY > 0) {
                        [self closeMenuWithCompletion:nil];
                    } else {
                        [self openMenu:(velocity.x > 0) ? MenuLeft : MenuRight withDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
                    }
                }
            } else {
                if (currentYOffset < self.navigationView.frame.size.height/2)
                    [self closeMenuWithCompletion:nil];
                else
                    [self selectedMenu:(currentY > 0) ? MenuLeft : MenuRight withCompletion:nil];
            }
        }
    }
}


- (NSInteger)minXForDragging {
    return (self.navigationView.frame.size.width - MENU_OFFSET)  * -1;
}

- (NSInteger)maxXForDragging {
    return self.navigationView.frame.size.width - MENU_OFFSET;
}

#pragma mark - Setter & Getter -

- (UITapGestureRecognizer *)tapRecognizer {
	if (!_tapRecognizer) {
		_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
	}
	
	return _tapRecognizer;
}

- (UIPanGestureRecognizer *)panRecognizer {
	if (!_panRecognizer) {
		_panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanDetected:)];
	}
	
	return _panRecognizer;
}

- (UIPanGestureRecognizer *)menuPanRecognizer {
	if (!_menuPanRecognizer) {
		_menuPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanDetected:)];
	}
	
	return _menuPanRecognizer;
}


- (BOOL)isPortrait {
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
        return YES;
    
    return NO;
}

- (BOOL)isLandscapeRight {
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES;
    }
    return NO;
}

- (float)menuOffsetLandscape {
    if ([self isLandscapeRight]) {
        return [ViewDisplayHelper screenHeight] * -1;
    }
    return [ViewDisplayHelper screenHeight];
}

@end
