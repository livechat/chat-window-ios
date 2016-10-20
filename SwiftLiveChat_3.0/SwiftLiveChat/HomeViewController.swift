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

open class HomeViewController : UIViewController {
    fileprivate let urlString = "https://cdn.livechatinc.com/app/mobile/urls.json"
    fileprivate let license = "1520"
    fileprivate let chatGroup = "88"
    fileprivate var chatURL : NSString?
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = MKMapView(frame: view.bounds)
        view.addSubview(mapView)
        
        let chatButton = UIBarButtonItem(title: "Chat with us!", style: .plain, target: self, action: #selector(startChat))
        navigationItem.setRightBarButton(chatButton, animated: false)
        
        requestUrl()
    }
    
    @objc func startChat() {
        if let chatURL = self.chatURL {
            let chatViewController = ChatViewController(chatURL: chatURL)
            let navigationController = ChatNavigationController(rootViewController: chatViewController)
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    fileprivate func requestUrl() {
        let session = URLSession.shared
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        session.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error {
                print("Request error: " + error.localizedDescription)
            } else {
                guard let data = data else {
                    print("Request data not present")
                    return
                }
                
                do {
                    let JSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    guard JSON is NSDictionary else {
                        print("JSON is not dictionary!")
                        return
                    }
                    
                    let JSONDict = JSON as! NSDictionary
                    
                    if JSONDict.value(forKey: "chat_url") != nil {
                        self.chatURL = self.prepareURL(JSONDict["chat_url"] as! NSString)
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
            }
        }) .resume()
        
    }
    
    fileprivate func prepareURL(_ URL: NSString) -> NSString {
        let string = NSMutableString(string: "https://\(URL)")
        
        string.replaceOccurrences(of: "{%license%}",
                                          with: license,
                                          options: .literal,
                                          range: NSMakeRange(0, string.length))
        
        string.replaceOccurrences(of: "{%group%}",
                                          with: chatGroup,
                                          options: .literal,
                                          range: NSMakeRange(0, string.length))
        
        return string
    }
}


