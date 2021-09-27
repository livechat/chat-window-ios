//
//  LiveChatOverlayViewController.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

enum ChatState {
    case presented
    case hidden
}

@objc protocol LiveChatOverlayViewControllerDelegate : NSObjectProtocol {
    func closedChatView()
    func handle(URL: URL)
    func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    func chatLoadingFailed(with error: Error)
    func overlayWillShow(animated: Bool)
}

class LiveChatOverlayViewController : UIViewController, ChatViewDelegate {
    let chatView = ChatView()
    private var preloadingWindow = UIWindow()
    var webViewBridge : WebViewBridge? {
        didSet {
            chatView.webViewBridge = webViewBridge
        }
    }
    var chatState : ChatState = .hidden
    var configuration : LiveChatConfiguration? {
        didSet {
            chatView.configuration = configuration
        }
    }
    var customVariables : CustomVariables? {
        didSet {
            chatView.customVariables = customVariables
        }
    }
    weak var delegate : LiveChatOverlayViewControllerDelegate?
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return delegate?.supportedInterfaceOrientations() ?? .all
    }
    override var shouldAutorotate : Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatView.delegate = self
        
        // Adding webView to temporary UIWindow to start preloading content.
        preloadingWindow.alpha = 0.0
        preloadingWindow.windowLevel = UIWindow.Level.normal - 100
        preloadingWindow.addSubview(chatView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.overlayWillShow(animated: true)
    }    
    
    // MARK: Public methods
    
    func presentChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        view.backgroundColor = .white
        view.addSubview(chatView)
        chatView.frame = view.bounds
        chatView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chatView.presentChat(animated: animated, completion: { (finished) in
            if let completion = completion {
                LiveChatState.markChatAsOpened()
                self.chatState = .presented
                completion(finished)
            }
        })
    }
    
    func dismissChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: { self.view.backgroundColor = .clear }, completion: nil)
        
        chatView.dismissChat(animated: animated, completion: { (finished) in
            if finished {
                self.chatState = .hidden
                self.preloadingWindow.addSubview(self.chatView)
            }
            
            if let completion = completion {
                completion(finished)
            }
        })
    }
    
    func clearSession() {
        chatView.clearSession()
    }
    
    // MARK: LiveChatViewDelegate
    
    @objc func closedChatView() {
        chatState = .hidden
        preloadingWindow.addSubview(chatView)
        
        if let delegate = delegate {
            delegate.closedChatView()
        }
    }
    
    @objc func handle(URL: URL) {
        if let delegate = delegate {
            delegate.handle(URL: URL)
        }
    }
    
    @objc func chatLoadingFailed(with error: Error) {
        delegate?.chatLoadingFailed(with: error)
    }
}
