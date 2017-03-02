//
//  ChatView.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import WebKit

@objc protocol ChatViewDelegate : NSObjectProtocol {
    func closedChatView()
    func handle(URL: URL)
}

let iOSMessageHandlerName = "iosMobileWidget"

class ChatView : UIView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, LoadingViewDelegate {
    private var webView = WKWebView()
    private let loadingView = LoadingView()
    weak var delegate : ChatViewDelegate?
    private let jsonCache = JSONRequestCache()
    private var keyboardFrame = CGRect.zero
    private var animating = false
    private let keyboardAnimationDelayed = true
    var configuration : LiveChatConfiguration? {
        didSet {
            if let oldValue = oldValue, let configuration = configuration {
                if oldValue != configuration {
                    reloadWithDelay()
                }
            }
            
        }
    }
    var customVariables : Dictionary<String, String>? {
        didSet {
            reloadWithDelay()
        }
    }
    var webViewBridge : WebViewBridge? {
        didSet {
            if let webViewBridge = webViewBridge {
                webViewBridge.webView = webView
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        contentController.add(self, name:iOSMessageHandlerName)
        configuration.userContentController = contentController
        
        let podBundle = Bundle(for: ChatView.self)
        var scriptContent : String?
        
        do {
            if let path = podBundle.path(forResource: "LiveChatWidget", ofType: "js") {
                scriptContent = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            }
        } catch {
            print("Exception while injecting LiveChatWidget.js script")
        }
        
        let script = WKUserScript(source: scriptContent!, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)
        
        let frame = webViewFrame(forKeyboardFrame: keyboardFrame, topInset: topInset())
        webView = WKWebView(frame: frame, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        HideInputAccessoryHelper().removeInputAccessoryView(from: webView)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.delegate = self
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        webView.frame = webViewFrame(forKeyboardFrame: keyboardFrame, topInset: topInset())
        addSubview(webView)
        
        webView.alpha = 0
        
        backgroundColor = UIColor.clear
        
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingView.delegate = self
        loadingView.frame = bounds
        loadingView.startAnimation()
        addSubview(loadingView)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidChangeFrameNotification), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }
    
    deinit {
        webView.scrollView.delegate = nil
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName:(iOSMessageHandlerName))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = webViewFrame(forKeyboardFrame: keyboardFrame, topInset: topInset())
        loadingView.frame = webView.frame
    }

    // MARK: Public Methods
    
    func presentChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if !LiveChatState.isChatOpenedBefore() {
            delayed_reload()
        }
        
        LiveChatState.markChatAsOpened()
        
        let animations = {
            self.webView.frame = CGRect(x: 0, y: self.topInset(), width: self.bounds.size.width, height: self.bounds.size.height - self.topInset())
            self.loadingView.frame = self.webView.frame
            self.webView.alpha = 1
        }
        
        let completion = { (finished : Bool) in
            self.animating = false
            
            if finished {
                self.webViewBridge?.postFocusEvent()
            }
            
            if let completion = completion {
                completion(finished)
            }
        }
        
        if animated {
            animating = true
            webView.frame = CGRect(x: 0, y: bounds.size.height, width: bounds.size.width, height: bounds.size.height - topInset())
            loadingView.frame = webView.frame
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0,
                           options: [],
                           animations: animations,
                           completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
    
    func dismissChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if animating {
            return
        }
        
        webView.endEditing(true)
        
        let animations = {
            self.webView.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: self.bounds.size.height - self.topInset())
            self.loadingView.frame = self.webView.frame
            self.webView.alpha = 0
        }
        
        let completion = { (finished : Bool) in
            self.animating = false
            
            if finished {
                self.webViewBridge?.postBlurEvent()
                
                self.chatHidden()
            }
            
            if let completion = completion {
                completion(finished)
            }
        }
        
        if animated {
            animating = true
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: [.curveEaseOut],
                           animations: animations,
                           completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
    
    private func chatHidden() {
        delegate?.closedChatView()
    }
    
    // MARK: Animation
    
    private func shouldAnimateKeyboard() -> Bool {
        if webView.alpha > 0 {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Keyboard frame changes
    
    func keyboardWillChangeFrameNotification(_ notification: Notification) {
        let notification = KeyboardNotification(notification)
        let keyboardScreenEndFrame = notification.screenFrameEnd
        keyboardFrame = keyboardScreenEndFrame
        
        if keyboardAnimationDelayed {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(delayedWillKeyboardFrameChange), with: notification, afterDelay: 0)
        } else {
            delayedWillKeyboardFrameChange(notification)
        }
    }
    
    func keyboardDidChangeFrameNotification(_ notification: Notification) {
        let notification = KeyboardNotification(notification)
        keyboardFrame = notification.screenFrameEnd
        
        if keyboardAnimationDelayed {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            perform(#selector(delayedDidKeyboardFrameChange), with: notification, afterDelay: 0)
        } else {
            delayedDidKeyboardFrameChange(notification)
        }
    }
    
    @objc func delayedWillKeyboardFrameChange(_ notification: KeyboardNotification) {
        if keyboardFrame.equalTo(notification.screenFrameEnd) {
            webView.scrollView.isScrollEnabled = !shouldAnimateKeyboard()
            
            if shouldAnimateKeyboard() {
                animateKeyboard(frameBegin: notification.screenFrameBegin, frameEnd: notification.screenFrameEnd, duration: notification.animationDuration, animationCurve: notification.animationCurve)
            } else {
                webView.frame = webViewFrame(forKeyboardFrame: keyboardFrame, topInset: topInset())
            }
        }
    }
    
    @objc func delayedDidKeyboardFrameChange(_ notification: KeyboardNotification) {
        if keyboardFrame.equalTo(notification.screenFrameEnd) {
            webView.scrollView.isScrollEnabled = false
            
            if keyboardFrame.origin.y >= self.bounds.size.height {
                keyboardFrame = CGRect.zero
            }
            
            webView.frame = webViewFrame(forKeyboardFrame:keyboardFrame, topInset: topInset())
            webView.layer.transform = CATransform3DIdentity
        }
    }
    
    // MARK: Private Methods
    
    private func webViewFrame(forKeyboardFrame keyboardFrame: CGRect?, topInset: CGFloat) -> CGRect {
        if (self.bounds.size.width == 0) {
            return CGRect(origin: CGPoint(x: 0, y: self.bounds.size.height), size:CGSize(width: self.bounds.size.width, height: 1))
        }
        
        guard let keyboardFrame = keyboardFrame, keyboardFrame != CGRect.zero else {
            let frame = CGRect(x: 0, y: topInset, width: self.bounds.size.width, height: max(self.bounds.size.height - topInset, 0))
            return frame
        }
        
        let frame = CGRect(x: 0, y: topInset, width: self.bounds.size.width, height: keyboardFrame.origin.y - topInset)
        return frame
    }
    
    private func topInset() -> CGFloat {
        let statusBarFrame  = UIApplication.shared.statusBarFrame;
        
        guard let viewWindow = self.window else {
            return statusBarFrame.size.height;
        }
        
        let statusBarWindowRect = viewWindow.convert(statusBarFrame, from: nil);
        let statusBarViewRect = self.convert(statusBarWindowRect, from: nil);
        
        return statusBarViewRect.size.height;
    }
    
    private func animateKeyboard(frameBegin: CGRect, frameEnd: CGRect, duration: TimeInterval, animationCurve: Int) {
        let beginViewFrame = webViewFrame(forKeyboardFrame: frameBegin, topInset: topInset())
        let endViewFrame = webViewFrame(forKeyboardFrame: frameEnd, topInset: topInset())
        
        webView.layer.transform = CATransform3DIdentity
        webView.layer.removeAllAnimations()
        
        UIGraphicsBeginImageContextWithOptions(webView.bounds.size, false, 0)
        webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: false)
        let beginImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        
        webView.frame = endViewFrame
        webView.scrollView.layer.removeAllAnimations() //prevents animation glitch
        
        let beginMaskImageView = UIImageView()
        beginMaskImageView.frame = beginViewFrame
        beginMaskImageView.image = beginImage
        self.addSubview(beginMaskImageView)
        beginMaskImageView.layer.removeAllAnimations()
        
        let yScale = beginViewFrame.size.height / endViewFrame.size.height
        let scaleTransform = CATransform3DMakeScale(1.0, yScale, 1.0)
        
        webView.layer.transform = scaleTransform
        webView.layer.removeAllAnimations()
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIViewAnimationOptions(rawValue: UInt(animationCurve)),
                       animations: {
                        beginMaskImageView.frame = endViewFrame
                        beginMaskImageView.alpha = 0
                        self.webView.layer.transform = CATransform3DIdentity
        }) { (finished) in
            beginMaskImageView.removeFromSuperview()
        }
    }
    
    private func displayLoadingError(withMessage message: String) {
        DispatchQueue.main.async(execute: { [weak self] in
            if let `self` = self {
                self.loadingView.displayLoadingError(withMessage: message)
            }
        })
    }
    
    @objc func delayed_reload() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayed_reload), object: nil)
        
        if jsonCache.currentTask == nil || jsonCache.currentTask?.state != .running {
            loadingView.alpha = 1.0
            loadingView.startAnimation()
            
            jsonCache.request(withCompletionHandler: { [weak self] (templateURL, error) in
                if let `self` = self {
                    if let error = error {
                        self.displayLoadingError(withMessage: error.localizedDescription)
                        return
                    }
                    
                    guard let templateURL = templateURL else {
                        self.displayLoadingError(withMessage: "Template URL not provided.")
                        return
                    }
                    
                    guard let configuration = self.configuration else {
                        self.displayLoadingError(withMessage: "Configuration not provided.")
                        return
                    }
                    
                    let url = buildUrl(templateURL: templateURL, configuration: configuration, customVariables: self.customVariables, maxLength: 2000)
                    
                    if let url = url {
                        let request = URLRequest(url: url)
                        
                        if #available(iOS 9.0, *) {
                            // Changing UserAgent string:
                            self.webView.evaluateJavaScript("navigator.userAgent") {[weak self] (result, error) in
                                if let `self` = self, let userAgent = result as? String {
                                    self.webView.customUserAgent = userAgent + " WebView_Widget_iOS/2.0.0"
                                    
                                    if LiveChatState.isChatOpenedBefore() {
                                        self.webView.load(request)
                                    }
                                }
                            }
                        } else {
                            if LiveChatState.isChatOpenedBefore() {
                                self.webView.load(request)
                            }
                        }
                    } else {
                        print("error: Invalid url")
                        self.displayLoadingError(withMessage: "Invalid url")
                    }
                }
            })
        }
    }
    
    // MARK: LoadingViewDelegate
    
    func reloadWithDelay() {
        self.perform(#selector(delayed_reload), with: nil, afterDelay: 0.2)
    }
    
    func reload() {
        self.loadingView.alpha = 1.0
        self.loadingView.startAnimation()
        self.webView.reload()
    }
    
    func close() {
        dismissChat(animated: true) { (finished) in
            if finished {
                if let delegate = self.delegate {
                    delegate.closedChatView()
                }
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldAnimateKeyboard() {
            scrollView.contentOffset = CGPoint.zero;
        }
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil // No zooming
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Did fail navigation error: " + error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let URL = navigationAction.request.url ,
                UIApplication.shared.canOpenURL(URL) {

                if let delegate = self.delegate {
                    delegate.handle(URL: URL)
                } else {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(URL)
                    }
                }
                
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        
        loadingView.alpha = 1.0
        
        if error.domain == NSURLErrorDomain && error.code == -999 {
            loadingView.displayLoadingError(withMessage: error.localizedDescription)
        } else {
            loadingView.displayLoadingError(withMessage: error.localizedDescription)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.webView.alpha == 0 {
            self.webViewBridge?.postBlurEvent()
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.4,
                       options: UIViewAnimationOptions(),
                       animations: {
                        self.loadingView.alpha = 0
        },
                       completion: { (finished) in
                        
        })
    }
    
    // MARK: WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.targetFrame == nil) {
            let popup = WKWebView(frame: webView.frame, configuration: configuration)
            popup.uiDelegate = self
            self.addSubview(popup)
            return popup
        }
        return nil;
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }
    
    // MARK: WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.body is NSDictionary) {
            webViewBridge?.handle(message.body as! NSDictionary);
        }
    }
}
