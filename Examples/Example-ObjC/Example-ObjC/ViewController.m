//
//  ViewController.m
//  Example-ObjC
//
//  Created by Łukasz Jerciński on 15/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

#import "ViewController.h"
@import LiveChat;
@import MapKit;

@interface ViewController () <LiveChatDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupChatWindowProperties];
    self.title = @"LiveChat";
}

- (void)setupChatWindowProperties {
    LiveChat.licenseId = @"1520"; // Set your licence number here
    LiveChat.groupId = @"77"; // Optionally, you can set specific group
    LiveChat.name = @"iOS Widget Example"; // User name and email can be provided if known
    LiveChat.email = @"example@livechatinc.com";
    
    // Setting some custom variables:
    [LiveChat setVariableWithKey:@"First variable name" value:@"Some value"];
    [LiveChat setVariableWithKey:@"Second name" value:@"Other value"];
    
    LiveChat.delegate = self;
}

- (IBAction)openChatStandardPresentation:(id)sender {
    [LiveChat setCustomPresentationStyleEnabled:NO];
    [LiveChat presentChatWithAnimated:YES completion:nil];
}

- (IBAction)openChatCustomPresentation:(id)sender {
    [LiveChat setCustomPresentationStyleEnabled:YES];
    [self presentViewController:LiveChat.chatViewController animated:YES completion:^{
        NSLog(@"Presentation completed");
    }];
}

- (IBAction)clearSession:(id)sender {
    [LiveChat clearSession];
}

#pragma mark - LiveChatDelegate

- (void)receivedWithMessage:(LiveChatMessage *)message {
    if (!LiveChat.isChatPresented) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Support" message:message.text preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *chatAction = [UIAlertAction actionWithTitle:@"Go to Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Presenting chat if not presented:
            if (!LiveChat.isChatPresented) {
                [LiveChat presentChatWithAnimated:YES completion:nil];
            }
        }];

        [alert addAction:chatAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)chatPresented {
    NSLog(@"Chat presented");
}

- (void)chatDismissed {
    [LiveChat.chatViewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Chat dismissed");
    }];
}

- (void)chatLoadingFailedWith:(NSError *)error {
    NSLog(@"Chat loading failure %@", error.localizedDescription);
}

- (void)handleWithURL:(NSURL *)URL {
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

@end
