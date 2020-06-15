'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2020 Chris Taylor.  All rights reserved.
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
    m.albumsObject      = {}
    m.apiPending        = 0
    
    m.pinPad.observeField("buttonSelected","processPinEntry")
    m.confirmDialog.observeField("buttonSelected","confirmUnregister")
End Sub


Sub loadListContent()

    appInfo              = CreateObject("roAppInfo")
    m.aboutVersion.text  = "Release v" + m.releaseVersion + " - Build " + appInfo.GetVersion()
    
    if m.top.contentFile = "settingsTemporaryContent"
        'Temporary setting only apply to the running application
        m.setScope           = "temporary"
    else if m.top.contentFile = "settingsScreensaverContent"
        'Screensaver setting
        m.setScope           = "screensaver"
    else
        'Global settings are percistent across reboot
        m.setScope           = "global"
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
Sub doGetAlbumSelection(pageNext="" As String)
    print "Settings.brs [doGetAlbumSelection]"  

    usersLoaded               = oauth_count()
    selectedUser              = m.settingSubList.itemFocused
    m.albumDirections.visible = "false"
    m.albumSelection.content  = ""
    m.albumSelection.visible  = true
    m.albumSelection.setFocus(true)
            
    m.infoLabel.text = "Select albums to display while the screensaver is active. If none are selected, random photos will be shown. Only the first 1,000 images, per album, are pulled."

    tmpData = [ "doGetAlbumSelection", selectedUser, pageNext ]

    if selectedUser <> usersLoaded then
        m.loadingSpinner.visible = true
        m.infoLabel.text = m.infoLabel.text + chr(10) + chr(10) + "Current user selected: " + m.userInfoEmail[selectedUser]
        doGetAlbumList(selectedUser, pageNext)
    
    else
        m.infoLabel.text = m.infoLabel.text + chr(10) + chr(10) + "Unable to select albums for 'All (Random)'. A future version might allow this."
    end if
End Sub


Sub handleGetAlbumSelection(event as object)
    print "Settings.brs [handleGetAlbumSelection]"
  
    errorMsg       = ""
    response       = event.getData()

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[1])
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumSelection'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)
        'print rsp["albums"]
        if rsp = invalid
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetAlbumSelection"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetAlbumSelection] " + json.error
        else
            albumList = googleAlbumListing(rsp)         
            
            for each album in albumList
                if m.sharedAPIpull = 1 then
                    album.GetTitle = "Shared: " + album.GetTitle
                end if
                m.albumsObject["albums"].Push(album)
            end for          

            if m.sharedAPIpull = 0 then
                if rsp["nextPageToken"]<>invalid then
                    pageNext = rsp["nextPageToken"]
                    m.albumsObject.nextPageToken = pageNext
                    m.albumsObject.apiCount = m.albumsObject.apiCount + 1
                    if m.albumsObject.apiCount < m.maxApiPerPage then
                        doGetAlbumList(m.settingSubList.itemFocused, pageNext)
                    else
                        m.sharedAPIpull = 1
                        doGetSharedAlbumList(m.settingSubList.itemFocused, "")
                    end if
                else
                    m.sharedAPIpull = 1
                    doGetSharedAlbumList(m.settingSubList.itemFocused, "")
                end if
            else
                 if rsp["nextPageToken"]<>invalid then
                    pageNext = rsp["nextPageToken"]
                    m.albumsObject.nextPageToken = pageNext
                    m.albumsObject.apiCountShared = m.albumsObject.apiCountShared + 1
                    if m.albumsObject.apiCount < m.maxApiPerPage then
                        doGetSharedAlbumList(m.settingSubList.itemFocused, pageNext)
                    else
                        printAlbumSelection(m.albumsObject["albums"])
                    end if
                else
                    printAlbumSelection(m.albumsObject["albums"])
                end if           
            end if    
        end if
    end if
    
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


Sub printAlbumSelection(albumList As Object)
    print "Settings.brs [printAlbumSelection]"
    
    m.albumContent = createObject("RoSGNode","ContentNode")
    regStore       = "SSaverAlbums"
    regAlbums      = RegRead(regStore, "Settings")
    checkedObj     = []
    
    date  = CreateObject("roDateTime")
    date.ToLocalTime()
    cYear = date.GetYear()    
    
    m.loadingSpinner.visible = "false"
    
    'Display Time in History selections
    c = 0    
    albumHistory = "Day|Daywithcurr|Week|Weekwithcurr|Month|Monthwithcurr".Split("|")
    albumHistoryTxt = "Day|Day|Week|Week|Month|Month".Split("|")
    for each album in albumHistory
        if album.Instr("withcurr") >= 0 then
            addItem(m.albumContent, "• "+albumHistoryTxt[c]+" in History including " + cYear.ToStr(), album, "")
        else
            addItem(m.albumContent, "• "+albumHistoryTxt[c]+" in History", album, "")
        end if
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
        c = c + 1
    end for
            
    'Display Google Photos Library
    addItem(m.albumContent, "Google Photos Library", "GP_LIBRARY", "")
    saved = 0
    if (regAlbums <> invalid) and (regAlbums <> "")
        parsedString = regAlbums.Split("|")
        for each item in parsedString
            albumUser = item.Split(":")
            if (albumUser[0] = "GP_LIBRARY") then
                'Check selected album
                saved = 1
            end if
        end for
    end if
    if saved = 1 checkedObj.Push(true)
    if saved = 0 checkedObj.Push(false)
            
    'Display user album selections
    for each album in albumList
        addItem(m.albumContent, album.GetTitle, album.GetID, "")
        saved = 0
        if (regAlbums <> invalid) and (regAlbums <> "")
            parsedString = regAlbums.Split("|")
            for each item in parsedString
                albumUser = item.Split(":")
                if albumUser[0] = album.GetID then
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
    
End Sub


Sub setLists()
    'Setup content list for different settings
    storeLinkedUsers()
    storeCECOptions()
    storeDateTimeOptions()
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

    is4k    = (val(m.device.GetVideoMode()) >= 2160)
    is1080p = (val(m.device.GetVideoMode()) = 1080)
    is720p  = (val(m.device.GetVideoMode()) = 720)
    
    print "RES: "; val(m.device.GetVideoMode())

    m.content = createObject("RoSGNode","ContentNode")
    
    if regSelection = "SD" then radioSelection = 0
    addItem(m.content, "Standard Definition 480p (SD)", "SD", regStore)

    if is4k Or is1080p Or is720p then
        if regSelection = "HD720" then radioSelection = 1
        addItem(m.content, "High Definition 720p (HD)", "HD720", regStore)
    end if
    
    if is4k Or is1080p then
        if (regSelection = "FHD" or regSelection = "HD") then radioSelection = 2
        addItem(m.content, "Full High Definition 1080p (FHD)", "FHD", regStore)
    end if
    
    if is4k then
        if regSelection = "UHD" then radioSelection = 3
        addItem(m.content, "Ultra High Definition 4K (UHD)", "UHD", regStore)               
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
    if regSelection = "5"
        radioSelection = 0
    else if regSelection = "8"
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
    
    if m.setScope = "screensaver"
        addItem(m.content, "5 seconds", "5", regStore)
        addItem(m.content, "8 seconds", "8", regStore)
        addItem(m.content, "10 seconds", "10", regStore)
        addItem(m.content, "15 seconds (Default)", "15", regStore)
        addItem(m.content, "30 seconds", "30", regStore)
        addItem(m.content, "Custom Setting"+tmp, "9999", regStore)
    else
        addItem(m.content, "5 seconds", "5", regStore)
        addItem(m.content, "8 seconds (Default)", "8", regStore)
        addItem(m.content, "10 seconds", "10", regStore)
        addItem(m.content, "15 seconds", "15", regStore)
        addItem(m.content, "30 seconds", "30", regStore)
        addItem(m.content, "Custom Setting"+tmp, "9999", regStore)
    end if
    
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
    if regSelection = "Reverse Album Order" then radioSelection = 1
    if regSelection = "Random Order" then radioSelection = 2
    
    if m.setScope = "screensaver"
        addItem(m.content, "Album Order", "Album Order", regStore)
        addItem(m.content, "Reverse Album Order", "Reverse Album Order", regStore)
        addItem(m.content, "Random Order  (Default)", "Random Order", regStore)
    else
        addItem(m.content, "Album Order (Default)", "Album Order", regStore)
        addItem(m.content, "Reverse Album Order", "Reverse Album Order", regStore)
        addItem(m.content, "Random Order", "Random Order", regStore)    
    end if
    
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
            addItem(m.content,  m.userInfoEmail[i], m.userInfoEmail[i], regStore)
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


Sub storeDateTimeOptions()
    'Populate Date/Time options
    
    radioSelection = 0
    regStore       = "SSaverTime"
    regSelection   = RegRead(regStore, "Settings")

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "Disabled" then radioSelection = 0
    addItem(m.content, "Disabled (Default)", "Disabled", regStore)
    if regSelection = "Enabled" then radioSelection = 1
    addItem(m.content, "Enabled", "Enabled", regStore)
    
    'Store content node and current registry selection
    m.settingsTime = m.content
    m.settingsTimecheckedItem = radioSelection
End Sub


Sub storeCECOptions()
    'Populate HDMI-CEC options
    
    radioSelection = 0
    regStore       = "SSaverCEC"
    regSelection   = RegRead(regStore, "Settings")

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "HDMI-CEC Enabled" then radioSelection = 0
    addItem(m.content, "HDMI-CEC Enabled (Default)", "HDMI-CEC Enabled", regStore)
    if regSelection = "HDMI-CEC Disabled" then radioSelection = 1
    addItem(m.content, "HDMI-CEC Disabled", "HDMI-CEC Disabled", regStore)
    
    'Store content node and current registry selection
    m.settingsCEC = m.content
    m.settingsCECcheckedItem = radioSelection
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
        
        m.albumDirections.visible = "false"
        m.aboutVersion.visible    = "false"
        
        if m.setScope = "screensaver"
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
                m.albumDirections.visible       = "false"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsTime
                m.settingSubList.checkedItem    = m.settingsTimecheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else if m.settingsList.itemFocused = 5 then
                m.albumDirections.visible       = "false"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsCEC
                m.settingSubList.checkedItem    = m.settingsCECcheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else if m.settingsList.itemFocused = 6 then    
                m.albumDirections.visible       = "true"
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsUsers
                m.settingSubList.checkedItem    = m.settingsUserscheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else if m.settingsList.itemFocused = 7 then
                m.settingSubList.visible        = "false"
                m.aboutVersion.visible          = "true"
            end if
            
        else
        
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
                m.settingSubList.visible        = "true"
                m.settingSubList.content        = m.settingsVideo
                m.settingSubList.checkedItem    = m.settingsVideocheckedItem
                m.settingSubList.translation    = [129, itemcontent.x]
            else if m.settingsList.itemFocused = 5 then
                m.settingSubList.visible        = "false"
            else if m.settingsList.itemFocused = 6 then
                m.settingSubList.visible        = "false"
            else if m.settingsList.itemFocused = 7 then
                m.settingSubList.visible        = "false"
                m.aboutVersion.visible          = "true"
            end if        
        end if
    end if 
End Sub


Sub showselected()

    'Process item selected
    if m.setScope = "screensaver"
        if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 OR m.settingsList.itemSelected = 4 OR m.settingsList.itemSelected = 5 OR m.settingsList.itemSelected = 6 then
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
            m.confirmDialog.message = "Are you sure you want to unregister "  + m.userInfoEmail[m.global.selectedUser] + " from this device?"
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
            
            if (m.settingsList.itemSelected = 5) and (m.settingsUserscheckedItem <> m.settingSubList.itemSelected) then
                'Reset any album selections - new user selected
                RegWrite("SSaverAlbums", "", "Settings")
            end if
        else
            'Global Setting
            RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
        end if
    end if
    
    
    if m.setScope = "screensaver"
        if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem     = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 1 then m.settingsDisplaycheckedItem = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 2 then m.settingsDelaycheckedItem   = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 3 then m.settingsOrdercheckedItem   = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 4 then m.settingsTimecheckedItem    = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 5 then m.settingsCECcheckedItem     = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 6 then m.settingsUserscheckedItem   = m.settingSubList.itemSelected
    else
        if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem     = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 1 then m.settingsDisplaycheckedItem = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 2 then m.settingsDelaycheckedItem   = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 3 then m.settingsOrdercheckedItem   = m.settingSubList.itemSelected
        if m.settingsList.itemSelected = 4 then m.settingsVideocheckedItem   = m.settingSubList.itemSelected    
    end if
End Sub


Sub showalbumselected()
    regStore     = "SSaverAlbums"
    regAlbums    = RegRead(regStore, "Settings")    
    selectedUser = m.settingSubList.itemFocused
    albumsTotal  = m.albumSelection.content.getChildCount()
    
    saveList    = ""
    errorMsg    = ""
    selectCount = 0
    for i = 0 to albumsTotal
        itemcontent  = m.albumSelection.content.getChild(i)
        checkState   = m.albumSelection.checkedState[i]
        if checkState = true then
            if m.albumSelection.checkedState[5] = true then
                saveList = m.albumSelection.content.getChild(5).description + ":" + itostr(selectedUser) + "|"
            else if m.albumSelection.checkedState[4] = true then
                saveList = m.albumSelection.content.getChild(4).description + ":" + itostr(selectedUser) + "|"
            else if m.albumSelection.checkedState[3] = true then
                saveList = m.albumSelection.content.getChild(3).description + ":" + itostr(selectedUser) + "|"
            else if m.albumSelection.checkedState[2] = true then
                saveList = m.albumSelection.content.getChild(2).description + ":" + itostr(selectedUser) + "|"
            else if m.albumSelection.checkedState[1] = true then
                saveList = m.albumSelection.content.getChild(1).description + ":" + itostr(selectedUser) + "|"
            else if m.albumSelection.checkedState[0] = true then
                saveList = m.albumSelection.content.getChild(0).description + ":" + itostr(selectedUser) + "|"
            else
                'Control the number of API calls we make. Sorry but Google monitors this.
                if selectCount < 5 then
                    saveList = saveList + itemcontent.description + ":" + itostr(selectedUser) + "|"
                    selectCount = selectCount + 1
                else
                    errorMsg = "You may select 5 albums max, for screensaver playback. Other album selections will not be saved."
                end if
            end if
            
            if (m.albumSelection.checkedState[5] = true or m.albumSelection.checkedState[4] = true or m.albumSelection.checkedState[3] = true or m.albumSelection.checkedState[2] = true or m.albumSelection.checkedState[1] = true or m.albumSelection.checkedState[0] = true) and (i > 5) then
                errorMsg = "Time in history albums are currently mutually exclusive. Other album selections will not be saved."
            end if
        end if
    end for
    
    if errorMsg<>"" then
        'ShowError
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.title   = "Notice"
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if
    
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
        if pinInt < 5
            'ShowError
            m.noticeDialog.visible = true
            buttons =  [ "OK" ]
            m.noticeDialog.title   = "Notice"
            m.noticeDialog.message = "Delay must be greater then 5 seconds due to requirements from Google."
            m.noticeDialog.buttons = buttons
            m.noticeDialog.setFocus(true)
            m.noticeDialog.observeField("buttonSelected","noticeClose2")
        else
            itemcontent = m.settingSubList.content.getChild(m.settingSubList.itemSelected)
            
            if m.setScope = "temporary"
                'Temporary Setting
                m.global.[itemcontent.titleseason] = itostr(pinInt)
            else
                'Global Setting
                RegWrite(itemcontent.titleseason, itostr(pinInt), "Settings")
            end if
        
            storeDelayOptions()
            showfocus()
            m.pinPad.visible = false
            m.settingSubList.setFocus(true)
        end if
    else
        'CANCEL
        m.pinPad.visible = false
        m.settingSubList.setFocus(true)
    end if
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible   = false
    m.loadingSpinner.visible = false
    m.albumSelection.setFocus(true)
End Sub

Sub noticeClose2(event as object)
    m.noticeDialog.visible   = false
    m.pinPad.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if (key = "options" or key = "right") and (m.settingSubList.hasFocus() = true) and (m.settingsList.itemFocused = 6)
            'Select Linked User
            m.sharedAPIpull = 0
            m.albumsObject["albums"] = []
            m.albumsObject.apiCount = 0
            m.albumsObject.apiCountShared = 0
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
