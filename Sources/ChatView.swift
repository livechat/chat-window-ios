//
//  ChatView.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import WebKit
import UIKit

@objc protocol ChatViewDelegate : NSObjectProtocol {
    func closedChatView()
    func handle(URL: URL)
}

let iOSMessageHandlerName = "iosMobileWidget"

class ChatView : UIView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, LoadingViewDelegate {
    private var webView : WKWebView?
    private let loadingView = LoadingView()
    weak var delegate : ChatViewDelegate?
    private let jsonCache = JSONRequestCache()
    private var animating = false
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
        
        webView = WKWebView(frame: frame, configuration: configuration)

        if let webView = webView {
            addSubview(webView)
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.scrollView.minimumZoomScale = 1.0
            webView.scrollView.maximumZoomScale = 1.0
            webView.isOpaque = false
            webView.backgroundColor = UIColor.white
            webView.frame = frame
            webView.alpha = 0
        }
        
        backgroundColor = UIColor.clear
        
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingView.delegate = self
        loadingView.frame = bounds
        loadingView.startAnimation()
        addSubview(loadingView)
        
        let nc = NotificationCenter.default
      
        #if swift(>=4.2)
        nc.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification
        , object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidChangeFrameNotification), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        #else
        nc.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive
          , object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        nc.addObserver(self, selector: #selector(keyboardDidChangeFrameNotification), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        #endif

    }
    
    deinit {
        if let webView = webView {
            webView.scrollView.delegate = nil
            webView.stopLoading()
            webView.configuration.userContentController.removeScriptMessageHandler(forName:(iOSMessageHandlerName))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let webView = webView {
            loadingView.frame = webView.frame
        }
    }
    
    // MARK: Public Methods
    
    func presentChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard let wv = webView else { return }
        
        if !LiveChatState.isChatOpenedBefore() {
            delayed_reload()
        }
        
        LiveChatState.markChatAsOpened()
        
        let animations = {
            wv.frame = self.frameForSafeAreaInsets()
            self.loadingView.frame = wv.frame
            wv.alpha = 1
        }
        
        let completion = { (finished : Bool) in
            let fr = self.frameForSafeAreaInsets()
            wv.frame = CGRect(origin: fr.origin, size: CGSize(width: fr.size.width, height: fr.size.height - 1))
            DispatchQueue.main.asyncAfter(deadline:.now() + 0.1, execute: { [weak self] in
                if let `self` = self {
                    if wv.alpha > 0 {
                        wv.frame = self.frameForSafeAreaInsets()
                    }
                }
            })
            
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
            wv.frame = CGRect(x: 0, y: bounds.size.height, width: bounds.size.width, height: bounds.size.height)
            loadingView.frame = wv.frame
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
        guard let wv = webView else { return }
        
        if animating {
            return
        }
        
        wv.endEditing(true)
        
        let animations = {
            wv.frame = CGRect(x: 0, y: self.bounds.size.height, width: self.bounds.size.width, height: self.bounds.size.height)
            self.loadingView.frame = wv.frame
            wv.alpha = 0
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
    
    func clearSession() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            for record in records {
                if record.displayName.contains("livechat") || record.displayName.contains("chat.io") {
                    dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: [record], completionHandler: {
                        self.reloadWithDelay()
                    })
                }
            }
        }
    }
    
    private func chatHidden() {
        delegate?.closedChatView()
    }
    
    // MARK: Application state management
    
    @objc func applicationDidBecomeActiveNotification(_ notification: Notification) {
        if let webView = self.webView, webView.alpha > 0 {
            self.webViewBridge?.postFocusEvent()
        }
    }
    
    @objc func applicationWillResignActiveNotification(_ notification: Notification) {
        if let webView = self.webView, webView.alpha > 0 {
            self.webViewBridge?.postBlurEvent()
        }
    }
    
    // MARK: Keyboard frame changes
    
    @objc func keyboardWillChangeFrameNotification(_ notification: Notification) {
        let notification = KeyboardNotification(notification)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(delayedKeyboardWillChangeFrame(notification:)), with: notification, afterDelay: 0)
    }
    
    @objc func keyboardDidChangeFrameNotification(_ notification: Notification) {
        let notification = KeyboardNotification(notification)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(delayedKeyboardDidChangeFrame(_:)), with: notification, afterDelay: 0)
    }
    
    @objc func delayedKeyboardWillChangeFrame(notification: KeyboardNotification) {
        let coordinator = WebViewAnimationCoordinator()
        coordinator.coordinateAnimation(webView!,
                                        superView: self,
                                        notification: notification)
    }
    
    @objc func delayedKeyboardDidChangeFrame(_ notification: KeyboardNotification) {
        triggerResize()
    }
    
    private func frameForSafeAreaInsets() -> CGRect {
        var safeAreaInsets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeAreaInsets = self.safeAreaInsets
        } else {
          safeAreaInsets = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        }
        let frameForSafeAreaInsets = CGRect(x: safeAreaInsets.left, y: safeAreaInsets.top, width: bounds.size.width - safeAreaInsets.left - safeAreaInsets.right, height: bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom)
        
        return frameForSafeAreaInsets
    }
    
    private func triggerResize() {
        let targetFrame = frameForSafeAreaInsets()
        let triggerFrame = CGRect(origin: targetFrame.origin, size: CGSize(width: targetFrame.size.width, height: targetFrame.size.height - 1))
        webView?.frame = triggerFrame
        webView?.frame = targetFrame
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
                DispatchQueue.main.async(execute: { [weak self] in
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
                        
                        if let url = url, let wv = self.webView {
                            let request = URLRequest(url: url)
                            
                            if #available(iOS 9.0, *) {
                                // Changing UserAgent string:
                                wv.evaluateJavaScript("navigator.userAgent") {(result, error) in
                                    DispatchQueue.main.async(execute: {
                                        if let userAgent = result as? String {
                                            wv.customUserAgent = userAgent + " WebView_Widget_iOS/2.0.7"
                                            
                                            if LiveChatState.isChatOpenedBefore() {
                                                wv.load(request)
                                            }
                                        }
                                    })
                                }
                            } else {
                                if LiveChatState.isChatOpenedBefore() {
                                    wv.load(request)
                                }
                            }
                        } else {
                            print("error: Invalid url")
                            self.displayLoadingError(withMessage: "Invalid url")
                        }
                    }
                })
            })
        }
    }
    
    // MARK: LoadingViewDelegate
    
    func reloadWithDelay() {
        self.perform(#selector(delayed_reload), with: nil, afterDelay: 0.2)
    }
    
    func reload() {
        if let webView = webView {
            self.loadingView.alpha = 1.0
            self.loadingView.startAnimation()
            webView.reload()
        }
    }
    
    @objc func close() {
        dismissChat(animated: true) { (finished) in
            if finished {
                if let delegate = self.delegate {
                    delegate.closedChatView()
                }
            }
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
        
        if !(error.domain == NSURLErrorDomain && error.code == -999) {
            loadingView.displayLoadingError(withMessage: error.localizedDescription)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let webView = self.webView, webView.alpha == 0 {
            self.webViewBridge?.postBlurEvent()
        }
      
      
      #if swift(>=4.2)
      UIView.animate(withDuration: 0.3,
                     delay: 1.0,
                     options: .curveLinear,
                     animations: {
                      self.loadingView.alpha = 0
      },
                     completion: { (finished) in
                      
      })
      #else
      UIView.animate(withDuration: 0.3,
                     delay: 1.0,
                     options: UIViewAnimationOptions(),
                     animations: {
                      self.loadingView.alpha = 0
      },
                     completion: { (finished) in
      
      })
      #endif
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
    
    @available(iOS 10.0, *)
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }
    
    // MARK: WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if (message.body is NSDictionary) {
            webViewBridge?.handle(message.body as! NSDictionary);
        }
    }
}
