//
//  LiveChatState.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 08/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import Foundation

class LiveChatState {
    static private let chatOpenedKey = "LiveChat_chatOpenedKey"
    
    class func isChatOpenedBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: chatOpenedKey)
    }
    
    class func markChatAsOpened() {
        UserDefaults.standard.set(true, forKey: chatOpenedKey)
        UserDefaults.standard.synchronize()
    }
}
