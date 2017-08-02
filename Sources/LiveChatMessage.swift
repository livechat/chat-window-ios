//
//  LiveChatMessage.swift
//  Pods
//
//  Created by Łukasz Jerciński on 15/03/2017.
//
//

import Foundation

public class LiveChatMessage : NSObject {
    public let id: String
    public let text: String
    public let date: Date
    public let authorName: String
    public let rawMessage: NSDictionary
    
    init(id: String, text: String, date: Date, authorName: String, rawMessage: NSDictionary) {
        self.id = id
        self.text = text
        self.date = date
        self.authorName = authorName
        self.rawMessage = rawMessage
        
        super.init()
    }
}
