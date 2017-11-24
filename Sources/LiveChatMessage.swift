//
//  LiveChatMessage.swift
//  Pods
//
//  Created by Łukasz Jerciński on 15/03/2017.
//
//

import Foundation

public class LiveChatMessage : NSObject {
    @objc public let id: String
    @objc public let text: String
    @objc public let date: Date
    @objc public let authorName: String
    @objc public let rawMessage: NSDictionary
    
    init(id: String, text: String, date: Date, authorName: String, rawMessage: NSDictionary) {
        self.id = id
        self.text = text
        self.date = date
        self.authorName = authorName
        self.rawMessage = rawMessage
        
        super.init()
    }
}
