//
//  ViewController.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import UIKit
import LiveChat
import MapKit

class ViewController: UIViewController, LiveChatDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "LiveChat"
        setupChatWindowProperties()
    }
    
    private func setupChatWindowProperties() {
        LiveChat.licenseId = "1520" // Set your licence number here
        LiveChat.groupId = "77" // Optionally, you can set specific group
        LiveChat.name = "iOS Widget Example" // User name and email can be provided if known
        LiveChat.email = "example@livechatinc.com"
        LiveChat.delegate = self
        
        // Setting some custom variables:
        LiveChat.setVariable(withKey:"First variable name", value:"Some value")
        LiveChat.setVariable(withKey:"Second name", value:"Other value")
    }
    
    @IBAction func openChatWithStandardPresentation(_ sender: Any) {
        LiveChat.customPresentationStyleEnabled = false
        LiveChat.presentChat()
    }
    
    @IBAction func openChatWithCustomPresentation(_ sender: Any) {
        LiveChat.customPresentationStyleEnabled = true
        present(LiveChat.chatViewController!, animated: true) {
            print("Presentation completed")
        }
    }
    
    // MARK: LiveChatDelegate
    
    func received(message: LiveChatMessage) {
        if (!LiveChat.isChatPresented) {
            // Notifying user
            let alert = UIAlertController(
                title: "Support",
                message: message.text,
                preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let chatAction = UIAlertAction(title: "Go to Chat", style: .default) { alert in
                // Presenting chat if not presented:
                if !LiveChat.isChatPresented {
                    LiveChat.presentChat()
                }
            }
            
            alert.addAction(chatAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func chatPresented() {
        print("Chat presented")
    }
    
    func chatLoadingFailed(with error: Error) {
        print("Chat loading failure \(error)")
    }
    
    func handle(URL: URL) {
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
    }

    func chatDismissed() {
        LiveChat.chatViewController?.dismiss(animated: true) {
            print("Presentation dismissed")
        }
    }
    
    @IBAction func clearSession(_ sender: Any) {
        LiveChat.clearSession()
    }
}

