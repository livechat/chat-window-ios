//
//  LiveChat.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

typealias CustomVariables = [(String, String)]

enum ChatWindowDisplayMode {
    case window
    case viewController
}

@objc public protocol LiveChatDelegate : NSObjectProtocol {
    @objc optional func received(message: LiveChatMessage)
    @objc optional func handle(URL: URL)
    @objc optional func chatPresented()
    @objc optional func chatDismissed()
    @objc optional func chatLoadingFailed(with error: Error)
    @objc optional func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
}

public class LiveChat : NSObject {
    
    @available(iOS 13.0, *)
    @objc public static var windowScene: UIWindowScene?
    
    @objc public static var licenseId : String? {
        didSet {
            updateConfiguration()
        }
    }
    @objc public static var groupId : String? {
        didSet {
            updateConfiguration()
        }
    }
    @objc public static var name : String? {
        didSet {
            updateConfiguration()
        }
    }
    @objc public static var email : String? {
        didSet {
            updateConfiguration()
        }
    }
    
    @objc public static var customPresentationStyleEnabled : Bool {
        get { Manager.sharedInstance.chatWindowDisplayMode == .viewController }        
        set { Manager.sharedInstance.chatWindowDisplayMode = newValue ? .viewController : .window }
    }
    
    @objc public static weak var delegate : LiveChatDelegate? {
        didSet {
            Manager.sharedInstance.delegate = delegate
        }
    }
    
    @objc public static var isChatPresented : Bool {
        get {
            return Manager.sharedInstance.overlayViewController.chatState == .presented
        }
    }
    
    @objc public static var unreadMessagesCount : Int {
        get {
            return UnreadMessagesCounter.counterValue
        }
    }
    
    @objc public class func setVariable(withKey key: String, value: String) {
        Manager.sharedInstance.setVariable(withKey: key, value: value)
    }
    
    @objc public class func presentChat(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        Manager.sharedInstance.presentChat(animated: animated, completion: completion)
    }
    
    @objc public class func dismissChat(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        Manager.sharedInstance.dismissChat(animated: animated, completion: completion)
    }
    
    @objc public class func clearSession() {
        Manager.sharedInstance.clearSession()
    }
    
    @objc public class var chatViewController: UIViewController? {
        customPresentationStyleEnabled ? Manager.sharedInstance.overlayViewController : nil
    }
    
    private class func updateConfiguration() {
        if let licenseId = self.licenseId {
            let conf = LiveChatConfiguration(licenseId: licenseId, groupId: self.groupId ?? "0", name: self.name ?? "", email: self.email ?? "")
            Manager.sharedInstance.configuration = conf
        }
    }
}

private class Manager : NSObject, LiveChatOverlayViewControllerDelegate, WebViewBridgeDelegate {
    var configuration : LiveChatConfiguration? {
        didSet {
            overlayViewController.configuration = configuration
        }
    }
    var customVariables : CustomVariables? {
        didSet {
            overlayViewController.customVariables = customVariables
        }
    }
    weak var delegate : LiveChatDelegate?
    fileprivate let overlayViewController = LiveChatOverlayViewController()
    fileprivate let window = PassThroughWindow()
    fileprivate var chatWindowDisplayMode: ChatWindowDisplayMode = .window
    private var previousKeyWindow : UIWindow?
    private let webViewBridge = WebViewBridge()
    static let sharedInstance: Manager = {
        return Manager()
    }()
    
    override init() {
        window.backgroundColor = UIColor.clear
        window.frame = UIScreen.main.bounds
        window.windowLevel = UIWindow.Level.normal + 1
        window.rootViewController = overlayViewController
        
        super.init()
        
        webViewBridge.delegate = self
        overlayViewController.delegate = self
        overlayViewController.webViewBridge = webViewBridge
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { (notification) in
            if let keyWindow = UIApplication.shared.keyWindow {
                self.window.frame = keyWindow.frame
            }
        }
    }
    
    // MARK: Public methods
    
    func setVariable(withKey key: String, value: String)
    {
        let pair = (key, value)
        var mutableCustomVariables = customVariables ?? []
        
        if let index = mutableCustomVariables.firstIndex(where: { $0.0 == key }) {
            mutableCustomVariables[index] = pair
        } else {
            mutableCustomVariables.append(pair)
        }        
        self.customVariables = mutableCustomVariables
    }
    
    func presentChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        makeWindowVisibleIfNeeded()
        overlayViewController.presentChat(animated: animated, completion: { (finished) in
            if finished {
                UnreadMessagesCounter.resetCounter()
                self.delegate?.chatPresented?()
            }
            
            completion?(finished)
        })
    }
    
    func dismissChat(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        overlayViewController.dismissChat(animated: animated, completion: { [weak self] (finished) in
            if finished {
                self?.makeWindowHiddenIfNeeded()
                UnreadMessagesCounter.resetCounter()
            }
            
            completion?(finished)
        })
    }
    
    func clearSession() {
        overlayViewController.clearSession()
    }
    
    // MARK: LiveChatViewDelegate
    
    @objc func closedChatView() {
        makeWindowHiddenIfNeeded()
        delegate?.chatDismissed?()
    }
    
    @objc func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return delegate?.supportedInterfaceOrientations?() ?? .all
    }
    
    @objc func handle(URL: URL) {
        if let delegate = self.delegate {            
            if delegate.responds(to: #selector(LiveChatDelegate.handle(URL:))) {
                delegate.handle?(URL: URL)
                return
            }
        }
        
        if #available(iOS 10, *) {
            UIApplication.shared.open(URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL)
        }
    }
    
    func chatLoadingFailed(with error: Error) {
        delegate?.chatLoadingFailed?(with: error)
    }
    
    func overlayWillShow(animated: Bool) {
        if chatWindowDisplayMode == .viewController {
            presentChat(animated: animated)
        }
    }
    
    // MARK: WebViewBridgeDelegate
    
    @objc func received(message: LiveChatMessage) {
        let unread = UnreadMessagesCounter.handleUnreadMessage(id: message.id)
        
        if (unread) {
            delegate?.received?(message: message)
        }
    }
    
    @objc func hideChatWindow() {
        dismissChat(animated: true)
    }
    
    // MARK: Helper methods
    
    private func makeWindowVisibleIfNeeded() {
        guard chatWindowDisplayMode == .window else {
            return
        }
        
        previousKeyWindow = UIApplication.shared.keyWindow
        if #available(iOS 13.0, *) {
            if LiveChat.windowScene != nil {
                window.windowScene = LiveChat.windowScene
            }
        }
        window.makeKeyAndVisible()
    }
    
    private func makeWindowHiddenIfNeeded() {
        guard chatWindowDisplayMode == .window else {
            return
        }
        
        previousKeyWindow?.makeKeyAndVisible()
        previousKeyWindow = nil
        window.isHidden = true
    }
}

private class PassThroughWindow: UIWindow {
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return super.hitTest(point, with: event)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
