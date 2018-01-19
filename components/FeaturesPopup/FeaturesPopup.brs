
Sub init()     
    'Load common variables
    loadCommon()
    
    'Define SG nodes
    m.itemLabelHeader   = m.top.findNode("itemLabelHeader")
    m.itemLabelMain     = m.top.findNode("itemLabelMain")
    m.buttonContinue    = m.top.findNode("buttonContinue")
    m.updateField       = m.top.findNode("updateField")
    
    m.buttonContinue.setFocus(true)
    
    m.top.observeField("display","loadingComplete")
    m.updateField.observeField("fire","doUpdateField")
    
    m.updateField.control = "start"

End Sub


Sub loadingComplete()
    if m.top.display = "NewFeatures" then
        setFeaturesText()
    else if m.top.display = "ThousandPopup"
        setThousandText()
    end if
    
    m.buttonContinue.observeField("buttonSelected","onButtonPress")
    
End Sub


Sub setFeaturesText()

    m.itemLabelHeader.text = "New Channel Features"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "1. This channel has been rewritten from the ground up, to support Roku's new ScreneGraph"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "2. New options when viewing slideshows including multi-scrolling images!"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "3. New menu layout"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "4. Don't forget to check out the channels embedded screensaver"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Bug fixes:"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "   - No bugs to report"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Thank you for using the PhotoView Channel. Please remember to rate us!"

    'Write reg entry to we don't redisplay
    RegWrite("FeaturePopup", m.releaseVersion, "Settings")
    
End Sub


Sub setThousandText()

    m.itemLabelHeader.text = "Large Album Details"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "Please be aware Google limits the amount of media we can pull back per request to 1,000 items. To account for this limitation, your album is broken into pages to allow viewing."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Paging also allows accessing your photos much quicker as it reduces API calls. Be aware, a lower page number holds more recent media content."

    'Write reg entry to we don't redisplay
    RegWrite("ThousandPopup", "true", "Settings")
    
End Sub


Sub doUpdateField()
    'This is ugly, but the best way I could think of at this time.
    m.top.closeReady = "true"   
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
End function