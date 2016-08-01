//
//  LCCChatNavigationController.h
//  MobiLiveChat
//
//  Created by Łukasz Jerciński on 01/08/16.
//  Copyright © 2016 Krzysztof Górski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LCCChatNavigationController : UINavigationController

- (void)trueDismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;

@end
