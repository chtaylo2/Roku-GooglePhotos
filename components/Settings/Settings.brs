
sub init()
    'Define SG nodes
    m.settingsList = m.top.findNode("settingsLabelList")
    m.settingSubList = m.top.findNode("settingSubList")
    m.infoLabel = m.top.findNode("infoLabel")
      
    'Read in Content
    m.readContentTask1 = createObject("roSGNode", "ContentReader")
    m.readContentTask1.observeField("content", "setlist")
    m.readContentTask1.contenturi = "pkg:/data/Settings/settingsContent.xml"
    m.readContentTask1.control = "RUN"
      
    'Read in Content
    m.readContentTask2 = createObject("roSGNode", "ContentReader")
    m.readContentTask2.observeField("content", "setres")
    m.readContentTask2.contenturi = "pkg:/data/Settings/settings-PhotoRes.xml"
    m.readContentTask2.control = "RUN"
      
    'Read in Content
    m.readContentTask3 = createObject("roSGNode", "ContentReader")
    m.readContentTask3.observeField("content", "setdelay")
    m.readContentTask3.contenturi = "pkg:/data/Settings/settings-PhotoDelay.xml"
    m.readContentTask3.control = "RUN"
end sub


sub setlist()
    'Populate list content
    m.settingsList.content = m.readContentTask1.content
    m.settingsList.setFocus(true)      
end sub


sub setres()
    'Populate list content
    m.settingsRes = m.readContentTask2.content 
end sub


sub setdelay()
    'Populate list content
    m.settingsDelay = m.readContentTask3.content
end sub


sub showfocus()
    'Show info for focused item
    if m.settingsList.content<>invalid then
        itemcontent = m.settingsList.content.getChild(m.settingsList.itemFocused)
        m.infoLabel.text = itemcontent.description
        
        if m.settingsList.itemFocused = 0 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsRes
        else if m.settingsList.itemFocused = 1 then
            m.settingSubList.visible = "true"
            m.settingSubList.content = m.settingsDelay
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