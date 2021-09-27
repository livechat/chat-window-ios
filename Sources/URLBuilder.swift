//
//  URLBuilder.swift
//  Pods
//
//  Created by Łukasz Jerciński on 21/03/2017.
//
//

import Foundation

func buildUrl(templateURL: String, configuration: LiveChatConfiguration, customVariables: CustomVariables?, maxLength: Int) -> URL? {
    var chatURL = templateURL.replacingOccurrences(of: "{%license%}", with: configuration.licenseId)
    chatURL = chatURL.replacingOccurrences(of: "{%group%}", with: configuration.groupId)
    chatURL = "https://".appending(chatURL)
    chatURL = chatURL.appending("&native_platform=ios")
    
    if configuration.name != "" {
        let escapedName = configuration.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        if let escapedName = escapedName {
            chatURL = chatURL.appending("&name=" + escapedName)
        }
    }
    
    if configuration.email != "" {
        let escapedEmail = configuration.email.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        if let escapedEmail = escapedEmail {
            chatURL = chatURL.appending("&email=" + escapedEmail)
        }
    }
    
    let customVariablesString = escaped(customVariables: customVariables)
    
    if let escapedCustomVariables = customVariablesString {
        chatURL = chatURL.appending("&params=" + escapedCustomVariables)
    }
    
    let url = URL(string:chatURL)
    
    return url
}

private func escaped(customVariables: CustomVariables?) -> String? {
    if let customVariables = customVariables {
        var allVariables = ""
        
        let characterSet =  CharacterSet(charactersIn:"=\"#%/<>?@\\^`{|} &\n　").inverted
        
        for (key, value) in customVariables {
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: characterSet)
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: characterSet)
            
            guard let eK = escapedKey else {
                continue
            }
            
            guard let eVal = escapedValue else {
                continue
            }
            
            let variable = eK + "=" + eVal
            
            if allVariables.count > 0 {
                allVariables += "&"
            }
            
            allVariables += variable
        }
        
        let escapedVariables = allVariables.addingPercentEncoding(withAllowedCharacters: characterSet)
        
        return escapedVariables
    }
    
    return nil
}
