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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"LiveChat";
}

- (IBAction)openChat:(id)sender {
    //Presenting chat:
    [LiveChat presentChatWithAnimated:YES completion:nil];
}

- (IBAction)clearSession:(id)sender {
    //Clearing session:
    [LiveChat clearSession];
}

@end
