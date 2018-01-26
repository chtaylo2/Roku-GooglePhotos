'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    'Set scene properties
    m.top.backgroundURI   = ""
    m.top.backgroundColor = "#EBEBEB"
    m.top.setFocus(true)

    m.itemOverhang = m.top.findNode("itemOverhang")

    device = CreateObject("roDeviceInfo")
    ds = device.GetDisplaySize()
    
    'Load common variables
    loadCommon()

    'Load default settings
    loadDefaults()
    
    if ds.w = 720 then
        print "SD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_SD.png"
    else if ds.w = 1280 then
        print "HD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_HD.png"
    else
        print "FHD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_FHD.png"
    end if
    
    m.screenActive              = createObject("roSGNode", "Settings")
    m.screenActive.contentFile  = "settingsScreensaverContent"
    m.screenActive.id           = "settings"
    m.screenActive.loaded       = true
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub
