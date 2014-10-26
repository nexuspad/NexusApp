//
//  MessageView.h
//  nexusapp
//
//  Created by Ren Liu on 2/5/13.
//
//

#import <UIKit/UIKit.h>

@interface MessageView : UIScrollView

- (id)initWithMessage:(NSString*)messageText messageImage:(UIImage*)image viewTag:(int)viewTag;

@end
