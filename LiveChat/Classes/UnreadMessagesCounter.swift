//
//  UnreadMessagesCounter.swift
//  Pods
//
//  Created by Łukasz Jerciński on 28/03/2017.
//
//

import Foundation

class UnreadMessagesCounter {
    static private let maxCount = 100
    static private let unreadMessagesKey = "LiveChat_unreadMessagesKey"
    static private let readMessagesKey = "LiveChat_readMessagesKey"
    
    private static func currentSet(forKey key: String) -> Set<String> {
        let object = UserDefaults.standard.object(forKey: key)
        
        var set : Set<String> = []
        if let a = object as? Array<String> {
            set = Set(a)
        }
        
        return set
    }
    
    private static func persist(set: Set<String>?, forKey key: String) {
        var array : Array<String>? = nil
        
        if let set = set {
            array = Array(set)
        }
        UserDefaults.standard.set(array, forKey: key)
    }
    
    public static var counterValue : Int {
        get {
            let unreadSet = currentSet(forKey: unreadMessagesKey)
            return unreadSet.count
        }
    }
    
    class func resetCounter() {
        let unreadSet = currentSet(forKey: unreadMessagesKey)
        var readSet = currentSet(forKey: readMessagesKey)
        
        readSet = readSet.union(unreadSet)
        
        persist(set: readSet, forKey: readMessagesKey)
        persist(set: nil, forKey: unreadMessagesKey)
    }
    
    class func handleUnreadMessage(id: String) -> Bool {
        var unreadSet = currentSet(forKey: unreadMessagesKey)
        let readSet = currentSet(forKey: readMessagesKey)
        
        if readSet.contains(id) {
            return false
        } else {
            if unreadSet.contains(id) {
                return false
            } else {
                unreadSet.insert(id)
                persist(set: unreadSet, forKey: unreadMessagesKey)
                
                return true
            }
        }
    }
}
