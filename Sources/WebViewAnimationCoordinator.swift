//
//  WebViewAnimationCoordinator.swift
//  chat.io
//
//  Created by Łukasz Jerciński on 21/11/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewAnimationCoordinator {
    func coordinateAnimation(_ webView: WKWebView, superView: UIView, notification: KeyboardNotification, completion: ((Bool) -> Swift.Void)? = nil) {
        let frameBegin = notification.frameBeginForView(webView)
        let frameEnd = notification.frameEndForView(webView)
        
        let keyboardHeightBegin = max(webView.bounds.size.height - frameBegin.origin.y, 0)
        let keyboardHeightEnd = max(webView.bounds.size.height - frameEnd.origin.y, 0)
        
        let maskAnimationBeginFrame = CGRect(origin: webView.frame.origin, size: CGSize(width: webView.frame.width, height: webView.frame.height - keyboardHeightBegin))
        let maskAnimationEndFrame = CGRect(origin: webView.frame.origin, size: CGSize(width: webView.frame.width, height: webView.frame.height - keyboardHeightEnd))
        
        let xScale = maskAnimationBeginFrame.size.width / maskAnimationEndFrame.size.width
        let yScale = maskAnimationBeginFrame.size.height / maskAnimationEndFrame.size.height
        let scaleTransform = CATransform3DMakeScale(xScale, yScale, 1.0)
        
        var translationTransform = CATransform3DIdentity
        let xTranslation = (maskAnimationBeginFrame.size.width / 2.0 - maskAnimationEndFrame.size.width / 2.0) - (maskAnimationEndFrame.origin.x - maskAnimationBeginFrame.origin.x)
        
        if (keyboardHeightEnd == 0) {
            let yTranslation = (maskAnimationBeginFrame.size.height / 2.0 - maskAnimationEndFrame.size.height / 2.0) - (maskAnimationEndFrame.origin.y - maskAnimationBeginFrame.origin.y)
            translationTransform = CATransform3DMakeTranslation(xTranslation, yTranslation, 0)
        } else {
            let yTranslation = keyboardHeightEnd * yScale / 2.0 - (maskAnimationEndFrame.origin.y - maskAnimationBeginFrame.origin.y)
            translationTransform = CATransform3DMakeTranslation(xTranslation, yTranslation, 0)
        }
        
        let transform = CATransform3DConcat(scaleTransform, translationTransform)
        
        performAnimation(webView, superView: superView, maskAnimationBeginFrame: maskAnimationBeginFrame, maskAnimationEndFrame: maskAnimationEndFrame, webViewTransform: transform, duration: notification.animationDuration, animationCurve: UIViewAnimationOptions(rawValue: UInt(notification.animationCurve)), completion: completion)
        
    }
    
    private func performAnimation(_ webView: WKWebView, superView: UIView, maskAnimationBeginFrame: CGRect, maskAnimationEndFrame: CGRect, webViewTransform: CATransform3D, duration: TimeInterval, animationCurve: UIViewAnimationOptions, completion: ((Bool) -> Swift.Void)? = nil) {
        
        webView.layer.transform = CATransform3DIdentity
        webView.layer.removeAllAnimations()
        
        UIGraphicsBeginImageContextWithOptions( maskAnimationBeginFrame.size, false, 0)
        webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: false)
        guard let maskImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()
        
        let fr = webView.frame
        webView.frame = CGRect(origin: fr.origin, size: CGSize(width: fr.size.width, height: fr.size.height - 1))
        webView.frame = fr
        webView.scrollView.layer.removeAllAnimations() //prevents animation glitch
        
        let maskImageView = UIImageView()
        maskImageView.frame = maskAnimationBeginFrame
        maskImageView.image = maskImage
        superView.addSubview(maskImageView)
        maskImageView.layer.removeAllAnimations()
        
        webView.layer.transform = webViewTransform
        webView.layer.removeAllAnimations()
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: animationCurve,
                       animations: {
                        maskImageView.frame = maskAnimationEndFrame
                        maskImageView.alpha = 0
                        webView.layer.transform = CATransform3DIdentity
        }) { (finished) in
            maskImageView.removeFromSuperview()
            if let completion = completion {
                completion(finished)
            }
        }
    }
}
