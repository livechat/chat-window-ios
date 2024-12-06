//
//  ChatWindow.swift
//  Example-SwiftUI
//
//  Created by Kamil Szostakowski on 06/12/2024.
//

import SwiftUI
import LiveChat

class ChatWindow {
    
    static func setup(with delegate: Delegate) {
        LiveChat.licenseId = "1520" // Set your licence number here
        LiveChat.groupId = "77" // Optionally, you can set specific group
        LiveChat.name = "iOS Widget Example" // User name and email can be provided if known
        LiveChat.email = "example@livechatinc.com"
        LiveChat.delegate = delegate
        
        // Setting some custom variables:
        LiveChat.setVariable(withKey:"First variable name", value:"Some value")
        LiveChat.setVariable(withKey:"Second name", value:"Other value")
        LiveChat.windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    }
 
    class Delegate: NSObject, LiveChatDelegate {
        var onDismiss: (() -> Void)?
        var onAlert: ((String) -> Void)?
        
        func received(message: LiveChatMessage) {
            if (!LiveChat.isChatPresented) {
                onAlert?(message.text)
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
            print("Presentation dismissed")
            LiveChat.chatViewController?.dismiss(animated: true) {
                
            }
        }
    }
}
