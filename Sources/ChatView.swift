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
    func chatLoadingFailed(with error: Error)
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
            if let configuration = configuration {
                if oldValue != configuration {
                    reloadWithDelay()
                }
            }
            
        }
    }
    var customVariables : CustomVariables? {
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
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true
        let contentController = WKUserContentController()
        contentController.add(self, name:iOSMessageHandlerName)
        configuration.userContentController = contentController

        #if SwiftPM
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: ChatView.self)
        #endif
        var scriptContent : String?
        
        do {
            if let path = bundle.path(forResource: "LiveChatWidget", ofType: "js") {
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
        nc.addObserver(self, selector: #selector(applicationDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification
            , object: nil)
        nc.addObserver(self, selector: #selector(applicationWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
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
    
    private func frameForSafeAreaInsets() -> CGRect {
        var safeAreaInsets = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeAreaInsets = self.safeAreaInsets
        } else {
            safeAreaInsets = UIEdgeInsets.init(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        }
        let frameForSafeAreaInsets = CGRect(x: safeAreaInsets.left, y: safeAreaInsets.top, width: bounds.size.width - safeAreaInsets.left - safeAreaInsets.right, height: bounds.size.height - safeAreaInsets.top - safeAreaInsets.bottom)
        
        return frameForSafeAreaInsets
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
                            self.delegate?.chatLoadingFailed(with: error)
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
                                    DispatchQueue.main.async(execute: { [weak self] in
                                        if let userAgent = result as? String {
                                            wv.customUserAgent = userAgent + " WebView_Widget_iOS/2.0.7"
                                            
                                            if LiveChatState.isChatOpenedBefore() {
                                                wv.load(request)
                                            }
                                        } else if let err = error {
                                            self?.delegate?.chatLoadingFailed(with: err)
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
        dismissChat(animated: true)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil // No zooming
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {        
        print("Did fail navigation error: " + error.localizedDescription)
        delegate?.chatLoadingFailed(with: error)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let URL = navigationAction.request.url ,
                UIApplication.shared.canOpenURL(URL) {
                
                if let delegate = self.delegate {
                    delegate.handle(URL: URL)
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
        delegate?.chatLoadingFailed(with: error)
        
        if !(error.domain == NSURLErrorDomain && error.code == -999) {
            loadingView.displayLoadingError(withMessage: error.localizedDescription)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let webView = self.webView, webView.alpha == 0 {
            self.webViewBridge?.postBlurEvent()
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 1.0,
                       options: UIView.AnimationOptions(),
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
