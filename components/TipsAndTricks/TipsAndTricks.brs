
sub init()
    'Define SG nodes
    m.tipsList = m.top.findNode("tipsLabelList")
    m.tipsInfo = m.top.findNode("infoLabel")
      
    'Read in content
    m.readContentTask = createObject("roSGNode", "ContentReader")
    m.readContentTask.observeField("content", "setlist")
    m.readContentTask.contenturi = "pkg:/data/TipsAndTricks/tipsContent.xml"
    m.readContentTask.control = "RUN"
end sub


sub setlist()
    'Populate list content
    m.tipsList.content = m.readContentTask.content
    m.tipsList.setFocus(true)
end sub


sub showfocus()
    'Show info for focused item
    if m.tipsList.content<>invalid then
        itemcontent = m.tipsList.content.getChild(m.tipsList.itemFocused)
        m.tipsInfo.text = itemcontent.description
    end if
end sub