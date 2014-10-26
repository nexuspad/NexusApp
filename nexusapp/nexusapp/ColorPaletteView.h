//
//  ColorPaletteView.h
//  nexuspad
//
//  Created by Ren Liu on 9/13/12.
//
//

#import <UIKit/UIKit.h>
#import "InputValueSelectedDelegate.h"
#import "ColorTile.h"

@interface ColorPaletteView : UIView <UIGestureRecognizerDelegate>

- (id)initWithToolBar:(UIView*)parentView;

- (void)slideOff;
- (void)slideIn:(UIView*)parentView;

@property BOOL isVisible;
@property (nonatomic, weak) id<InputValueSelectedDelegate> delegate;

@end
