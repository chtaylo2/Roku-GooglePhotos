
sub init()
    'Set scene properties
    m.top.backgroundURI   = ""
    m.top.backgroundColor = "#EBEBEB"     
      
    m.top.setFocus(true)

    'Define SG nodes
    m.markupgrid = m.top.findNode("homeGrid")
    m.itemLabelMain1 = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2 = m.top.findNode("itemLabelMain2")
    m.itemLabelMain3 = m.top.findNode("itemLabelMain3")
      
    m.itemLabelMain3.text = "Chris Taylor • Main Menu"
      
    'Read in content
    m.readMarkupGridTask = createObject("roSGNode", "ContentReader")
    m.readMarkupGridTask.contenturi = "pkg:/data/homeGridContent.xml"
    m.readMarkupGridTask.observeField("content", "showmarkupgrid")
    m.readMarkupGridTask.control = "RUN"
end sub


sub showmarkupgrid()
    'Populate grid content
    m.markupgrid.content = m.readMarkupGridTask.content
      
    'Select default item
    m.markupgrid.jumpToItem = 2
      
    'Watch for events
    m.markupgrid.observeField("itemFocused", "onItemFocused") 
    m.markupgrid.observeField("itemSelected", "onItemSelected")
end sub


sub onItemFocused()
    'Item focused
    focusedItem = m.markupgrid.content.getChild(m.markupgrid.itemFocused)
    m.itemLabelMain1.text = focusedItem.shortdescriptionline1
    m.itemLabelMain2.text = focusedItem.shortdescriptionline2
end sub


sub onItemSelected()
    'Item selected
    selectedItem = m.markupgrid.content.getChild(m.markupgrid.itemSelected)
    screenToDisplay = selectedItem.shortdescriptionline1
      
    m.markupgrid.visible = false
    m.itemLabelMain1.visible = false
    m.itemLabelMain2.visible = false
      
    m.itemLabelMain3.text = screenToDisplay
    m.screenActive = createObject("roSGNode", screenToDisplay)
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
end sub


function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"        
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid

                m.itemLabelMain3.text = "Chris Taylor • Main Menu"
                m.markupgrid.visible = true
                m.itemLabelMain1.visible = true
                m.itemLabelMain2.visible = true
                m.markupgrid.setFocus(true)
                
                return true
            end if
        end if
    end if
    return false
end function