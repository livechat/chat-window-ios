//
//  HomeViewController.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import Foundation
import UIKit
import MapKit

public class HomeViewController : UIViewController {
    private let urlString = "https://cdn.livechatinc.com/app/mobile/urls.json"
    private let license = "1520"
    private let chatGroup = "88"
    private var chatURL : NSString?
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = MKMapView(frame: view.bounds)
        view.addSubview(mapView)
        
        let chatButton = UIBarButtonItem(title: "Chat with us!", style: .Plain, target: self, action: #selector(startChat))
        navigationItem.setRightBarButtonItem(chatButton, animated: false)
        
        requestUrl()
    }
    
    @objc func startChat() {
        if let chatURL = self.chatURL {
            let chatViewController = ChatViewController(chatURL: chatURL)
            let navigationController = ChatNavigationController(rootViewController: chatViewController)
            presentViewController(navigationController, animated: true, completion: nil)
        }
    }
    
    private func requestUrl() {
        let session = NSURLSession.sharedSession()
        
        guard let url = NSURL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        session.dataTaskWithURL(url) { (data, response, error) in
            if let error = error {
                print("Request error: " + error.localizedDescription)
            } else {
                guard let data = data else {
                    print("Request data not present")
                    return
                }
                
                do {
                    let JSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if JSON.isKindOfClass(NSDictionary) && JSON.valueForKey("chat_url") != nil {
                        self.chatURL = self.prepareURL(JSON["chat_url"] as! NSString)
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
        }.resume()
        
    }
    
    private func prepareURL(URL: NSString) -> NSString {
        let string = NSMutableString(string: "https://\(URL)")
        
        string.replaceOccurrencesOfString("{%license%}",
                                          withString: license,
                                          options: .LiteralSearch,
                                          range: NSMakeRange(0, string.length))
        
        string.replaceOccurrencesOfString("{%group%}",
                                          withString: chatGroup,
                                          options: .LiteralSearch,
                                          range: NSMakeRange(0, string.length))
        
        return string
    }
}


