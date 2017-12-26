
Sub init()

    ' Load in the OAuth Registry entries
    loadReg()

    'Define SG nodes
    m.pinRectangle = m.top.findNode("pinRectangle")
    m.pinPad = m.top.findNode("pinPad")
    
    m.settingsList = m.top.findNode("settingsLabelList")
    m.settingSubList = m.top.findNode("settingSubList")
    m.regEntry = m.top.findNode("RegistryTask")
    m.infoLabel = m.top.findNode("infoLabel")
      
    'Read in Content
    m.readContentTask = createObject("roSGNode", "Local ContentReader")
    m.readContentTask.observeField("content", "setLists")
    m.readContentTask.file = "pkg:/data/Settings/settingsContent.xml"
    m.readContentTask.control = "RUN"
End Sub


Sub setLists()
    'Setup content list for different settings
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
    regStore = "SlideshowRes"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    device = createObject("roDeviceInfo")
    is4k = (val(device.GetVideoMode()) = 2160)
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
    regStore = "SlideshowDisplay"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "YesFading_YesBlur" then radioSelection = 0
    addItem(m.content, "Fading w/ Blackground Blur", "YesFading_YesBlur", regStore)
    if regSelection = "YesFading_NoBlur" then radioSelection = 1
    addItem(m.content, "Fading w/o Blackground Blur", "YesFading_NoBlur", regStore)
    if regSelection = "NoFading_YesBlur" then radioSelection = 2
    addItem(m.content, "No Fading w/ Blackground Blur", "NoFading_YesBlur", regStore)
    if regSelection = "NoFading_NoBlur" then radioSelection = 3
    addItem(m.content, "No Fading w/o Blackground Blur", "NoFading_NoBlur", regStore)
    if regSelection = "multi" then radioSelection = 4
    addItem(m.content, "Multi-Scrolling Photos", "multi", regStore)
    
    'Store content node and current registry selection
    m.settingsDisplay = m.content
    m.settingsDisplaycheckedItem = radioSelection
End Sub


Sub storeDelayOptions()
    'Populate photo delay list content
    regStore = "SlideshowDelay"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "3" then radioSelection = 0
    addItem(m.content, "3 seconds", "3", regStore)
    if regSelection = "5" then radioSelection = 1
    addItem(m.content, "5 seconds (Default)", "5", regStore)
    if regSelection = "10" then radioSelection = 2
    addItem(m.content, "10 Seconds", "10", regStore)
    if regSelection = "15" then radioSelection = 3
    addItem(m.content, "15 Seconds", "15", regStore)
    if regSelection = "30" then radioSelection = 4
    addItem(m.content, "30 seconds", "30", regStore)
    if regSelection = "0" then radioSelection = 5
    addItem(m.content, "Custom Setting", "0", regStore)
    
    'Store content node and current registry selection
    m.settingsDelay = m.content
    m.settingsDelaycheckedItem = radioSelection
End Sub


Sub storeOrder()
    'Populate photo delay list content
    regStore = "SlideshowOrder"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "newest" then radioSelection = 0
    addItem(m.content, "Newest to Oldest (Default)", "newest", regStore)
    if regSelection = "oldest" then radioSelection = 1
    addItem(m.content, "Oldest to Newest", "oldest", regStore)
    if regSelection = "random" then radioSelection = 2
    addItem(m.content, "Random Order", "random", regStore)
    
    'Store content node and current registry selection
    m.settingsOrder = m.content
    m.settingsOrdercheckedItem = radioSelection
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
        
        if m.settingsList.itemFocused = 0 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsRes
            m.settingSubList.checkedItem = m.settingsRescheckedItem
            m.settingSubList.translation = [85, itemcontent.x]
        else if m.settingsList.itemFocused = 1 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsDisplay
            m.settingSubList.checkedItem = m.settingsDisplaycheckedItem
            m.settingSubList.translation = [85, itemcontent.x]
        else if m.settingsList.itemFocused = 2 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsDelay
            m.settingSubList.checkedItem = m.settingsDelaycheckedItem
            m.settingSubList.translation = [85, itemcontent.x]
        else if m.settingsList.itemFocused = 3 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsOrder
            m.settingSubList.checkedItem = m.settingsOrdercheckedItem
            m.settingSubList.translation = [85, itemcontent.x]
        else if m.settingsList.itemFocused = 4 then
            m.settingSubList.visible = "false"
        else if m.settingsList.itemFocused = 5 then
            m.settingSubList.visible = "false"
        else if m.settingsList.itemFocused = 6 then
            m.settingSubList.visible = "false"
        end if
    end if 
End Sub


Sub showselected()
    'Process item selected
    if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 OR m.settingsList.itemSelected = 2 OR m.settingsList.itemSelected = 3 then
        'SETTINGS
        m.settingSubList.setFocus(true)
    else if m.settingsList.itemSelected = 4 then
        'REGISTER NEW USER
        'm.screenActive = createObject("roSGNode", "Registration")
        'm.top.appendChild(m.screenActive)
        'm.screenActive.setFocus(true)
    else if m.settingsList.itemSelected = 5 then
        'UNREGISTER USER

        loadItems()
        for each item in m.items
            m.[item].Delete(m.global.selectedUser)
        end for
        saveReg()
        
        m.global.selectedUser = -2
        
    end if
End Sub


Sub showsubselected()
    'Store item selected in registry
    itemcontent = m.settingSubList.content.getChild(m.settingSubList.itemSelected)
    
    if itemcontent.description = "0" then
        'Center the MarkUp Box
        pinRect = m.pinRectangle.boundingRect()
        centerx = (1280 - pinRect.width) / 2
        m.pinRectangle.translation = [ centerx, 200 ]
          
        m.pinRectangle.visible = true
        m.pinPad.pin = "0"
        m.pinPad.setFocus(true)   
    end if
    
    RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
    
    'Re-store the current selected item locally
    if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 1 then m.settingsDisplaycheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 2 then m.settingsDelaycheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 3 then m.settingsOrdercheckedItem = m.settingSubList.itemSelected
End Sub


Sub processPinEntry()
    if len(m.pinPad.pin) = 3 then
        m.pinRectangle.visible = false
        m.settingSubList.setFocus(true)
    end if

End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if (key = "right") and (m.pinRectangle.visible = false)
            m.settingsList.itemSelected = m.settingsList.itemFocused
            return true
        else if (key = "left") and (m.pinRectangle.visible = false) and (m.settingsList.hasFocus() = false)
            m.settingsList.setFocus(true)
            return true        
        else if (key = "back") and (m.settingsList.hasFocus() = false)
            m.settingsList.setFocus(true)
            m.pinRectangle.visible = false
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function