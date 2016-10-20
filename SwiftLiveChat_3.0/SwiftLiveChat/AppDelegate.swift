//
//  AppDelegate.swift
//  SwiftLiveChat
//
//  Created by Łukasz Jerciński on 17/08/16.
//  Copyright © 2016 LiveChat Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let viewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window!.backgroundColor = UIColor.white
        window!.makeKeyAndVisible()
        
        return true
    }
}

