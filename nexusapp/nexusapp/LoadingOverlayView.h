//
//  LoadingOverlayController.h
//  nexuspad
//
//  Created by Ren Liu on 5/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingOverlayView : UIView

@property BOOL isPortrait;

@property (nonatomic, strong) UILabel* loadingLabel;
@property (nonatomic, strong) UIActivityIndicatorView* loadingIndicator;

- (void)show:(UIView*)containerView;

@end
