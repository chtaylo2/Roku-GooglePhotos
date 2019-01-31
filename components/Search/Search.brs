'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("searchResult","handleGetSearch")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    
    m.miniKeyboard      = m.top.findNode("miniKeyboard")
    m.searchBtn         = m.top.findNode("searchBtn")
    m.clearSearchBtn    = m.top.findNode("clearSearchBtn")
    m.searchHistoryList = m.top.findNode("searchHistoryList")
    m.searchProgress    = m.top.findNode("searchProgress")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    
    m.searchBtn.observeField("buttonSelected","keywordSearch")
    m.searchHistoryList.observeField("itemSelected","historySearch")
    m.clearSearchBtn.observeField("buttonSelected","clearSearchHistory")

    'Load common variables
    loadCommon()
    
    'Load privlanged variables
    loadPrivlanged()

    'Load in the OAuth Registry entries
    loadReg()
    
    'populateHistory()
    
    'Set some UI customizations
    m.miniKeyboard.texteditbox.maxTextLength    = 20
    m.miniKeyboard.texteditbox.hintText         = "Google Photos Search"
    m.miniKeyboard.texteditbox.hintTextColor    = "#949596"
    m.miniKeyboard.texteditbox.textColor        = "#313233"
    
End Sub


Sub populateHistory()
    m.history = createObject("RoSGNode","ContentNode")
    regStore = "History"
    regHistory = RegRead(regStore, "Search")
    
    if regHistory <> invalid
        parsedString = regHistory.Split("|")

        for each item in parsedString
            if item <> ""
                addItem(m.history, item)
            end if
        end for
    
        m.searchHistoryList.content = m.history
    end if
    
End Sub


Sub keywordSearch()
    print "Search.brs [keywordSearch]"
    keyword = m.miniKeyboard.textEditBox.text
    
    writeSearchHistory(keyword)
    doGetSearch(keyword)
End Sub


Sub historySearch()
    print "Search.brs [historySearch]"
    keyword = m.searchHistoryList.content.getChild(m.searchHistoryList.itemSelected).title
    
    print "KEYWORD: "; keyword
    doGetSearch(keyword)
End Sub


' URL Request to fetch search
Sub doGetSearch(keyword as string)
    print "Search.brs [doGetSearch]"
    
    if keyword <> ""
        m.searchProgress.message = "Searching albums for '" + keyword + "'"
        m.searchProgress.visible = true
    
        tmpData = [ "doGetSearch", keyword ]
        
        keyword = keyword.Replace(" ", "+")
        signedHeader = oauth_sign(m.global.selectedUser)
        makeRequest(signedHeader, m.gp_prefix + "?kind=photo&v=3.0&q="+keyword+"&max-results=1000&thumbsize=220&imgmax="+getResolution(), "GET", "", 3, tmpData)
    end if
End Sub


Sub handleGetSearch(event as object)
    print "Search.brs [handleGetSearch]"

    errorMsg = ""
    response = event.getData()
    
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetSearch'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        
        print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else
        
            results=rsp.GetNamedElements("openSearch:totalResults")[0].GetText()
            
            m.searchProgress.visible = false
            
            if strtoi(results) > 0 then
                m.screenActive = createObject("roSGNode", "My Albums")
                m.screenActive.imageContent = response
                m.screenActive.predecessor = "Search Results"
                m.screenActive.loaded = true
                m.top.appendChild(m.screenActive)
                m.screenActive.setFocus(true)
                
                m.miniKeyboard.visible = false
            else
                m.noticeDialog.visible = true
                buttons =  [ "OK" ]
                m.noticeDialog.title   = "Notice"
                m.noticeDialog.message = "No media matched your search"
                m.noticeDialog.buttons = buttons
                m.noticeDialog.setFocus(true)
                m.noticeDialog.observeField("buttonSelected","noticeClose")                
            end if
        end if
        
    end if

    if errorMsg<>"" then
        'ShowError
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.title   = "Error"
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if   

End Sub


Sub addItem(store as object, itemtext as string)
    item = store.createChild("ContentNode")
    item.title = itemtext
End Sub


Sub writeSearchHistory(keyword as string)
    regStore = "History"
    regHistory = RegRead(regStore, "Search")
    
    if keyword <> ""
        if (regHistory <> invalid) and (regHistory <> "")
            
            'Only save last 10 searches
            parsedString = regHistory.Split("|")
            i = 1
            saveList = ""
            for each item in parsedString
                if item <> keyword
                    saveList = saveList + "|" + item
                    i = i + 1
                    if i = 10 EXIT FOR
                end if
            end for
            RegWrite(regStore, keyword+saveList, "Search")
        else
            RegWrite(regStore, keyword, "Search")
        end if
        
        populateHistory()
        
    end if
End Sub


Sub clearSearchHistory()
    regStore = "History"
    RegWrite(regStore, "", "Search")
    m.searchHistoryList.content = ""
    m.clearSearchBtn.unobserveField("buttonSelected")
    m.miniKeyboard.setFocus(true)
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible   = false
    m.searchProgress.visible = false
    m.miniKeyboard.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if key = "back"
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                m.miniKeyboard.visible = true
                m.miniKeyboard.setFocus(true)
                return true
            end if
        else if (key = "down") and (m.miniKeyboard<>invalid) and (m.miniKeyboard.focusedChild.id = "")
            m.searchBtn.setFocus(true)
            return true
        else if (key = "down") and (m.searchHistoryList.hasFocus() = true)
            m.clearSearchBtn.setFocus(true)
            return true
        else if (key = "up") and (m.miniKeyboard<>invalid) and (m.miniKeyboard.focusedChild.id = "searchBtn")
            m.miniKeyboard.setFocus(true)
            return true
        else if (key = "up") and (m.clearSearchBtn.hasFocus() = true)
            m.searchHistoryList.setFocus(true)
            return true
        else if (key = "right") and (m.miniKeyboard<>invalid) and (m.miniKeyboard.focusedChild.id = "")
            m.searchHistoryList.setFocus(true)
            return true
        else if (key = "left") and (m.searchHistoryList.hasFocus() = true)
            m.miniKeyboard.setFocus(true)
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
