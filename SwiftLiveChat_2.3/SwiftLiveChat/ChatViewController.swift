//
//  ChatViewController.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit

public class ChatViewController : UIViewController, UIWebViewDelegate {
    private var chatURLString : NSString?
    private let chatView = UIWebView()
    private let indicator = UIActivityIndicatorView()
    
    convenience init(chatURL: NSString) {
        self.init(nibName: nil, bundle: nil)
        
        self.chatURLString = chatURL
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        title = "Chat"
        
        let closeButtonItem = UIBarButtonItem(title: "Close",
                                              style: .Done,
                                              target: self,
                                              action: #selector(close))
        navigationItem.setLeftBarButtonItem(closeButtonItem, animated: false)
        
        chatView.frame = view.bounds
        chatView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        chatView.alpha = 0
        chatView.delegate = self
        view.addSubview(chatView)
        
        indicator.frame = view.bounds
        indicator.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        indicator.color = UIColor.blackColor()
        indicator.startAnimating()
        view.addSubview(indicator)
        
        guard let chatURLString = chatURLString else {
            print("Chat URL not provided")
            return
        }
        
        let request = NSURLRequest(URL: NSURL(string: chatURLString as String)!)
        chatView.loadRequest(request)
    }
    
    @objc func close() {
        (navigationController as! ChatNavigationController).trueDismissViewController(true, completion: nil)
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        UIView.animateWithDuration(1.0,
                                   delay: 1.0,
                                   options: .CurveEaseInOut,
                                   animations: { 
                                    self.chatView.alpha = 1.0
                                    self.indicator.alpha = 0.0
            }) { (finished) in
                self.indicator.stopAnimating()
        }
    }
}
