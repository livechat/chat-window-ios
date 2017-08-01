//
//  JSONRequestCache.swift
//  Pods
//
//  Created by Łukasz Jerciński on 22/03/2017.
//
//

import Foundation

class JSONRequestCache {
    var templateURL : String?
    var currentTask : URLSessionDataTask?

    @discardableResult
    func request(withCompletionHandler completionHandler: @escaping (String?, Error?) -> Void) -> URLSessionDataTask? {
        self.currentTask?.cancel()
        
        if let templateURL = templateURL {
            completionHandler(templateURL, nil)
            return nil
        }
        
        let session = URLSession.shared
        let request = URLRequest(url: URL(string:"https://cdn.livechatinc.com/app/mobile/urls.json")!)
        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            if let `self` = self {
                if let data = data {
                    var json: NSDictionary
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
                        
                        guard let openChat = json["chat_url"] as? String else {
                            print("error: Invalid JSON: \(json)")
                            return
                        }
                        
                        self.templateURL = openChat
                        completionHandler(self.templateURL, error)
                    } catch {
                        print("error: \(error)")
                        
                        self.templateURL = nil
                        completionHandler(self.templateURL, error)
                    }
                } else {
                    self.templateURL = nil
                    completionHandler(self.templateURL, error)
                }
            }
        })
        task.resume()
        self.currentTask = task
        return task
    }
}
