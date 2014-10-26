//
//  WebPageViewController.m
//  nexuspad
//
//  Created by Ren Liu on 8/26/12.
//
//

#import "WebPageViewController.h"
#import "ViewDisplayHelper.h"

@interface WebPageViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *htmlPageWebView;
@end

@implementation WebPageViewController

@synthesize pageUrl;
@synthesize htmlPageWebView;

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
    
    self.htmlPageWebView.delegate = self;

    NSString *urlString = [NSString stringWithFormat:@"http://nexuspad.com%@", pageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.htmlPageWebView loadRequest:request];
}

- (void)viewDidUnload
{
    [self setHtmlPageWebView:nil];
    [super viewDidUnload];
}

@end
