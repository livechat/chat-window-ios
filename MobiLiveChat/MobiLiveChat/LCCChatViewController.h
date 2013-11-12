//
//  LCCChatViewController.h
//  MobiLiveChat
//
//  Created by Krzysztof Górski on 12/11/13.
//  Copyright (c) 2013 Krzysztof Górski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCCChatViewController : UIViewController<UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *chatView;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

- (id)initWithChatUrl:(NSString*)url;

@end
