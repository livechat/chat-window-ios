//
//  AppDelegate.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import UIKit
import LiveChat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LiveChatDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        LiveChat.licenseId = "1520" // Set your licence number here
        LiveChat.groupId = "88" // Optionally, you can set specific group
        LiveChat.name = "iOS Widget Example" // User name and email can be provided if known
        LiveChat.email = "example@livechatinc.com"
        
        // Setting some custom variables:
        LiveChat.setVariable(withKey:"First variable name", value:"Some value")
        LiveChat.setVariable(withKey:"Second name", value:"Other value")
        
        LiveChat.delegate = self
        
        return true
    }
    
    // MARK: LiveChatDelegate
    
    func received(message: LiveChatMessage) {
        // Notifying user
        let alert = UIAlertController(title: "Support", message: message.text, preferredStyle: .alert)
        let chatAction = UIAlertAction(title: "Go to Chat", style: .default) { alert in
            // Presenting chat if not presented:
            if !LiveChat.isChatPresented {
                LiveChat.presentChat()
            }
        }
        alert.addAction(chatAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func handle(URL: URL) {
        UIApplication.shared.openURL(URL)
    }
}

