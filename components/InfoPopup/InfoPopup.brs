
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
    else if m.top.id = "ThousandPopup"
        setThousandText()
    else if m.top.id = "AboutChannel"
        setAboutText()
    end if
    
    m.buttonContinue.observeField("buttonSelected","onButtonPress")
End Sub


Sub setFeaturesText()

    m.itemLabelHeader.text = "New Channel Features"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "1. This channel has been rewritten from the ground up, to support Roku's ScreneGraph features."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "2. New options when viewing slideshows including multi-scrolling images, fading photos and background blurs."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "3. New menu layout plus many other new features."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "4. Finally, don't forget to check out the channels embedded screensaver."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Bug fixes:"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "   - No bugs to report"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Thank you for using the PhotoView Channel. Please remember to rate us!"

    'Write reg entry to we don't redisplay
    RegWrite("FeaturePopup", m.releaseVersion, "Settings")
    
End Sub


Sub setThousandText()

    m.itemLabelHeader.text = "Large Album Details"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "Google limits the amount of media we can pull back per request to 1,000 items. To account for this limitation, your album is broken into pages to allow viewing."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Paging also allows accessing your photos much quicker as it reduces API calls. Be aware, a lower page number holds more recent media content."

    'Write reg entry to we don't redisplay
    RegWrite("ThousandPopup", "true", "Settings")
    
End Sub


Sub setAboutText()

    m.itemLabelHeader.text = "About Channel"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "The 'PhotoView for Google Photos' channel was developed by Chris Taylor. It's dedicated to his 2-year-old daughter, who goes nuts every time she sees photos of herself, on TV."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "It is and always will remain FREE, with no ads. We're committed to making this one of the best Photo Apps on the Roku platform."
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