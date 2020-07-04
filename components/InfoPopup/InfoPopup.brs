'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2020 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()     
    'Load common variables
    loadCommon()
    
    'Define SG nodes
    m.itemLabelHeader   = m.top.findNode("itemLabelHeader")
    m.itemLabelMain     = m.top.findNode("itemLabelMain")
    m.buttonContinue    = m.top.findNode("buttonContinue")
    m.updateField       = m.top.findNode("updateField")
    
    m.buttonContinue.setFocus(true)
    
    m.top.observeField("id","loadingComplete")
    m.updateField.observeField("fire","doUpdateField")
    
    m.updateField.control = "start" 
End Sub


Sub loadingComplete()
    if m.top.id = "FeaturesPopup" then
        setFeaturesText()
    else if m.top.id = "OverLoadPopup"
        setOverLoadText()
    else if m.top.id = "AboutChannel"
        setAboutText()
    end if
    
    m.buttonContinue.observeField("buttonSelected","onButtonPress")
End Sub


Sub setFeaturesText()

    m.itemLabelHeader.text = "New Channel Features"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "1. New CLOCK functionality added in screensaver. Enable in screensaver settings menu"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "2. Channel now supports higher resolution videos from Google."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "3. Shared Album support is finally here!"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Bug fixes:"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "   - Fixed an image download error seen by a few users"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Thank you for using the PhotoView Channel."

    'Write reg entry to we don't redisplay
    RegWrite("FeaturePopup", m.releaseVersion, "Settings")
    
End Sub


Sub setAboutText()

    m.itemLabelHeader.text = "About Channel"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "The 'PhotoView for Google Photos' channel was developed by Chris Taylor. It's dedicated to his 4-year-old daughter, who goes nuts every time she sees herself on TV."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "We're committed to making this one of the best Photo Apps on the Roku platform."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "If you have any questions or comments, please see [Tips and Tricks > Bugs / Feature Request]"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Please remember to rate us, this helps spread the word and drive development!"

End Sub


Sub doUpdateField()
    'This is ugly, but the best way I could think of at this time.
    m.top.closeReady = "true"   
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
End function
