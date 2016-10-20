//
//  ChatViewController.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatViewController : UIViewController, UIWebViewDelegate {
    fileprivate var chatURLString : NSString?
    fileprivate let chatView = UIWebView()
    fileprivate let indicator = UIActivityIndicatorView()
    
    convenience init(chatURL: NSString) {
        self.init(nibName: nil, bundle: nil)
        
        self.chatURLString = chatURL
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = "Chat"
        
        let closeButtonItem = UIBarButtonItem(title: "Close",
                                              style: .done,
                                              target: self,
                                              action: #selector(close))
        navigationItem.setLeftBarButton(closeButtonItem, animated: false)
        
        chatView.frame = view.bounds
        chatView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        chatView.alpha = 0
        chatView.delegate = self
        view.addSubview(chatView)
        
        indicator.frame = view.bounds
        indicator.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        indicator.color = UIColor.black
        indicator.startAnimating()
        view.addSubview(indicator)
        
        guard let chatURLString = chatURLString else {
            print("Chat URL not provided")
            return
        }
        
        let request = URLRequest(url: URL(string: chatURLString as String)!)
        chatView.loadRequest(request)
    }
    
    @objc func close() {
        (navigationController as! ChatNavigationController).trueDismissViewController(true, completion: nil)
    }
    
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        UIView.animate(withDuration: 1.0,
                                   delay: 1.0,
                                   options: UIViewAnimationOptions(),
                                   animations: { 
                                    self.chatView.alpha = 1.0
                                    self.indicator.alpha = 0.0
            }) { (finished) in
                self.indicator.stopAnimating()
        }
    }
}
