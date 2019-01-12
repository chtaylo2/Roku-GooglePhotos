'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumList","handleGetAlbumSelection")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    
    'Load common variables
    loadCommon()
    
    'Load privlanged variables
    loadPrivlanged()
    
    ' Load in the OAuth Registry entries
    loadReg()

    'Define SG nodes
    m.pinPad            = m.top.findNode("pinPad")
    m.settingScopeLabel = m.top.findNode("settingScopeLabel")
    m.settingsList      = m.top.findNode("settingsLabelList")
    m.settingSubList    = m.top.findNode("settingSubList")
    m.regEntry          = m.top.findNode("RegistryTask")
    m.infoLabel         = m.top.findNode("infoLabel")
    m.infoTempSetting   = m.top.findNode("infoTempSetting")
    m.confirmDialog     = m.top.findNode("confirmDialog")
    m.albumSelection    = m.top.findNode("albumSelection")
    m.albumDirections   = m.top.findNode("albumDirections")
    m.loadingSpinner    = m.top.findNode("loadingSpinner")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    m.aboutVersion      = m.top.findNode("aboutVersion")
    
    m.pinPad.observeField("buttonSelected","processPinEntry")
    m.confirmDialog.observeField("buttonSelected","confirmUnregister")
End Sub


Sub loadListContent()

    if m.top.contentFile = "settingsTemporaryContent"
        'Temporary setting only apply to the running application
        m.setScope           = "temporary"
    else if m.top.contentFile = "settingsScreensaverContent"
        'Screensaver setting
        m.setScope           = "screensaver"
    else
        'Global settings are percistent across reboot
        appInfo              = CreateObject("roAppInfo")
        m.setScope           = "global"
        m.aboutVersion.text  = "Release v" + m.releaseVersion + " - Build " + appInfo.GetVersion()
    end if

    if m.setScope = "temporary"
        m.settingScopeLabel.text = "Temporary Settings:"
    else if m.setScope = "screensaver"
        m.settingScopeLabel.text = "Screensaver Settings:"
    end if

    'Read in Content
    m.readContentTask = createObject("roSGNode", "Local ContentReader")
    m.readContentTask.observeField("content", "setLists")
    m.readContentTask.file = "pkg:/data/Settings/" + m.top.contentFile + ".xml"
    m.readContentTask.control = "RUN"
End Sub


' URL Request to fetch album listing - Used for screensaver album selection
Sub doGetAlbumSelection()
    print "Settings.brs [doGetAlbumSelection]"  

    usersLoaded               = oauth_count()
    selectedUser              = m.settingSubList.itemFocused
    m.albumDirections.visible = "false"
    m.albumSelection.content  = ""
    m.albumSelection.visible  = true
    m.albumSelection.setFocus(true)
            
    m.infoLabel.text = "Select albums to display while the screensaver is active. If none are selected, random photos will be shown. Only the first 1,000 images, per album, are pulled."

    tmpData = [ "doGetAlbumSelection", selectedUser ]

    if selectedUser <> usersLoaded then
        m.loadingSpinner.visible = true
        m.infoLabel.text = m.infoLabel.text + chr(10) + chr(10) + "Current user selected: " + m.userInfoName[selectedUser]
        signedHeader = oauth_sign(selectedUser)
        makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=300", "GET", "", 0, tmpData)
    else
        m.infoLabel.text = m.infoLabel.text + chr(10) + chr(10) + "Unable to select albums for 'All (Random)'. A future version might allow this."
    end if
End Sub


Sub handleGetAlbumSelection(event as object)
    print "Settings.brs [handleGetAlbumSelection]"
  
    m.albumContent = createObject("RoSGNode","ContentNode")
    errorMsg       = ""
    response       = event.getData()
    regStore       = "SSaverAlbums"
    regAlbums      = RegRead(regStore, "Settings")
    checkedObj     = []

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[1])
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumSelection'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else

            'Display Time in History selections
            albumHistory = "Day|Week|Month".Split("|")
            for each album in albumHistory
                addItem(m.albumContent, "• "+album+" in History - Auto Refresh", album, "")
                saved = 0
                if (regAlbums <> invalid) and (regAlbums <> "")
                    parsedString = regAlbums.Split("|")
                    for each item in parsedString
                        albumUser = item.Split(":")
                        if albumUser[0] = album then
                            'Check selected album
                            saved = 1
                        end if
                    end for
                end if
                if saved = 1 checkedObj.Push(true)
                if saved = 0 checkedObj.Push(false)                
            end for
            
            'Display user album selections
            m.albumsObject = googleAlbumListing(rsp.entry)
            for each album in m.albumsObject
                addItem(m.albumContent, album.GetTitle(), album.GetID(), "")
                saved = 0
                if (regAlbums <> invalid) and (regAlbums <> "")
                    parsedString = regAlbums.Split("|")
                    for each item in parsedString
                        albumUser = item.Split(":")
                        if albumUser[0] = album.GetID() then
                            'Check selected album
                            saved = 1
                        end if
                    end for
                end if
                if saved = 1 checkedObj.Push(true)
                if saved = 0 checkedObj.Push(false)
            end for

            m.albumSelection.content = m.albumContent
            m.albumSelection.checkedState = checkedObj
        end if
    end if
    
    m.loadingSpinner.visible = false
    
    if errorMsg<>"" then
        'ShowNotice
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if   
    
End Sub


Sub setLists()
    'Setup content list for different settings
    storeLinkedUsers()
    storeResolutionOptions()
    storeDisplayOptions()
    storeDelayOptions()
    storeOrder()
    storeVideoOptions()

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

        if regSelection = "UHD" then radioSelection = 3
        addItem(m.content, "Ultra High Definition [Beta]", "UHD", regStore)               
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
    if regSelection = "Album Order" then radioSelection = 0
    addItem(m.content, "Album Order (Default)", "Album Order", regStore)
    if regSelection = "Reverse Album Order" then radioSelection = 1
    addItem(m.content, "Reverse Album Order", "Reverse Album Order", regStore)
    if regSelection = "Random Order" then radioSelection = 2
    addItem(m.content, "Random Order", "Random Order", regStore)
    
    'Store content node and current registry selection
    m.settingsOrder = m.content
    m.settingsOrdercheckedItem = radioSelection
End Sub


Sub storeVideoOptions()
    'Populate Video playback options

    if m.setScope = "screensaver"
        regStore = "SSaverVideo"
    else
        regStore = "VideoContinuePlay"
    end if
    
    radioSelection = 0
    regSelection = RegRead(regStore, "Settings")

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "Single Video Playback" then radioSelection = 0
    addItem(m.content, "Single Video Playback (Default)", "Single Video Playback", regStore)
    if regSelection = "Continuous Video Playback" then radioSelection = 1
    addItem(m.content, "Continuous Video Playback", "Continuous Video Playback", regStore)
    
    'Store content node and current registry selection
    m.settingsVideo = m.content
    m.settingsVideocheckedItem = radioSelection
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
        
        m.albumDirections.visible = "false"
        m.aboutVersion.visible    = "false"
        
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
            if m.setScope <> "screensaver"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsVideo
                m.settingSubList.checkedItem    = m.settingsVideocheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else
                m.settingSubList.visible        = "false"
            end if
        else if m.settingsList.itemFocused = 5 then
            if m.setScope = "screensaver"
                m.albumDirections.visible       = "true"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsUsers
                m.settingSubList.checkedItem    = m.settingsUserscheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else
                m.settingSubList.visible        = "false"
            end if
        else if m.settingsList.itemFocused = 6 then
            m.settingSubList.visible        = "false"
        else if m.settingsList.itemFocused = 7 then
            m.settingSubList.visible        = "false"
            m.aboutVersion.visible          = "true"
        end if
    end if 
End Sub


Sub showselected()

    'Process item selected
    if m.setScope = "screensaver"
        if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 OR m.settingsList.itemSelected = 5 then
            'SETTINGS
            m.settingSubList.setFocus(true)
        end if    
    else
        if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 OR m.settingsList.itemSelected = 4 then
            'SETTINGS
            m.settingSubList.setFocus(true)
        else if m.settingsList.itemSelected = 5 then
            'REGISTER NEW USER
            m.screenActive = createObject("roSGNode", "Registration")
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
            m.settingScopeLabel.visible = false
        else if m.settingsList.itemSelected = 6 then
            'UNREGISTER USER
            m.confirmDialog.visible = true
            buttons                 =  [ "Confirm", "Cancel" ]
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
        m.pinPad.visible            = true
        m.pinPad.pinPad.secureMode  = false
        m.pinPad.pinPad.pinLength   = "3"
        buttons                     =  [ "Save", "Cancel" ]
        m.pinPad.buttons            = buttons
        m.pinPad.setFocus(true)
    else
        if m.setScope = "temporary"
            'Temporary Setting
            m.global.[itemcontent.titleseason] = itemcontent.description
            m.infoTempSetting.text = "Override Setting: " + m.global.[itemcontent.titleseason]
        else if m.setScope = "screensaver"
            'Screensaver Setting
            RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
            
            if (m.settingsList.itemSelected = 4) and (m.settingsUserscheckedItem <> m.settingSubList.itemSelected) then
                'Reset any album selections
                RegWrite("SSaverAlbums", "", "Settings")
            end if
        else
            'Global Setting
            RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
        end if
    end if
    
    if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem     = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 1 then m.settingsDisplaycheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 2 then m.settingsDelaycheckedItem   = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 3 then m.settingsOrdercheckedItem   = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 4 then m.settingsVideocheckedItem   = m.settingSubList.itemSelected    
    if m.settingsList.itemSelected = 5 then m.settingsUserscheckedItem   = m.settingSubList.itemSelected    
End Sub


Sub showalbumselected()
    regStore     = "SSaverAlbums"
    regAlbums    = RegRead(regStore, "Settings")    
    selectedUser = m.settingSubList.itemFocused
    albumsTotal  = m.albumSelection.content.getChildCount()
    
    saveList = ""
    for i = 0 to albumsTotal
        itemcontent  = m.albumSelection.content.getChild(i)
        checkState   = m.albumSelection.checkedState[i]
        if checkState = true then
            saveList = saveList + itemcontent.description + ":" + itostr(selectedUser) + "|"
        end if
    end for
    
    RegWrite(regStore, saveList, "Settings")       
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


Sub noticeClose(event as object)
    m.noticeDialog.visible   = false
    m.loadingSpinner.visible = false
    'm.albummarkupgrid.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if (key = "options" or key = "right") and (m.settingSubList.hasFocus() = true) and (m.settingsList.itemFocused = 5)
            'Select Linked User
            doGetAlbumSelection()
            m.settingSubList.itemSelected = m.settingSubList.itemFocused
            m.settingSubList.visible = false
            return true
        else if (key = "back" or key = "left") and (m.albumSelection.hasFocus() = true)
            m.settingSubList.visible = true
            m.albumSelection.visible = false
            m.settingSubList.setFocus(true)
            showfocus()
            return true
        else if (key = "right") and (m.pinPad.visible = false) and (m.albumSelection.hasFocus() = false)
            m.settingsList.itemSelected = m.settingsList.itemFocused
            return true
        else if (key = "left") and (m.pinPad.visible = false) and (m.settingsList.hasFocus() = false)
            m.settingsList.setFocus(true)
            return true
        else if (key = "back") and (m.screenActive<>invalid)
            m.top.removeChild(m.screenActive)
            m.screenActive              = invalid
            m.settingScopeLabel.visible = true
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
