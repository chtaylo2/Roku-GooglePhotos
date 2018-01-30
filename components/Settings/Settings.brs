'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    ' Load in the OAuth Registry entries
    loadReg()

    'Define SG nodes
    m.pinPad            = m.top.findNode("pinPad")
    m.settingScopeLobal = m.top.findNode("settingScopeLobal")
    m.settingsList      = m.top.findNode("settingsLabelList")
    m.settingSubList    = m.top.findNode("settingSubList")
    m.regEntry          = m.top.findNode("RegistryTask")
    m.infoLabel         = m.top.findNode("infoLabel")
    m.infoTempSetting   = m.top.findNode("infoTempSetting")
    m.confirmDialog     = m.top.findNode("confirmDialog")
    
    m.pinPad.observeField("buttonSelected","processPinEntry")
    m.confirmDialog.observeField("buttonSelected","confirmUnregister")
End Sub


Sub loadListContent()

    if m.top.contentFile = "settingsTemporaryContent"
        'Temporary setting only apply to the running application
        m.setScope = "temporary"
    else if m.top.contentFile = "settingsScreensaverContent"
        'Screensaver setting
        m.setScope = "screensaver"
    else
        'Global settings are percistent across reboot
        m.setScope = "global"
    end if

    if m.setScope = "temporary"
        m.settingScopeLobal.text = "Temporary Settings:"
    else if m.setScope = "screensaver"
        m.settingScopeLobal.text = "Screensaver Settings:"
    end if

    'Read in Content
    m.readContentTask = createObject("roSGNode", "Local ContentReader")
    m.readContentTask.observeField("content", "setLists")
    m.readContentTask.file = "pkg:/data/Settings/" + m.top.contentFile + ".xml"
    m.readContentTask.control = "RUN"
End Sub


Sub setLists()
    'Setup content list for different settings
    storeLinkedUsers()
    storeResolutionOptions()
    storeDisplayOptions()
    storeDelayOptions()
    storeOrder()

    'Populate primary list content
    m.settingsList.content = m.readContentTask.content
    m.settingsList.setFocus(true)
End Sub


Sub storeResolutionOptions()
    'Populate screen resolution list content
    
    if m.setScope = "screensaver"
        regStore = "SSaverRes"
    else
        regStore = "SlideshowRes"
    end if
    
    radioSelection = 0
    regSelection = RegRead(regStore, "Settings")

    device  = createObject("roDeviceInfo")
    is4k    = (val(device.GetVideoMode()) = 2160)
    is1080p = (val(device.GetVideoMode()) = 1080)

    m.content = createObject("RoSGNode","ContentNode")
    
    if regSelection = "SD" then radioSelection = 0
    addItem(m.content, "Standard Definition (SD)", "SD", regStore)

    if is4k Or is1080p then
        if regSelection = "HD" then radioSelection = 1
        addItem(m.content, "High Definition (HD)", "HD", regStore)
    end if
    
    if is4k then
        if regSelection = "FHD" then radioSelection = 2
        addItem(m.content, "Full High Definition (FHD)", "FHD", regStore)
    end if

    'Store content node and current registry selection
    m.settingsRes = m.content
    m.settingsRescheckedItem = radioSelection
End Sub


Sub storeDisplayOptions()
    'Populate photo delay list content
    
    if m.setScope = "screensaver"
        regStore = "SSaverMethod"
    else
        regStore = "SlideshowDisplay"
    end if
    
    radioSelection = 0
    regSelection = RegRead(regStore, "Settings")

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "YesFading_YesBlur" then radioSelection = 0
    addItem(m.content, "Fading w/ Blackground Blur", "YesFading_YesBlur", regStore)
    if regSelection = "YesFading_NoBlur" then radioSelection = 1
    addItem(m.content, "Fading w/o Blackground Blur", "YesFading_NoBlur", regStore)
    if regSelection = "NoFading_YesBlur" then radioSelection = 2
    addItem(m.content, "No Fading w/ Blackground Blur", "NoFading_YesBlur", regStore)
    if regSelection = "NoFading_NoBlur" then radioSelection = 3
    addItem(m.content, "No Fading w/o Blackground Blur", "NoFading_NoBlur", regStore)
    if regSelection = "Multi-Scrolling" then radioSelection = 4
    addItem(m.content, "Multi-Scrolling Photos", "Multi-Scrolling", regStore)
    
    'Store content node and current registry selection
    m.settingsDisplay = m.content
    m.settingsDisplaycheckedItem = radioSelection
End Sub


Sub storeDelayOptions()
    'Populate photo delay list content
    
    if m.setScope = "screensaver"
        regStore = "SSaverDelay"
    else
        regStore = "SlideshowDelay"
    end if
    
    radioSelection = 0
    regSelection = RegRead(regStore, "Settings")

    tmp = ""
    if regSelection = "3"
        radioSelection = 0
    else if regSelection = "5"
        radioSelection = 1
    else if regSelection = "10"
        radioSelection = 2
    else if regSelection = "15"
        radioSelection = 3
    else if regSelection = "30"
        radioSelection = 4
    else
        radioSelection = 5
        tmp = "  [" + regSelection + " Seconds]"
    end if
    
    m.content = createObject("RoSGNode","ContentNode")
    addItem(m.content, "3 seconds", "3", regStore)
    addItem(m.content, "5 seconds (Default)", "5", regStore)
    addItem(m.content, "10 seconds", "10", regStore)
    addItem(m.content, "15 seconds", "15", regStore)
    addItem(m.content, "30 seconds", "30", regStore)
    addItem(m.content, "Custom Setting"+tmp, "9999", regStore)
    
    'Store content node and current registry selection
    m.settingsDelay = m.content
    m.settingsDelaycheckedItem = radioSelection
End Sub


Sub storeOrder()
    'Populate photo delay list content

    if m.setScope = "screensaver"
        regStore = "SSaverOrder"
    else
        regStore = "SlideshowOrder"
    end if
    
    radioSelection = 0
    regSelection = RegRead(regStore, "Settings")

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "Newest to Oldest" then radioSelection = 0
    addItem(m.content, "Newest to Oldest (Default)", "Newest to Oldest", regStore)
    if regSelection = "Oldest to Newest" then radioSelection = 1
    addItem(m.content, "Oldest to Newest", "Oldest to Newest", regStore)
    if regSelection = "Random Order" then radioSelection = 2
    addItem(m.content, "Random Order", "Random Order", regStore)
    
    'Store content node and current registry selection
    m.settingsOrder = m.content
    m.settingsOrdercheckedItem = radioSelection
End Sub


Sub storeLinkedUsers()
    'Populate linked user list
    
    usersLoaded     = oauth_count()
    radioSelection  = 0
    regStore        = "SSaverUser"
    regSelection    = RegRead(regStore, "Settings")
    m.content       = createObject("RoSGNode","ContentNode")
    
    if usersLoaded = 0 then
        addItem(m.content, "No users linked", "0", "")
    else
        for i = 0 to usersLoaded-1
            addItem(m.content,  m.userInfoName[i], m.userInfoEmail[i], regStore)
            if regSelection = m.userInfoEmail[i] then radioSelection = i
        end for
        if usersLoaded > 1 then
            addItem(m.content,  "All (Random)", "All (Random)", regStore)
            if regSelection = "All (Random)" then
                radioSelection = usersLoaded
            end if
        end if
    end if
    
    'Store content node and current registry selection
    m.settingsUsers = m.content
    m.settingsUserscheckedItem = radioSelection
End Sub


Sub addItem(store as object, itemtext as string, itemdesc as string, itemsection as string)
    item = store.createChild("ContentNode")
    item.title = itemtext
    item.description = itemdesc
    item.titleseason = itemsection
End Sub


Sub showfocus()
    'Show info for focused item
    if m.settingsList.content<>invalid then
        itemcontent = m.settingsList.content.getChild(m.settingsList.itemFocused)
        m.infoLabel.text = itemcontent.description
        
        'Temporary Setting
        if (itemcontent.shortdescriptionline1<>"" and m.global.[itemcontent.shortdescriptionline1] <> "")
            m.infoTempSetting.text = "Override Setting: " + m.global.[itemcontent.shortdescriptionline1]
        else
            m.infoTempSetting.text = ""
        end if
        
        if m.settingsList.itemFocused = 0 then
            m.settingSubList.visible        = "true"
            m.settingSubList.content        = m.settingsRes
            m.settingSubList.checkedItem    = m.settingsRescheckedItem
            m.settingSubList.translation    = [129, itemcontent.x]
        else if m.settingsList.itemFocused = 1 then
            m.settingSubList.visible        = "true"
            m.settingSubList.content        = m.settingsDisplay
            m.settingSubList.checkedItem    = m.settingsDisplaycheckedItem
            m.settingSubList.translation    = [129, itemcontent.x]
        else if m.settingsList.itemFocused = 2 then
            m.settingSubList.visible        = "true"
            m.settingSubList.content        = m.settingsDelay
            m.settingSubList.checkedItem    = m.settingsDelaycheckedItem
            m.settingSubList.translation    = [129, itemcontent.x]
        else if m.settingsList.itemFocused = 3 then
            m.settingSubList.visible        = "true"
            m.settingSubList.content        = m.settingsOrder
            m.settingSubList.checkedItem    = m.settingsOrdercheckedItem
            m.settingSubList.translation    = [129, itemcontent.x]
        else if m.settingsList.itemFocused = 4 then
            if m.setScope = "screensaver"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsUsers
                m.settingSubList.checkedItem    = m.settingsUserscheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]    
            else
                m.settingSubList.visible        = "false"
            end if
        else if m.settingsList.itemFocused = 5 then
            m.settingSubList.visible        = "false"
        else if m.settingsList.itemFocused = 6 then
            m.settingSubList.visible        = "false"
        end if
    end if 
End Sub


Sub showselected()

    'Process item selected
    if m.setScope = "screensaver"
        if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 OR m.settingsList.itemSelected = 4 then
            'SETTINGS
            m.settingSubList.setFocus(true)
        end if    
    else
        if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 then
            'SETTINGS
            m.settingSubList.setFocus(true)
        else if m.settingsList.itemSelected = 4 then
            'REGISTER NEW USER
            m.screenActive = createObject("roSGNode", "Registration")
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
            m.settingScopeLobal.visible = false
        else if m.settingsList.itemSelected = 5 then
            'UNREGISTER USER
            m.confirmDialog.visible = true
            buttons =  [ "Confirm", "Cancel" ]
            m.confirmDialog.message = "Are you sure you want to unregister "  + m.userInfoName[m.global.selectedUser] + " from this device?"
            m.confirmDialog.buttons = buttons
            m.confirmDialog.setFocus(true)        
        end if    
    end if
End Sub


Sub showsubselected()
    'Store item selected in registry
    itemcontent = m.settingSubList.content.getChild(m.settingSubList.itemSelected)

    if itemcontent.description = "9999" then
        m.pinPad.visible = true
        m.pinPad.pinPad.secureMode = false
        m.pinPad.pinPad.pinLength  = "3"
        buttons =  [ "Save", "Cancel" ]
        m.pinPad.buttons = buttons
        m.pinPad.setFocus(true)
    else
        if m.setScope = "temporary"
            'Temporary Setting
            m.global.[itemcontent.titleseason] = itemcontent.description
            m.infoTempSetting.text = "Override Setting: " + m.global.[itemcontent.titleseason]
        else if m.setScope = "screensaver"
            'Screensaver Setting
            RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
        else
            'Global Setting
            RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
        end if
    end if
    
    if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 1 then m.settingsDisplaycheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 2 then m.settingsDelaycheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 3 then m.settingsOrdercheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 4 then m.settingsUserscheckedItem = m.settingSubList.itemSelected    
End Sub


Sub confirmUnregister(event as object)
    if event.getData() = 0
        'CONFIRM
        loadItems()
        for each item in m.items
            m.[item].Delete(m.global.selectedUser)
            print m.[item]
        end for
        saveReg()
        m.global.selectedUser = -2
    else
        'CANCEL
        m.confirmDialog.visible = false
        m.settingsList.setFocus(true)
    end if
End Sub


Sub processPinEntry(event as object)
    if event.getData() = 0
        'SAVE
        pinInt = strtoi(m.pinPad.pin)
        if pinInt > 0
            itemcontent = m.settingSubList.content.getChild(m.settingSubList.itemSelected)
            
            if m.setScope = "temporary"
                'Temporary Setting
                m.global.[itemcontent.titleseason] = itostr(pinInt)
            else
                'Global Setting
                RegWrite(itemcontent.titleseason, itostr(pinInt), "Settings")
            end if
        end if
        
        storeDelayOptions()
        showfocus()
        m.pinPad.visible = false
        m.settingSubList.setFocus(true)
    else
        'CANCEL
        m.pinPad.visible = false
        m.settingSubList.setFocus(true)
    end if
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if (key = "right") and (m.pinPad.visible = false)
            m.settingsList.itemSelected = m.settingsList.itemFocused
            return true
        else if (key = "left") and (m.pinPad.visible = false) and (m.settingsList.hasFocus() = false)
            m.settingsList.setFocus(true)
            return true
        else if (key = "back") and (m.screenActive<>invalid)
            m.top.removeChild(m.screenActive)
            m.screenActive = invalid
            m.settingScopeLobal.visible = true
            m.settingsList.setFocus(true)
            return true
        else if (key = "back") and (m.settingsList.hasFocus() = false)
            m.settingsList.setFocus(true)
            m.pinPad.visible = false
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
