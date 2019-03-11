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

    m.itemOverhang  = m.top.findNode("itemOverhang")

    device = CreateObject("roDeviceInfo")
    ds = device.GetDisplaySize()
    
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
        
    'Load common variables
    loadCommon()
    
    'Load default settings
    loadDefaults()
    
    'Define SG nodes
    m.itemHeader = m.top.findNode("itemHeader")
    
    'Observe user selected
    m.global.observeField("selectedUser", "mainLoad")
    
    'Show new features popup once
    lastPopup = RegRead("FeaturePopup","Settings")
    if (lastPopup = invalid) or (lastPopup <> m.releaseVersion) then
        showFeaturesPopup()
    else
        checkRegistration()
    end if
End Sub


Function showFeaturesPopup()
    m.itemHeader.text       = "Version " + m.releaseVersion + " • New Features"
    m.screenActive          = createObject("roSGNode", "InfoPopup")
    m.screenActive.id       = "FeaturesPopup"
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Function


Function checkRegistration()

    ' Load in the OAuth Registry entries
    loadReg()

    'Check for linked user
    usersLoaded = oauth_count()

    if usersLoaded = 0 then
        m.itemHeader.text   = "Registration"
        m.screenActive      = createObject("roSGNode", "Registration")
        m.screenActive.id   = "Registration"
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
        if m.screenKill<>invalid then
            m.top.removeChild(m.screenKill)
        end if
        
    else if usersLoaded = 1 then
        'Show only registered user
        m.global.selectedUser = 0
        m.top.selectedUser = 0
        mainLoad()
    else
        selectionLoad()
    end if
End function


Function reRegistrar()
    'REGISTER NEW USER
    m.itemHeader.text   = "Registration"
    m.screenActive = createObject("roSGNode", "Registration")
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)  

    if m.screenKill<>invalid then
        m.top.removeChild(m.screenKill)
    end if
End function


Function selectionLoad()
    m.itemHeader.text   = "Select User"
    m.screenActive      = createObject("roSGNode", "UserSelection")
    m.screenActive.id   = "UserSelection"
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
    
    if m.screenKill<>invalid then
        m.top.removeChild(m.screenKill)
    end if
End function


Function mainLoad()

    usersLoaded = oauth_count()
    print "USERS LOADED: "; usersLoaded
    print "SELECTED USER: "; m.global.selectedUser

    if (m.global.selectedUser <> usersLoaded) and (m.global.selectedUser <> -1) and (m.global.selectedUser <> -2) and (m.global.selectedUser <> -3) and (m.global.selectedUser <> -4)

        'The following to for v2.x to v3 migration. Can be removed in a later version (Sometime after August, 2019)
        if m.versionToken[m.global.selectedUser] = "v2token" then
            m.screenActive          = createObject("roSGNode", "ExpiredPopup")
            m.screenActive.id       = "RelinkPopup"
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
        else
            'A user was selected, display!
           m.itemHeader.text = ""
           m.top.removeChild(m.screenActive)
           m.screenActive      = createObject("roSGNode", "MainMenu")
           m.screenActive.id   = "MainMenu"
           m.top.appendChild(m.screenActive)
           m.screenActive.setFocus(true)       
        end if

    else if m.global.selectedUser = usersLoaded
        'So user can reselect
        m.global.selectedUser = -4
        'Add new user account
        m.screenKill = m.screenActive
        reRegistrar()
    else if m.global.selectedUser = -2
        'A user was unregistered
        m.screenKill = m.screenActive
        checkRegistration()
    else if m.global.selectedUser = -3
        'A users refresh token expired
        m.screenKill = m.screenActive
        reRegistrar()
    end if
End function


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY (GooglephotosMain): "; key
        if key = "back"
            if (m.screenActive <> invalid) and (m.screenActive.id = "UserSelection" or m.screenActive.id = "Registration" or m.screenActive.id = "FeaturesPopup")
                return false
            else if (m.screenActive <> invalid) and (m.screenActive.id <> "Registration")
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                selectionLoad()
                return true
            else
                return true
            end if
        else if key = "OK"
            if (m.screenActive <> invalid) and (m.screenActive.id = "FeaturesPopup")
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                checkRegistration()
                return true
            end if
        end if
    end if
    return false
End function
