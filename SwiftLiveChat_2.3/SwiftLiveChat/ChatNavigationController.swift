//
//  ChatNavigationController.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

public class ChatNavigationController : UINavigationController {
    private var flagged = false
    public override var presentingViewController : UIViewController? {
        get {
            if flagged {
                return nil
            } else {
                return super.presentingViewController
            }
        }
    }
    
    override public func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if viewControllerToPresent.isKindOfClass(UIDocumentMenuViewController) || viewControllerToPresent.isKindOfClass(UIImagePickerController) {
            flagged = true
        }
        
        super.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    public func trueDismissViewController(animated: Bool, completion: (() -> Void)?) {
        flagged = false
        dismissViewControllerAnimated(animated, completion: completion)
    }
}
