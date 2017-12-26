
Sub init()     
    m.top.setFocus(true)
    
    ' Load in the OAuth Registry entries
    loadReg()
    
    'Define SG nodes
    m.markupgrid        = m.top.findNode("homeGrid")
    m.itemLabelMain1    = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2    = m.top.findNode("itemLabelMain2")
    m.itemHeader        = m.top.findNode("itemHeader")
    
    m.itemHeader.text = "Select User"
      
    'Display content
    showmarkupgrid()
    
End Sub


Sub showmarkupgrid()

    usersLoaded = oauth_count()
    m.content = createObject("RoSGNode","ContentNode")

    for i = 0 to usersLoaded-1
        print "User: "; m.userInfoName[i]
        addItem(m.content,  m.userInfoPhoto[i], m.userInfoName[i], m.userInfoEmail[i])
    end for
    
    'Populate grid content
    m.markupgrid.content = m.content
        
    'if usersLoaded = 1 then
    '    'Show only registered user
    '    m.global.selectedUser = 0
    'end if

    'Center the MarkUp Box
    markupRect = m.markupgrid.boundingRect()
    centerx = (1280 - markupRect.width) / 2
    m.markupgrid.translation = [ centerx, 240 ]
      
    'Watch for events
    m.markupgrid.observeField("itemFocused", "onItemFocused") 
    m.markupgrid.observeField("itemSelected", "onItemSelected")
End Sub


Sub addItem(store as object, hdgridposterurl as string, shortdescriptionline1 as string, shortdescriptionline2 as string)
    item = store.createChild("ContentNode")
    item.hdgridposterurl = hdgridposterurl
    item.shortdescriptionline1 = shortdescriptionline1
    item.shortdescriptionline2 = shortdescriptionline2
    item.x = 200
End Sub


Sub onItemFocused()
    'Item focused
    focusedItem = m.markupgrid.content.getChild(m.markupgrid.itemFocused)
    m.itemLabelMain1.text = focusedItem.shortdescriptionline1
    m.itemLabelMain2.text = focusedItem.shortdescriptionline2
End Sub


Sub onItemSelected()
    'Item selected
    print "SELECTEDUSER: "; m.markupgrid.itemSelected
    m.global.selectedUser = m.markupgrid.itemSelected
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
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
            else
                'Once on MainMenu Screen, Stop Back Key 
                return true
            end if
        end if
    end if
    return false
End function