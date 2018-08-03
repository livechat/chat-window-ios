import UIKit

/// Wrapper for the NSNotification userInfo values associated with a keyboard notification.
///
/// It provides properties that retrieve userInfo dictionary values with these keys:
///
/// - UIKeyboardFrameBeginUserInfoKey
/// - UIKeyboardFrameEndUserInfoKey
/// - UIKeyboardAnimationDurationUserInfoKey
/// - UIKeyboardAnimationCurveUserInfoKey

class KeyboardNotification : NSObject {
    
    let notification: Notification
    let userInfo: NSDictionary
    
    /// Initializer
    ///
    /// :param: notification Keyboard-related notification
    public init(_ notification: Notification) {
        self.notification = notification
        if let userInfo = notification.userInfo {
            self.userInfo = userInfo as NSDictionary
        }
        else {
            self.userInfo = NSDictionary()
        }
    }
    
    /// Start frame of the keyboard in screen coordinates
    open var screenFrameBegin: CGRect {
        #if swift(>=4.2)
        let key: String = UIResponder.keyboardFrameBeginUserInfoKey
        #else
        let key: String = UIKeyboardFrameBeginUserInfoKey
        #endif
        if let value = userInfo[key] as? NSValue {
            return value.cgRectValue
        }
        else {
            return CGRect.zero
        }
    }
    
    /// End frame of the keyboard in screen coordinates
    open var screenFrameEnd: CGRect {
        #if swift(>=4.2)
        let key: String = UIResponder.keyboardFrameEndUserInfoKey
        #else
        let key: String = UIKeyboardFrameEndUserInfoKey
        #endif
        if let value = userInfo[key] as? NSValue {
            return value.cgRectValue
        }
        else {
            return CGRect.zero
        }
    }
    
    /// Keyboard animation duration
    open var animationDuration: Double {
        #if swift(>=4.2)
        let key: String = UIResponder.keyboardAnimationDurationUserInfoKey
        #else
        let key: String = UIKeyboardAnimationDurationUserInfoKey
        #endif
        if let number = userInfo[key] as? NSNumber {
            return number.doubleValue
        }
        else {
            return 0.25
        }
    }
    
    /// Keyboard animation curve
    ///
    /// Note that the value returned by this method may not correspond to a
    /// UIViewAnimationCurve enum value.  For example, in iOS 7 and iOS 8,
    /// this returns the value 7.
    open var animationCurve: Int {
        #if swift(>=4.2)
        let key: String = UIResponder.keyboardAnimationCurveUserInfoKey
        #else
        let key: String = UIKeyboardAnimationCurveUserInfoKey
        #endif
        if let number = userInfo[key] as? NSNumber {
            return number.intValue
        }
      
        #if swift(>=4.2)
        return UIView.AnimationCurve.easeInOut.rawValue
        #else
        return UIViewAnimationCurve.easeInOut.rawValue
        #endif
    }
    
    /// Start frame of the keyboard in coordinates of specified view
    ///
    /// :param: view UIView to whose coordinate system the frame will be converted
    /// :returns: frame rectangle in view's coordinate system
    open func frameBeginForView(_ view: UIView) -> CGRect {
        return view.convert(screenFrameBegin, from: view.window)
    }
    
    /// End frame of the keyboard in coordinates of specified view
    ///
    /// :param: view UIView to whose coordinate system the frame will be converted
    /// :returns: frame rectangle in view's coordinate system
    open func frameEndForView(_ view: UIView) -> CGRect {
        return view.convert(screenFrameEnd, from: view.window)
    }
}


