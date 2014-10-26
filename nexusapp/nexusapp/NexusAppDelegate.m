//
//  NexusPadAppDelegate.m
//  nexuspad
//
//  Created by Ren Liu on 5/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NexusAppDelegate.h"
#import "ImportDocUploadViewController.h"
#import "Reachability.h"
#import <SDWebImage/SDImageCache.h>
#import "HostInfo.h"
#import "UIColor+NPColor.h"
#import "NPService.h"
#import "SyncUpService.h"
#import "UserManager.h"
#import "Account.h"
#import "AccountManager.h"
#import "UIColor+NPColor.h"
#import "SyncDownService.h"
#import "NPUploadHelper.h"

@interface NexusAppDelegate ()
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *nexuspadReach;
@property (nonatomic, strong) Reachability *wifiReach;

@property (nonatomic, unsafe_unretained) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation NexusAppDelegate

@synthesize window = _window;
@synthesize internetReach, nexuspadReach, wifiReach;
@synthesize backgroundTaskIdentifier;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
    
    if (url != nil && [url isFileURL]) {
        [self openDocImportView:url];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    [self checkConnectivity];
    
    // Set the navigation bar
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    

    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    [navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar.png"] resizableImageWithCapInsets:edgeInsets] forBarMetrics:UIBarMetricsDefault];

    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];

    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:[UIColor colorFromHexString:@"eeeeee"]];        

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    // Start the core data store.
    [DataStore getNPManagedDocument];
    
    // Create the global instance of BackgroundUploader
    [NPUploadHelper instance];

    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [self openDocImportView:url];
    return YES;
}

- (void)openDocImportView:(NSURL*)url {
    Account *currentAcct = [[AccountManager instance] getCurrentLoginAcct];
    [[UserManager instance] setCurrentUser:currentAcct];

    AccessEntitlement *defaultAccessInfo = [[UserManager instance] defaultAccessInfo];
    
    UIStoryboard *entryStoryBoard = [UIStoryboard storyboardWithName:@"iPhone_doc" bundle:nil];
    
    ImportDocUploadViewController* docUploadController = [entryStoryBoard instantiateViewControllerWithIdentifier:@"DocUploadView"];
    [docUploadController addFileURLWithDestination:url
                                          toFolder:[NPFolder initRootFolder:DOC_MODULE
                                                                 accessInfo:defaultAccessInfo]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:docUploadController];

    navController.navigationBar.translucent = YES;                              // This is important to stick the view to top
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
}


- (void)checkConnectivity
{
    // Check if it can reach NexusPad.com
    self.nexuspadReach = [Reachability reachabilityWithHostName:@"nexuspad.com"];
	[self.nexuspadReach startNotifier];
    
    // Make sure user gets notified when offline
    self.internetReach = [Reachability reachabilityForInternetConnection];
    [self.internetReach startNotifier];
    
    // Check wifi
    self.wifiReach = [Reachability reachabilityForLocalWiFi];
    [self.wifiReach startNotifier];
}


// Called by Reachability whenever status changes.
- (void)reachabilityChanged: (NSNotification* )note {
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    
    Boolean syncUpstream = NO;
    
    if (curReach == self.internetReach) {
        if (netStatus == NotReachable) {
            [NPService setServiceSpeed:none];
        } else {
        }
    }
    
    if (curReach == self.nexuspadReach) {
        
        if (netStatus == NotReachable) {
            DLog(@"NexusPad.com not available...");
            [NPService setServiceSpeed:none];
            
        } else if (netStatus == ReachableViaWiFi) {
            DLog(@"NexusPad is available via wifi...");
            
            if ([NPService isServiceAvailable] == NO) {
                syncUpstream = YES;
            }
            
            [NPService setServiceSpeed:wifi];
            
        } else if (netStatus == ReachableViaWWAN) {
            [NPService setServiceSpeed:threeG];

        } else {
            DLog(@"NexusPad.com is available :)");

            if ([NPService isServiceAvailable] == NO) {
                syncUpstream = YES;
            }
            
            [NPService setServiceSpeed:threeG];
        }
    }
    
    if (![NPService isServiceAvailable]) {
        // Stop the downstream sync timer when device goes offline to ensure that upstream sync is ALWAYS run before downstream sync.
        [[SyncDownService instance] stop];
    }
    
    if ([NPService isLoggedIn]) {
        if (syncUpstream) {
            [[SyncUpService instance] start];
        }
        
        if ([NPService isServiceAvailable]) {
            [[SyncDownService instance] start];
        }   
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    DLog(@"Continue uploading in the background...");
    [[NPUploadHelper instance] startUploading];
    
    self.backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [self endBackgroundTask];
    }];
    
    [self cleanupCache];
}

- (void)endBackgroundTask {
    DLog(@"Finish the background task...");

    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    __weak NexusAppDelegate *weakSelf = self;
    
    dispatch_async(mainQueue, ^{
        NexusAppDelegate *strongSelf = weakSelf;

        if (strongSelf != nil) {
            [[NPUploadHelper instance] cleanup];
            [[SyncDownService instance] stop];

            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            strongSelf.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    DLog(@"NexusApp enters foreground...");
    
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [self endBackgroundTask];
    }

    [self checkConnectivity];
    
    // Start the core data store.
    [DataStore getNPManagedDocument];    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
}


- (void)cleanupCache
{
    DLog(@"Clean up SDImageCache...");
    SDImageCache *imageCache = [SDImageCache sharedImageCache];
    [imageCache clearMemory];
    [imageCache clearDisk];
    [imageCache cleanDisk];
}

@end
