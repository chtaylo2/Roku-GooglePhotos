'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2020 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("appstatus_response","handleAppStatus")
    
    m.top.setFocus(true)
    
    ' Load in the OAuth Registry entries
    loadReg()
    
    'Load common variables
    loadCommon()
    
    'Define SG nodes
    m.markupgrid        = m.top.findNode("homeGrid")
    m.itemLabelMain1    = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2    = m.top.findNode("itemLabelMain2")
    m.itemHeader        = m.top.findNode("itemHeader")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    m.supportReset      = "Normal"
    
    m.itemHeader.text   = m.userInfoName[m.global.selectedUser] + " • Main Menu"
    
    'Read in content
    m.readMarkupGridTask = createObject("roSGNode", "Local ContentReader")
    m.readMarkupGridTask.file = "pkg:/data/homeGridContent.xml"
    m.readMarkupGridTask.observeField("content", "showmarkupgrid")
    m.readMarkupGridTask.control = "RUN"
    
End Sub


Sub handleAppStatus(event as object)
    print "MainMenu.brs [handleAppStatus]"
  
    response = event.getData()
    if response.code = 200
        rsp = ParseXML(response.content)
        if rsp.GetNamedElements("status")[0].GetText() <> "" then
            m.itemHeader.text      = rsp.GetNamedElements("status_header")[0].GetText()
            m.screenActive         = createObject("roSGNode", "StatusPopup")
            m.screenActive.content = rsp.GetNamedElements("status")[0].GetText()
            m.screenActive.id      = "StatusPopup"
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
            
            m.markupgrid.visible        = false
            m.itemLabelMain1.visible    = false
            m.itemLabelMain2.visible    = false
            
        end if
    end if   
End Sub


Sub showmarkupgrid()

    'Show any live status from the site
    makeRequest({}, "https://www.photoviewapp.com/status/roku_status_v" + m.releaseVersion + ".xml" + "?" + getRandomString(10), "GET", "", 7, [])

    'Populate grid content
    m.markupgrid.content = m.readMarkupGridTask.content

    'Center the MarkUp Box
    markupRect = m.markupgrid.boundingRect()
    centerx = (1920 - markupRect.width) / 2
    m.markupgrid.translation = [ centerx + 15, 360 ]
    
    'Select default item
    m.markupgrid.jumpToItem = 2
      
    'Watch for events
    m.markupgrid.observeField("itemFocused", "onItemFocused") 
    m.markupgrid.observeField("itemSelected", "onItemSelected")
End Sub


Sub onItemFocused()
    'Item focused
    focusedItem = m.markupgrid.content.getChild(m.markupgrid.itemFocused)
    m.itemLabelMain1.text = focusedItem.shortdescriptionline1
    m.itemLabelMain2.text = focusedItem.shortdescriptionline2
End Sub


Sub onItemSelected()
    'Item selected
    selectedItem = m.markupgrid.content.getChild(m.markupgrid.itemSelected)
    screenToDisplay = selectedItem.shortdescriptionline1
    
    if screenToDisplay = "Search" then
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.title   = "Notice"
        m.noticeDialog.message = "Google Photos announced they will no longer support a 'keyword' search feature in thier API. Unless something changes, this search icon will be removed in a future release. It's unfortunate"
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    
    else
        m.markupgrid.visible        = false
        m.itemLabelMain1.visible    = false
        m.itemLabelMain2.visible    = false
    
        m.itemHeader.text           = m.userInfoName[m.global.selectedUser] + " • " + screenToDisplay
        m.screenActive              = createObject("roSGNode", screenToDisplay)
        m.screenActive.loaded       = true
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    end if
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible = false
    m.markupgrid.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        
        if key = "OK" and (m.screenActive <> invalid) and (m.screenActive.id = "StatusPopup") then
            m.top.removeChild(m.screenActive)
            m.screenActive = invalid
            
            m.itemHeader.text        = m.userInfoName[m.global.selectedUser] + " • Main Menu"
            m.markupgrid.visible     = true
            m.itemLabelMain1.visible = true
            m.itemLabelMain2.visible = true
            m.markupgrid.setFocus(true)
        end if
        
        
        'This will monitor events looking for the registery delete sequence
        m.supportReset = supportResetMonitor(key, m.supportReset)
        
        if key = "back"        
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid

                m.itemHeader.text        = m.userInfoName[m.global.selectedUser] + " • Main Menu"
                m.markupgrid.visible     = true
                m.itemLabelMain1.visible = true
                m.itemLabelMain2.visible = true
                m.markupgrid.setFocus(true)
                
                return true
            else
                m.global.selectedUser = -1
            end if
        end if
    end if
    return false
End function
