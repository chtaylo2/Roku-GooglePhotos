
Sub init()

    m.miniKeyboard = m.top.findNode("miniKeyboard")
    m.searchBtn = m.top.findNode("searchBtn")

    ' Load in the OAuth Registry entries
    loadReg()

End Sub


Sub processkeyEntry()
    print "TEXT: "; m.miniKeyboard.textEditBox.text

    'if len(m.pinPad.pin) = 3 then
    '    m.pinRectangle.visible = false
    '    m.settingSubList.setFocus(true)
    'end if

End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        print "FOCUS: "; m.miniKeyboard.hasFocus()
        'm.searchBtn.setFocus(true)
        if (key = "down") and (m.miniKeyboard.hasFocus() = true)
        '    m.searchBtn.setFocus(true)
            return true
        'else if (key = "left") and (m.pinRectangle.visible = false) and (m.settingsList.hasFocus() = false)
        '    m.settingsList.setFocus(true)
        '    return true        
        'else if (key = "back") and (m.settingsList.hasFocus() = false)
        '    m.settingsList.setFocus(true)
        '    m.pinRectangle.visible = false
        '    return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function