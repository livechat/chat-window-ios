//
//  LCCChatViewController.m
//  MobiLiveChat
//
//  Created by Krzysztof Górski on 12/11/13.
//  Copyright (c) 2013 Krzysztof Górski. All rights reserved.
//

#import "LCCChatViewController.h"
#import "LCCChatNavigationController.h"

@interface LCCChatViewController ()

@property (nonatomic, copy) NSString *chatUrl;

@end

@implementation LCCChatViewController

- (id)initWithChatUrl:(NSString *)url
{
    self = [super init];
    if (self) {
        [self setChatUrl:url];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setTitle:@"Chat"];
    
    UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                        style:UIBarButtonItemStyleDone
                                                                       target:self
                                                                       action:@selector(close:)];
    
    [self.navigationItem setLeftBarButtonItem:closeButtonItem
                                     animated:NO];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    self.chatView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.chatView setAlpha:0.0];
    [self.chatView setDelegate:self];
    [self.view addSubview:self.chatView];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.indicator setColor:[UIColor blackColor]];
    [self.indicator startAnimating];
    [self.view addSubview:self.indicator];
    
    NSURL *url = [NSURL URLWithString:self.chatUrl];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.chatView loadRequest:request];
}

- (void)close:(id)sender {
    [((LCCChatNavigationController *)self.navigationController) trueDismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    void (^showChatView)(void) = ^(void) {
        [self.chatView setAlpha:1.0];
        [self.indicator setAlpha:0.0];
    };
    
    void (^stopIndicator)(BOOL) = ^(BOOL finished) {
        [self.indicator stopAnimating];
    };
    
    [UIView animateWithDuration:1.0
                          delay:1.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:showChatView
                     completion:stopIndicator];
}
@end
