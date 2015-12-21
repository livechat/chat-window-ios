//
//  LCCHomeViewController.m
//  MobiLiveChat
//
//  Created by Krzysztof Górski on 12/11/13.
//  Copyright (c) 2013 Krzysztof Górski. All rights reserved.
//

#import "LCCHomeViewController.h"
#import <MapKit/MKMapView.h>

#define LC_URL              "https://cdn.livechatinc.com/app/mobile/urls.json"
#define LC_LICENSE          "3498581"
#define LC_CHAT_GROUP       "0"

@interface LCCHomeViewController ()

@property (nonatomic, strong) NSString *chatURL;

- (void) requestUrl;
- (NSString*) prepareUrl:(NSString *)url;
- (void) startChat:(UIButton*)button;

@end

@interface LCCHomeViewController ()

@end

@implementation LCCHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    [self.view addSubview:mapView];
    
    UIBarButtonItem *chatButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Chat with us!"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(startChat:)];
    [self.navigationItem setRightBarButtonItem:chatButton];
    
    [self requestUrl];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Tasks

- (void)requestUrl
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:@LC_URL];
    [[session dataTaskWithURL:url
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (!error) {
                    NSError *jsonError;
                    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&jsonError];
                    
                    if ([JSON isKindOfClass:[NSDictionary class]] && [JSON valueForKey:@"chat_url"] != nil) {
                        self.chatURL = [self prepareUrl:JSON[@"chat_url"]];
                    } else if (jsonError) {
                        NSLog(@"%@", jsonError);
                    }
                } else {
                    NSLog(@"%@", error);
                }
            }] resume];
}

#pragma mark -
#pragma mark Helper functions

- (NSString *)prepareUrl:(NSString *)url
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"https://%@", url];
    
    [string replaceOccurrencesOfString:@"{%license%}"
                            withString:@LC_LICENSE
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [string length])];
    
    [string replaceOccurrencesOfString:@"{%group%}"
                            withString:@LC_CHAT_GROUP
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [string length])];
    
    return string;
}

#pragma mark -
#pragma mark Actions

- (void)startChat:(UIButton*)button {
    
    if (!self.chatViewController) {
        self.chatViewController = [[LCCChatViewController alloc] initWithChatUrl:self.chatURL];
    }
    
    [self.navigationController pushViewController:self.chatViewController animated:YES];
}
@end
