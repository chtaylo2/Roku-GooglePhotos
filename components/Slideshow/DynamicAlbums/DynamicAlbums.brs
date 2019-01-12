'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("searchResult","handleGetSearch")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    
    m.FadeBackground   = m.top.findNode("FadeBackground")
    m.dynamicAlbumList = m.top.findNode("dynamicAlbumList")
    m.itemOverhang     = m.top.findNode("itemOverhang")
    m.searchProgress   = m.top.findNode("searchProgress")
    m.noticeDialog     = m.top.findNode("noticeDialog")
    
    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()

    'Load in the OAuth Registry entries
    loadReg()

    device = CreateObject("roDeviceInfo")
    ds = device.GetDisplaySize()
    
    if ds.w = 720 then
        print "SD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_SD.png"
    else if ds.w = 1280 then
        print "HD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_HD.png"
    else
        print "FHD Detected"
        m.itemOverhang.logoUri = "pkg:/images/Logo_Overhang_FHD.png"
    end if
    
End Sub


Sub loadListContent()
    
    'Get Dates
    date         = CreateObject("roDateTime")
    datepast     = createobject("rodatetime")
    date.ToLocalTime()
    datepast.ToLocalTime()
 
    'Calculate 7 days prior
    d1seconds    = datepast.asseconds() - (60 * 60 * 24 * 7)
    datepast.FromSeconds(d1seconds)
    
    current      = date.AsDateString("no-weekday")
    currentYear  = date.GetYear().ToStr()
    currentMonth = current.Split(" ")[0].ToStr()
    currentDay   = zeroCheck(date.GetDayOfMonth().ToStr())
    
    past         = datepast.AsDateString("no-weekday")
    pastYear     = datepast.GetYear().ToStr()
    pastMonth    = past.Split(" ")[0].ToStr()
    pastDay      = zeroCheck(datepast.GetDayOfMonth().ToStr())
    
    m.content = createObject("RoSGNode","ContentNode")
    addItem(m.content, "Shuffle All Photos", "3", "junk")
    addItem(m.content, "Rediscover this Day in History", "%22"+currentMonth+" "+currentDay+"%22 "+"-"+currentYear, "Rediscover this Day in History")
    addItem(m.content, "Rediscover this Week in History", "%22"+pastMonth+" "+pastDay+" - "+currentMonth+" "+currentDay+"%22 "+"-"+pastYear+" -"+currentYear, "Rediscover this Week in History")
    addItem(m.content, "Rediscover this Month in History", "%22"+currentMonth+"%22 "+"-"+currentYear, "Rediscover this Month in History")

    'Store content node and current registry selection
    m.dynamicAlbumList.content = m.content
    
    'Watch for events
    m.dynamicAlbumList.observeField("itemSelected", "onItemSelected")
    
End Sub


Sub onItemSelected()
    print "DynamicAlbums.brs [onItemSelected]"
    
    if m.dynamicAlbumList.itemFocused = 0 then
    
        m.dynamicAlbumList.visible = false
        m.itemOverhang.visible     = false         
            
        m.screenActive = createObject("roSGNode", "Shuffle Photos")
        m.screenActive.loaded = true
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    else
    
        'Item selected
        keyword = m.dynamicAlbumList.content.getChild(m.dynamicAlbumList.itemFocused).description
        m.top.tracking = m.dynamicAlbumList.content.getChild(m.dynamicAlbumList.itemFocused).titleseason
        doGetSearch(keyword)
    end if
    
End Sub


' URL Request to fetch search
Sub doGetSearch(keyword as string)
    print "DynamicAlbums.brs [doGetSearch]"
    
    if keyword <> ""
        m.searchProgress.message = m.top.tracking+" - Searching Albums"
        m.searchProgress.visible = true
    
        tmpData = [ "doGetSearch", keyword ]
        
        keyword = keyword.Replace(" ", "+")
        'print "KEYWORD: "; keyword
        
        signedHeader = oauth_sign(m.global.selectedUser)
        makeRequest(signedHeader, m.gp_prefix + "?kind=photo&v=3.0&q="+keyword+"&max-results=1000&thumbsize=220&imgmax="+getResolution(), "GET", "", 3, tmpData)
    end if
End Sub


Sub handleGetSearch(event as object)
    print "DynamicAlbums.brs [handleGetSearch]"

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
            
                'Hide blackout screen
                m.FadeBackground.visible   = false
                m.dynamicAlbumList.visible = false
                m.itemOverhang.visible     = false         
            
                m.screenActive = createObject("roSGNode", "My Albums")
                m.screenActive.imageContent = response
                m.screenActive.predecessor = m.top.tracking
                m.screenActive.loaded = true
                m.top.appendChild(m.screenActive)
                m.screenActive.setFocus(true)
                
            else
                m.noticeDialog.visible = true
                buttons =  [ "OK" ]
                m.noticeDialog.title   = "Notice"
                m.noticeDialog.message = "No media found matching this search. Try a different date range"
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


Sub addItem(store as object, itemtext as string, itemdesc as string, itemsection as string)
    item = store.createChild("ContentNode")
    item.title = itemtext
    item.description = itemdesc
    item.titleseason = itemsection
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible   = false
    m.noticeDialog.unobserveField("buttonSelected") 
    m.dynamicAlbumList.setFocus(true)
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End function
