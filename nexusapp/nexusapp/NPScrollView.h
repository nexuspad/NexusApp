//
//  NPScrollView.h
//  nexusapp
//
//  Created by Ren Liu on 8/17/13.
//
//

#import <UIKit/UIKit.h>
#import "CoreSettings.h"

@protocol NPScrollViewPageDataDelegate <NSObject>
- (id)getLeftPageView:(NSInteger)currentIndex;
- (id)getRightPageView:(NSInteger)currentIndex;
@end


@interface NPScrollView : UIScrollView <UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, weak) id<NPScrollViewPageDataDelegate> dataDelegate;

- (id)initWithOnePage:(CGRect)frame pageView:(UIView*)pageView backgroundColor:(UIColor*)backgroundColor;
- (id)initWithTwoPages:(CGRect)frame pageViews:(NSMutableArray*)pageViews startingIndex:(NSInteger)startingIndex backgroundColor:(UIColor*)backgroundColor;
- (id)initWithPageViews:(CGRect)frame pageViews:(NSMutableArray*)pageViews startingIndex:(NSInteger)startingIndex backgroundColor:(UIColor*)backgroundColor;

- (UIView*)activePage;

- (void)changeOrientation;

@end
