var LiveChatWidget_hasFocusValue = false

document.hasFocus = function () { return LiveChatWidget_hasFocusValue;}

function LiveChatWidget_emitFocus() {
    LiveChatWidget_hasFocusValue = true;
    
    var focusName = 'focus'
    var focusEvent = document.createEvent('Event')
    focusEvent.initEvent(focusName, false, false);
    window.dispatchEvent(focusEvent)
}

function LiveChatWidget_emitBlur() {
    LiveChatWidget_hasFocusValue = false;
    
    var blurName = 'blur'
    var blurEvent = document.createEvent('Event')
    blurEvent.initEvent(blurName, false, false);
    window.dispatchEvent(blurEvent)
}


