//
//  ChatNavigationController.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatNavigationController : UINavigationController {
    fileprivate var flagged = false
    open override var presentingViewController : UIViewController? {
        get {
            if flagged {
                return nil
            } else {
                return super.presentingViewController
            }
        }
    }
    
    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if viewControllerToPresent.isKind(of: UIDocumentMenuViewController.self) || viewControllerToPresent.isKind(of: UIImagePickerController.self) {
            flagged = true
        }
        
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    open func trueDismissViewController(_ animated: Bool, completion: (() -> Void)?) {
        flagged = false
        dismiss(animated: animated, completion: completion)
    }
}
