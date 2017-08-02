//
//  WebViewBridge.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation
import WebKit

@objc protocol WebViewBridgeDelegate : NSObjectProtocol {
    func received(message: LiveChatMessage)
    func hideChatWindow()
}

class WebViewBridge {
    weak var webView : WKWebView?
    weak var delegate : WebViewBridgeDelegate?
    private var delayedMessages:[String] = []
    var webAppActive = false {
        didSet {
            if webAppActive {
                for message in delayedMessages {
                    post(message: message)
                }
                delayedMessages.removeAll()
            }
        }
    }
    
    func handle(_ message: NSDictionary) {
        guard let messageTypeObj = message["messageType"], messageTypeObj is String else { return }
        let messageType = messageTypeObj as! String
        
        webAppActive = true
        
        if messageType == "newMessage" {
            guard let textObj = message["text"], textObj is String else {
                print("'text' key not valid in 'newMessage'")
                return
            }
            let text = textObj as! String

            guard let messageIdObj = message["id"], messageIdObj is String else {
                print("'id' key not valid in 'newMessage'")
                return
            }
            let messageId = messageIdObj as! String
            
            guard let timestampObj = message["timestamp"], timestampObj is String || timestampObj is NSNumber else {
                print("'timestamp' key not valid in 'newMessage'")
                return
            }
            var timestamp : Double = 0
            if timestampObj is String {
                timestamp = Double(timestampObj as! String)!
            } else if timestampObj is NSNumber {
                timestamp = (timestampObj as! NSNumber).doubleValue / 1000.0
            }
            
            guard let authorObj = message["author"], authorObj is Dictionary<String, Any> else {
                print("'author' key not valid in 'newMessage'")
                return
            }
            let author = authorObj as! Dictionary<String, Any>
            
            guard let authorNameObj = author["name"], authorNameObj is String else {
                print("'author.name' key not valid in 'newMessage'")
                return
            }
            let authorName = authorNameObj as! String
            
            let liveChatMessage = LiveChatMessage(id: messageId, text: text, date: Date(timeIntervalSince1970: timestamp), authorName: authorName, rawMessage: message)
            
            delegate?.received(message: liveChatMessage)
        } else if messageType == "hideChatWindow" {
            delegate?.hideChatWindow()
        } else {
            print("WebViewBridge unknown messageType: " + message.debugDescription)
        }
    }
    
    func postFocusEvent() {
        post(message: "LiveChatWidget_emitFocus();")
    }
    
    func postBlurEvent() {
        post(message: "LiveChatWidget_emitBlur();")
    }
    
    private func post(message: String) {
        if webAppActive {
            if let webView = self.webView {
                let exec = message
                webView.evaluateJavaScript(exec, completionHandler: { (object, error) in
                    if let error = error {
                        print("Sending message to iOS web bridge error: '\(error)' message: '\(message)'")
                    }
                })
            }
        } else {
            delayedMessages.append(message)
        }
    }
}
