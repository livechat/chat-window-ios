//
//  LiveChatConfiguration.swift
//  Pods
//
//  Created by Łukasz Jerciński on 15/03/2017.
//
//

import Foundation

struct LiveChatConfiguration : Equatable {
    var licenseId: String
    var groupId: String = "0"
    var name: String = ""
    var email: String = ""
    
    static func == (lhs: LiveChatConfiguration, rhs: LiveChatConfiguration) -> Bool {
        return lhs.licenseId == rhs.licenseId &&
            lhs.groupId == rhs.groupId &&
            lhs.name == rhs.name &&
            lhs.email == rhs.email
    }
}
