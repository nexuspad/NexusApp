//
//  OAuthViewController.h
//  nexusapp
//
//  Created by Ren Liu on 10/13/13.
//
//

#import <UIKit/UIKit.h>
#import "UserExtService.h"

@interface OAuthViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UserExtService *externalService;

@end
