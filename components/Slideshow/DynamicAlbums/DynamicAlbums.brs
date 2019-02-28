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
    m.apiTimer         = m.top.findNode("apiTimer")
    m.apiTimer.observeField("fire","onApiTimerTrigger")
    
    m.apiPending        = 0
    m.albumActiveObject = {}
    
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
    m.content = createObject("RoSGNode","ContentNode")
    'addItem(m.content, "Shuffle All Photos", "3", "junk")
    addItem(m.content, "Rediscover this Day in History", "day", "Rediscover this Day in History")
    addItem(m.content, "Rediscover this Week in History", "week", "Rediscover this Week in History")
    addItem(m.content, "Rediscover this Month in History", "month", "Rediscover this Month in History")

    'Store content node and current registry selection
    m.dynamicAlbumList.content = m.content
    
    'Watch for events
    m.dynamicAlbumList.observeField("itemSelected", "onItemSelected")
    
End Sub


Sub onItemSelected()
    print "DynamicAlbums.brs [onItemSelected]"
    
    'if m.dynamicAlbumList.itemFocused = 0 then
    
    '    m.dynamicAlbumList.visible = false
    '    m.itemOverhang.visible     = false         
            
    '    m.screenActive = createObject("roSGNode", "Shuffle Photos")
    '    m.screenActive.loaded = true
    '    m.top.appendChild(m.screenActive)
    '    m.screenActive.setFocus(true)
    'else
        m.apiTimer.control = "start"
    
        'Item selected
        keyword = m.dynamicAlbumList.content.getChild(m.dynamicAlbumList.itemFocused).description
        m.top.tracking = m.dynamicAlbumList.content.getChild(m.dynamicAlbumList.itemFocused).titleseason

        searchStrings = doSearchGenerate()
        
        m.albumActiveObject["SearchResults"] = {}
        m.albumActiveObject["SearchResults"].GetTitle = "Search Results"
        m.albumActiveObject["SearchResults"].GetID = "SearchResults"
        m.albumActiveObject["SearchResults"].GetImageCount = 0
        m.albumActiveObject["SearchResults"].previousPageTokens = []
        m.albumActiveObject["SearchResults"].showCountStart = 1
        m.albumActiveObject["SearchResults"].showCountEnd = 0
        m.albumActiveObject["SearchResults"].apiCount = 0
        m.albumActiveObject["SearchResults"].GetUserIndex = m.global.selectedUser
        m.albumActiveObject["SearchResults"].keyword = keyword
        m.albumActiveObject["SearchResults"].imagesMetaData = []
        m.albumActiveObject["SearchResults"].videosMetaData = []
        
        m.searchProgress.message = m.top.tracking+" - Searching Albums"
        m.searchProgress.visible = true

        doGetSearch("SearchResults", searchStrings[keyword], m.global.selectedUser)
    'end if
    
End Sub


Sub handleGetSearch(event as object)
    print "DynamicAlbums.brs [handleGetSearch]"

    errorMsg = ""
    response = event.getData()
    albumid  = response.post_data[1]
    keywords = response.post_data[2]
    
    m.apiPending = m.apiPending-1
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, m.global.selectedUser)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetSearch'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)
        'print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetSearch"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetSearch] " + json.error
        else

            imageList = googleImageListing(rsp)

            for each media in imageList
                tmp             = {}
                tmp.id          = media.GetID
                tmp.url         = media.GetURL
                tmp.timestamp   = media.GetTimestamp
                tmp.description = media.GetDescription
                tmp.filename    = media.GetFilename
        
                if media.IsVideo then
                    m.albumActiveObject[albumid].videosMetaData.Push(tmp)
                    'print "VIDEO: "; tmp.url
                else
                    m.albumActiveObject[albumid].imagesMetaData.Push(tmp)
                    'print "IMAGE: "; tmp.url
                end if
            end for
            
            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumActiveObject[albumid].nextPageToken = pageNext
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + imageList.Count()
                m.albumActiveObject[albumid].apiCount = m.albumActiveObject[albumid].apiCount + 1
                if (m.albumActiveObject[albumid].apiCount < m.maxApiPerPage) and (m.albumActiveObject[albumid].showCountEnd < m.maxImagesPerPage) then
                    pagesShow = "Items Found"+StrI(m.albumActiveObject[albumid].showCountStart+m.albumActiveObject[albumid].showCountEnd-1)
                    m.searchProgress.message = m.top.tracking+" - Searching Albums - "+pagesShow
                    doGetSearch(albumid, keywords, m.global.selectedUser, pageNext)
                end if
            else
                m.albumActiveObject[albumid].nextPageToken = invalid
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + imageList.Count()
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


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending;

    if m.apiPending = 0 then
        m.searchProgress.visible = false
        m.apiTimer.control = "stop"
        
        if m.albumActiveObject["SearchResults"].showcountend > 0 then
            'Hide blackout screen
            m.FadeBackground.visible   = false
            m.dynamicAlbumList.visible = false
            m.itemOverhang.visible     = false         
            
            m.screenActive = createObject("roSGNode", "Google Photos Albums")
            m.screenActive.imageContent = m.albumActiveObject
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
