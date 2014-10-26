//
//  SlideMenuViewController.h
//  nexusapp
//
//  Created by Ren Liu on 11/30/13.
//
//

#import <UIKit/UIKit.h>
#import "NPUser.h"

#define MENU_OFFSET 60
#define MENU_SLIDE_ANIMATION_DURATION .3
#define MENU_QUICK_SLIDE_ANIMATION_DURATION .1

typedef enum {
	MenuLeft,
	MenuRight,
} Menu;

@protocol SlideMenuDelegate <NSObject>
- (void)didSelectedSharer:(NPUser*)sharer;
@end

@interface SlideMenu : NSObject

@property (nonatomic, weak) id<SlideMenuDelegate> menuDelegate;

@property (nonatomic, strong) UIView *menuView;

@property Boolean isLandscape;

- (BOOL)isMenuOpen;

- (void)selectedMenu:(Menu)menu withCompletion:(void (^)())completion;
- (void)closeMenuWithCompletion:(void (^)())completion;

// Clear the menu out of navigation controller view. Usually called in viewWillDisappear
- (void)clearMenu;

@end
