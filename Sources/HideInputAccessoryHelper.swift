//
//  HideInputAccessoryHelper.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import WebKit

class HideInputAccessoryHelper : NSObject {
    @objc func inputAccessoryView() -> AnyObject? {
        return nil
    }
    
    func removeInputAccessoryView(from webView: WKWebView) {
        var targetView: UIView?
        for view in webView.scrollView.subviews {
            if String(describing: type(of: view)).hasPrefix("WKContent") {
                targetView = view
            }
        }
        
        if let targetView = targetView {
            let noInputAccessoryViewClassName = "\(targetView.superclass!)HideInputAccessoryHelper"
            var newClass : AnyClass? = NSClassFromString(noInputAccessoryViewClassName)
            
            if newClass == nil {
                let uiViewClass : AnyClass = object_getClass(targetView)!
                newClass = objc_allocateClassPair(uiViewClass, noInputAccessoryViewClassName.cString(using: String.Encoding.ascii)!, 0)
            }
            
            let originalMethod = class_getInstanceMethod(HideInputAccessoryHelper.self, #selector(HideInputAccessoryHelper.inputAccessoryView))
            
            class_addMethod(newClass!.self, #selector(HideInputAccessoryHelper.inputAccessoryView), method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
            
            object_setClass(targetView, newClass!)
        }
    }
}
