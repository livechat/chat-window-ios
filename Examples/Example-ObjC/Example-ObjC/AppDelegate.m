//
//  AppDelegate.m
//  Example-ObjC
//
//  Created by Łukasz Jerciński on 15/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

#import "AppDelegate.h"
@import LiveChat;

@interface AppDelegate () <LiveChatDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    LiveChat.licenseId = @"1520"; // Set your licence number here
    LiveChat.groupId = @"77"; // Optionally, you can set specific group
    LiveChat.name = @"iOS Widget Example"; // User name and email can be provided if known
    LiveChat.email = @"example@livechatinc.com";
    
    // Setting some custom variables:
    [LiveChat setVariableWithKey:@"First variable name" value:@"Some value"];
    [LiveChat setVariableWithKey:@"Second name" value:@"Other value"];
    
    LiveChat.delegate = self;
    
    return YES;
}

#pragma mark - LiveChatDelegate

- (void)receivedWithMessage:(LiveChatMessage *)message {
    if (!LiveChat.isChatPresented) {
        // Notifying user
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Support" message:message.text preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *chatAction = [UIAlertAction actionWithTitle:@"Go to Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Presenting chat if not presented:
            if (!LiveChat.isChatPresented) {
                [LiveChat presentChatWithAnimated:YES completion:nil];
            }
        }];
        [alert addAction:chatAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)chatPresented {
    NSLog(@"Chat dismissed");
}

- (void)chatDismissed {
    NSLog(@"Chat presented");
}


- (void)handleWithURL:(NSURL *)URL {
    [[UIApplication sharedApplication] openURL:URL];
}

@end
