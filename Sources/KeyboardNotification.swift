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
        if let value = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue {
            return value.cgRectValue
        }
        else {
            return CGRect.zero
        }
    }
    
    /// End frame of the keyboard in screen coordinates
    open var screenFrameEnd: CGRect {
        if let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            return value.cgRectValue
        }
        else {
            return CGRect.zero
        }
    }
    
    /// Keyboard animation duration
    open var animationDuration: Double {
        if let number = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {
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
        if let number = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            return number.intValue
        }
        return UIView.AnimationCurve.easeInOut.rawValue
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


