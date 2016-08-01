//
//  LCCChatNavigationController.m
//  MobiLiveChat
//
//  Created by Łukasz Jerciński on 01/08/16.
//  Copyright © 2016 Krzysztof Górski. All rights reserved.
//

#import "LCCChatNavigationController.h"

@interface LCCChatNavigationController ()

@end

@implementation LCCChatNavigationController {
    BOOL _flagged;
}

#pragma mark - Avoiding iOS bug

- (UIViewController *)presentingViewController {
    if (_flagged) {
        return nil;
    } else {
        return [super presentingViewController];
    }
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if ([viewControllerToPresent isKindOfClass:[UIDocumentMenuViewController class]]
        ||[viewControllerToPresent isKindOfClass:[UIImagePickerController class]]) {
        _flagged = YES;
    }
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (void)trueDismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    _flagged = NO;
    [self dismissViewControllerAnimated:flag completion:completion];
}

@end
