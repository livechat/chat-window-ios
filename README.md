# iOS chat widget for LiveChat

iOS chat widget for LiveChat allows you to integrate [LiveChat](https://livechatinc.com) with your iOS app.

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](#carthage)
[![Version](https://img.shields.io/cocoapods/v/LiveChat.svg?style=flat)](http://cocoapods.org/pods/LiveChat)
[![License](https://img.shields.io/cocoapods/l/LiveChat.svg?style=flat)](http://cocoapods.org/pods/LiveChat)
[![Platform](https://img.shields.io/cocoapods/p/LiveChat.svg?style=flat)](http://cocoapods.org/pods/LiveChat)

## Requirements

- iOS 11.0+
- Xcode 10.0+

## Installation

### Carthage

If you use [Carthage](https://github.com/Carthage/Carthage) to manage your dependencies, simply add 'livechat/chat-window-ios' to your `Cartfile`.

```
github "livechat/chat-window-ios" ~> 2.0.24
```

Make sure you have added `LiveChat.framework` to the "_Linked Frameworks and Libraries_" section of your target, and have include it in your Carthage framework copying build phase.

### CocoaPods

If you use [CocoaPods](http://cocoapods.org) to manage your dependencies, simply add LiveChat to your `Podfile`.

```bash
pod 'LiveChat', '~> 2.0.24'
```

### Manual Installation

You can integrate iOS chat widget into your project manually without using a dependency manager.

#### Swift

Just drag all files from the `LiveChat/Sources` directory into your project.

#### Objective-C

Drag all files from the `LiveChat/Sources` directory into your project. When adding first `*.swift` file to Objective-C project, Xcode will ask you to create a Bridging Header. It is not necessary for chat widget to work, so you can decline unless you plan to call Swift code from Objective-C. More information about bridging headers and Swift and Objective-C interoperability can be found [here](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html). You need to put the following import statement: `#import "<Your Project Name>-Swift.h"` at the top of your .m file.

Also, for Objective-C projects, you need to set the **Embedded Content Contains Swift Code** flag in your project to `Yes` (found under **Build Options** in the **Build Settings** tab).

## Usage

### Initalization

```swift
import LiveChat

LiveChat.licenseId = "YOUR_LICENSE_ID"
```

### Default Chat Widget presentation

```swift
LiveChat.presentChat()
```

### Presenting Chat Widget within client app view hierarchy

You can also take over the a responsibility for widget presentation within you app. To do so you have to set the `customPresentationStyleEnabled` flag to `true`.
This flag will disable the default widget's presentation behavior and leave that logic up to you. You can now access the `chatViewController` property and define your own presentation style.

When `customPresentationStyleEnabled` is set to `false` then `chatViewController` has a value of `nil`.

```swift
class YOUR_CLASS_NAME : UIViewControler, LiveChatDelegate { // Your class need to implement LiveChatDelegate protocol

    @IBAction func openChat(_ sender: Any) {  
        LiveChat.delegate = self
        LiveChat.customPresentationStyleEnabled = true

        present(LiveChat.chatViewController!, animated: true) {
            print("Presentation completed")
        }
    }

    func chatDismissed() {
        LiveChat.chatViewController!.dismiss(animated: true) {
            print("Presentation dismissed")
        }
    }
}
```

### Using UIWindowSceneDelegate
If your app is using UIWindowScene API you need to perform additional configuration steps in you window scene delegate class.

```swift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        LiveChat.windowScene = (scene as? UIWindowScene)
    }
}
```

### Setting Custom Variables

You can provide customer name or email if they are known, so a customer will not need to fill out the pre-chat survey:

```swift
LiveChat.name = "iOS Widget Example"
LiveChat.email = "example@livechatinc.com"
```

If you want to associate some additional info with your customer, you can set up Custom Variables:

```swift
LiveChat.setVariable(withKey:"Variable name", value:"Some value")
```

### Assign chat to specific group

You can route your customers to specific group of agents by providing groupId. More information can be found here: https://www.livechatinc.com/kb/dividing-live-chat-by-group/.

```swift
LiveChat.groupId = "77"
```

### Notifying the user about the agent's response

You can notifiy your user about agent response if chat was minimized by the user. To handle the incoming messages, your class must implement `LiveChatDelegate` protocol and set itself as `LiveChat.delegate`.

```swift
class YOUR_CLASS_NAME : LiveChatDelegate { // Your class need to implement LiveChatDelegate protocol
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		LiveChat.licenseId = "YOUR_LICENSE_ID"
		LiveChat.delegate = self // Set self as delegate

		return true
	}

	func received(message: LiveChatMessage) {
		print("Received message: \(message.text)")
		// Handle message here
	}
}
```

Sample message structure.

```swift
{
    author = {
        name = "Support Bot";
    };
    id = "QZ0X4O6PAV_3";
    messageType = newMessage;
    text = "I'm a HelpDesk Bot, here to assist you with any HelpDesk questions!";
    timestamp = 1632478822776;
}
```

### Handling chat window resence events

On the SDK level it's also possible to handle chat window presence events. To do so, your class must implement `LiveChatDelegate` protocol and set itself as `LiveChat.delegate`.

```swift
class YOUR_CLASS_NAME : LiveChatDelegate { // Your class need to implement LiveChatDelegate protocol
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        LiveChat.licenseId = "YOUR_LICENSE_ID"
        LiveChat.delegate = self // Set self as delegate

        return true
    }
    
    func chatPresented() {
        print("Chat presented")
        // Handle event here
    }
    
    func chatDismissed() {
        print("Chat dismissed")
        // Handle event here
    }    
}
```

### Handling URL

By default, all links in chat messages are opened in Safari browser. To change this behavior you can use the `LiveChatDelegate` to handle URL's yourself.

```swift
func handle(URL: URL) {
	print("URL is \(URL.absoluteString)")
	// Handle URL here
}
```

### Handling chat window errors

SDK will use this method to report unhandled widget errors. 

```swift
func loadingDidFail(with errror: Error) {
    print("Chat loading failure \(errror)")
    // Handle error here
}
```

### Sending files from device library

If you have file sharing enabled for the visitors, you should provide usage description by including `NSPhotoLibraryUsageDescription` (`Privacy - Photo Library Usage Description`), `NSCameraUsageDescription` (`Privacy - Camera Usage Description`) and `NSMicrophoneUsageDescription` (`Privacy - Microphone Usage Description`) keys in your `Info.plist` file to avoid crash on iOS 10 or higher. You can check `Info.plist` files in example projects.

## Third party integrations

### Snap Call

LiveChat SDK offers built in Snap Call (https://snapcall.io) integration. To benefit from that feature you have to prepare you application for requesting a mic permission from the user.
That can be done by adding `NSMicrophoneUsageDescription` and `NSCameraUsageDescription` keys to the `Info.plist` file. 

## Sample Apps

Sample apps for both Swift and Objective-C can be found in the `Examples` folder.

## Getting help

If you have any questions or want to provide feedback, [chat with us!](https://secure-lc.livechatinc.com/licence/1520/v2/open_chat.cgi?groups=51)

## License

iOS chat widget is available under the MIT license. See the LICENSE file for more info.
