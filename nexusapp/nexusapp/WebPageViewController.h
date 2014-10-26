//
//  WebPageViewController.h
//  nexuspad
//
//  Created by Ren Liu on 8/26/12.
//
//

#import <UIKit/UIKit.h>

@interface WebPageViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSString *pageUrl;

@end
