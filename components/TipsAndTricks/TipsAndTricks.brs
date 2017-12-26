
Sub init()
    'Define SG nodes
    m.tipsList = m.top.findNode("tipsLabelList")
    m.tipsInfo = m.top.findNode("infoLabel")
      
    'Read in content
    m.readContentTask = createObject("roSGNode", "Local ContentReader")
    m.readContentTask.observeField("content", "setlist")
    m.readContentTask.file = "pkg:/data/TipsAndTricks/tipsContent.xml"
    m.readContentTask.control = "RUN"
End Sub


Sub setlist()
    'Populate list content
    m.tipsList.content = m.readContentTask.content
    m.tipsList.setFocus(true)
End Sub


Sub showfocus()
    'Show info for focused item
    if m.tipsList.content<>invalid then
        itemcontent = m.tipsList.content.getChild(m.tipsList.itemFocused)
        m.tipsInfo.text = itemcontent.description
    end if
End Sub