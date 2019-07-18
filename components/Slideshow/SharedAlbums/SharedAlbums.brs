'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()  
    m.top.observeField("loaded","loadingComplete")
End Sub


Sub loadingComplete()
    m.top.unobserveField("loaded")

    m.screenActive = createObject("roSGNode", "Google Photos Albums")
    m.screenActive.id = "Shared Google Photos Albums"
    m.screenActive.loaded = true
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    'If nothing above is true, we'll fall back to the previous screen.
    return false
End function
