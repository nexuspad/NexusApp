//
//  OAuthViewController.m
//  nexusapp
//
//  Created by Ren Liu on 10/13/13.
//
//

#import "OAuthViewController.h"
#import "ViewDisplayHelper.h"

@interface OAuthViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation OAuthViewController


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [ViewDisplayHelper displayWaiting:self.view messageText:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [ViewDisplayHelper dismissWaiting:self.view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.delegate = self;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.externalService.googleOauthUrl]];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
