
sub init()
    'Define SG nodes
    m.settingsList = m.top.findNode("settingsLabelList")
    m.settingSubList = m.top.findNode("settingSubList")
    m.regEntry = m.top.findNode("RegistryTask")
    m.infoLabel = m.top.findNode("infoLabel")
      
    'Read in Content
    m.readContentTask = createObject("roSGNode", "ContentReader")
    m.readContentTask.observeField("content", "setlist")
    m.readContentTask.contenturi = "pkg:/data/Settings/settingsContent.xml"
    m.readContentTask.control = "RUN"
end sub


sub setlist()
    'Setup content list for different settings
    setresolution()
    setdelay()

    'Populate primary list content
    m.settingsList.content = m.readContentTask.content
    m.settingsList.setFocus(true)
end sub


sub setresolution()
    'Populate screen resolution list content
    regStore = "SlideshowRes"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    device = createObject("roDeviceInfo")
    is4k = (val(device.GetVideoMode()) = 2160)
    is1080p = (val(device.GetVideoMode()) = 1080)

    m.content = createObject("RoSGNode","ContentNode")
    
    if regSelection = "0" then radioSelection = 0
    addItem(m.content, "Standard Definition (SD)", "0", regStore)

    if is4k Or is1080p then
        if regSelection = "1" then radioSelection = 1
        addItem(m.content, "High Definition (HD)", "1", regStore)
    end if
    
    if is4k then
        if regSelection = "2" then radioSelection = 2
        addItem(m.content, "Full High Definition (FHD)", "2", regStore)
    end if

    'Store content node and current registry selection
    m.settingsRes = m.content
    m.settingsRescheckedItem = radioSelection
end sub


sub setdelay()
    'Populate photo delay list content
    regStore = "SlideshowDelay"
    regSelection = RegRead(regStore, "Settings")
    radioSelection = 0

    m.content = createObject("RoSGNode","ContentNode")
    if regSelection = "1" then radioSelection = 0
    addItem(m.content, "1 second", "1", regStore)
    if regSelection = "3" then radioSelection = 1
    addItem(m.content, "3 seconds (Default)", "3", regStore)
    if regSelection = "5" then radioSelection = 2
    addItem(m.content, "5 seconds", "5", regStore)
    if regSelection = "10" then radioSelection = 3
    addItem(m.content, "10 Seconds", "10", regStore)
    if regSelection = "30" then radioSelection = 4
    addItem(m.content, "30 seconds", "30", regStore)
    if regSelection = "0" then radioSelection = 5
    addItem(m.content, "Custom Setting", "0", regStore)
    
    'Store content node and current registry selection
    m.settingsDelay = m.content
    m.settingsDelaycheckedItem = radioSelection
end sub


sub addItem(store as object, itemtext as string, itemdesc as string, itemsection as string)
    item = store.createChild("ContentNode")
    item.title = itemtext
    item.description = itemdesc
    item.titleseason = itemsection
end sub


sub showfocus()
    'Show info for focused item
    if m.settingsList.content<>invalid then
        itemcontent = m.settingsList.content.getChild(m.settingsList.itemFocused)
        m.infoLabel.text = itemcontent.description
        
        if m.settingsList.itemFocused = 0 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsRes
            m.settingSubList.checkedItem = m.settingsRescheckedItem
        else if m.settingsList.itemFocused = 1 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsDelay
            m.settingSubList.checkedItem = m.settingsDelaycheckedItem
        else if m.settingsList.itemFocused = 2 then
            m.settingSubList.visible = "false"
        else if m.settingsList.itemFocused = 3 then
            m.settingSubList.visible = "false"
        else if m.settingsList.itemFocused = 4 then
            m.settingSubList.visible = "false"
        end if
    end if 
end sub


sub showselected()
    'Process item selected
    if m.settingsList.itemSelected = 0 OR m.settingsList.itemSelected = 1 then
        m.settingSubList.setFocus(true)       
    end if
end sub


sub showsubselected()
    'Store item selected in registry
    itemcontent = m.settingSubList.content.getChild(m.settingSubList.itemSelected)
    RegWrite(itemcontent.titleseason, itemcontent.description, "Settings")
    
    'Re-store the current selected item locally
    if m.settingsList.itemSelected = 0 then m.settingsRescheckedItem = m.settingSubList.itemSelected
    if m.settingsList.itemSelected = 1 then m.settingsDelaycheckedItem = m.settingSubList.itemSelected
    
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "right"
            m.settingsList.itemSelected = m.settingsList.itemFocused
            return true      
        else if (key = "back" or key = "left") and m.settingsList.hasFocus() = false
            m.settingsList.setFocus(true)
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
end function