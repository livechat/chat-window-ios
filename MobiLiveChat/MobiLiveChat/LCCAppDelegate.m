//
//  LCCAppDelegate.m
//  MobiLiveChat
//
//  Created by Krzysztof Górski on 12/11/13.
//  Copyright (c) 2013 Krzysztof Górski. All rights reserved.
//

#import "LCCAppDelegate.h"
#import "LCCHomeViewController.h"

@implementation LCCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    LCCHomeViewController *viewController = [[LCCHomeViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.window setRootViewController:navController];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
