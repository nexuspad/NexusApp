//
//  UIBarButtonItem+ImageButton.h
//  nexuspad
//
//  Created by Ren Liu on 9/1/12.
//
//

#import <UIKit/UIKit.h>

extern NSString* const TOOLBAR_ITEM_MOVE_ENTRY;
extern NSString* const TOOLBAR_ITEM_FAVORITE_ENTRY;
extern NSString* const TOOLBAR_ITEM_EMAIL_ENTRY;
extern NSString* const TOOLBAR_ITEM_DELETE_ENTRY;

@interface UIBarButtonItem (NPUtil)

+ (UIBarButtonItem*)barItemWithImage:(UIImage*)image target:(id)target action:(SEL)action;

+ (UIBarButtonItem*)richEditorToolbarButton:(UIImage*)image target:(id)target action:(SEL)action;

+ (UIBarButtonItem*)refreshButton:(id)target action:(SEL)action;

+ (UIBarButtonItem*)dashboardButton:(id)target action:(SEL)action;
+ (UIBarButtonItem*)dashboardButtonPlain:(id)target action:(SEL)action;

+ (UIBarButtonItem*)goToParentFolderButton:(id)target action:(SEL)action parentFolder:(NSString*)parentFolder;

+ (UIBarButtonItem*)goBackButton:(id)target action:(SEL)action;

+ (UIBarButtonItem*)khFlatButton:(id)target action:(SEL)action title:(NSString*)title rect:(CGRect)rect backgroundColor:(UIColor*)backgroundColor;

+ (UIBarButtonItem*)spacer;
@end
