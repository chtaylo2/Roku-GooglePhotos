'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
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
    else if m.top.id = "ThousandPopup"
        setThousandText()
    else if m.top.id = "OverLoadPopup"
        setOverLoadText()
    else if m.top.id = "AboutChannel"
        setAboutText()
    end if
    
    m.buttonContinue.observeField("buttonSelected","onButtonPress")
End Sub


Sub setFeaturesText()

    m.itemLabelHeader.text = "New Channel Features"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "1. Continuous Video playback! Allows continuous looping of videos without having to manually hit play. Enable in settings."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "2. Photo captions are now viewable during slideshow playback. See Tips and Tricks."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "3. TIP: Screensaver can show specific albums. See 'Linked Users' in screensaver options."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Bug fixes:"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "   - Space in search caused an error"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "   - Other minor bugs"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Thank you for using the PhotoView Channel."

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


Sub setOverLoadText()

    m.itemLabelHeader.text = "Albums over 11,000 Items"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "Google Photo's API, unfortunately, does not allow pulling media after page 11. (Over 11,000 items)"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "To work around this limitation, it is recommended to break-up large albums into smaller, more manageable ones. For example, albums by Month or Year."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "If this limitation ever changes, this channel will be updated to handle."

    'Write reg entry to we don't redisplay
    RegWrite("ThousandPopup", "true", "Settings")
    
End Sub


Sub setAboutText()

    m.itemLabelHeader.text = "About Channel"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "The 'PhotoView for Google Photos' channel was developed by Chris Taylor. It's dedicated to his 2-year-old daughter, who goes nuts every time she herself on TV."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "This channel is and always will remain FREE, with no ads. We're committed to making this one of the best Photo Apps on the Roku platform."
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
