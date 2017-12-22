//
//  ViewController.swift
//  Example-Swift
//
//  Created by Łukasz Jerciński on 06/03/2017.
//  Copyright © 2017 LiveChat Inc. All rights reserved.
//

import UIKit
import LiveChat
import MapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "LiveChat"
    }
    
    @IBAction func openChat(_ sender: Any) {
        //Presenting chat:
        LiveChat.presentChat()
    }
    
    @IBAction func clearSession(_ sender: Any) {
        //Clearing session:
        LiveChat.clearSession()
    }
}

