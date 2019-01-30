'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumList","handleGetAlbumList")
    m.UriHandler.observeField("albumImages","handleGetAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")

    m.loadingSpinner    = m.top.findNode("loadingSpinner")
    m.albummarkupgrid   = m.top.findNode("albumGrid")
    m.itemLabelMain1    = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2    = m.top.findNode("itemLabelMain2")
    m.itemLabelMain3    = m.top.findNode("itemLabelMain3")
    m.settingsIcon      = m.top.findNode("settingsIcon")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    
    m.albumPageList     = m.top.findNode("albumPageList")
    m.albumPageThumb    = m.top.findNode("albumPageThumb")
    m.albumPageInfo1    = m.top.findNode("albumPageInfo1")
    m.albumPageInfo2    = m.top.findNode("albumPageInfo2")

    m.albumListContent  = createObject("RoSGNode","ContentNode")
       
    m.albumActiveObject = invalid
    m.albumSelection    = 0
    
    'Load common variables
    loadCommon()
    
    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
    m.top.observeField("loaded","loadingComplete")
End Sub


Sub loadingComplete()
    m.top.unobserveField("loaded")

    if m.top.imageContent<>invalid then
        'Show search results
    
        'TODO: WILL WE SUPPORT SEARCH?
        
        'album = CreateObject("roAssociativeArray")
        'album.GetTitle=function():return "Unused":end function
        'album.GetImageCount=function():return Int(1):end function
        'm.albumName = m.top.predecessor

        'rsp=ParseXML(m.top.imageContent.content)
        'm.imagesObject = googleImageListing(rsp.entry)
        'googleDisplayImageMenu(album, m.imagesObject)
        
    else
        'Get user albums
        
        'Display Loading Spinner
        showLoadingSpinner(5, "GP_ALBUM_LISTING")
        
        'API CALL: Get album listing
        doGetAlbumList()
    end if
End Sub


Sub handleGetAlbumList(event as object)
    print "Albums.brs [handleGetAlbumList]"
  
    errorMsg = ""
    response = event.getData()

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumList'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)
        'print rsp
        
        if rsp = invalid
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetAlbumList"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetAlbumList] " + json.error
        else
            m.albumsObject = googleAlbumListing(rsp)
            googleDisplayAlbums(m.albumsObject)        
        end if
    end if
    
    if errorMsg<>"" then
        'ShowNotice
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if   
    
End Sub


Sub handleGetAlbumImages(event as object)
    print "Albums.brs [handleGetAlbumImages]"
  
    errorMsg = ""
    response = event.getData()
    
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumImages'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)

        if rsp = invalid
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetAlbumImages"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetAlbumImages] " + json.error
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
                   m.videosMetaData.Push(tmp)
                   'print "VIDEO: "; tmp.url
                else
                   m.imagesMetaData.Push(tmp)
                   'print "IMAGE: "; tmp.url
                end if
            end for

            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumActiveObject.nextPageToken = pageNext
                m.albumActiveObject.showCountEnd = m.albumActiveObject.showCountEnd + imageList.Count()
                m.albumActiveObject.apiCount = m.albumActiveObject.apiCount + 1
                if (m.albumActiveObject.apiCount < m.maxApiPerPage) and (m.albumActiveObject.showCountEnd < m.maxImagesPerPage) then
                    pagesShow = "Media Items"+StrI(m.albumActiveObject.showCountStart)+" -"+StrI(m.albumActiveObject.showCountStart+m.albumActiveObject.showCountEnd-1)
                    if m.albumActiveObject.GetImageCount<>0 then
                        pagesShow = pagesShow+" of"+StrI(m.albumActiveObject.GetImageCount)
                    end if
                    print "END: "; m.albumActiveObject.showCountEnd
                    m.itemLabelMain3.text = pagesShow
                    
                    if m.albumActiveObject.GetID = "GP_LIBRARY" then
                        doGetLibraryImages(pageNext)
                    else
                        doGetAlbumImages(m.albumActiveObject.GetID, pageNext)
                    end if
                else
                    if m.albumActiveObject.GetID = "GP_LIBRARY" then
                        googleDisplayImageMenu("Google Photos Library")
                    else
                        googleDisplayImageMenu(m.albumActiveObject.GetTitle, m.albumActiveObject.GetImageCount)
                    end if
                end if
            else
                m.albumActiveObject.nextPageToken = invalid
                m.albumActiveObject.showCountEnd = m.albumActiveObject.showCountEnd + imageList.Count()
                googleDisplayImageMenu(m.albumActiveObject.GetTitle, m.albumActiveObject.GetImageCount)
            end if
        end if
    end if
    
    if errorMsg<>"" then
        'ShowNotice
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if
    
End Sub


Sub onItemFocused()
    'Item focused
    
    focusedItem = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemFocused)
    m.itemLabelMain1.text = focusedItem.shortdescriptionline1
    m.itemLabelMain2.text = focusedItem.shortdescriptionline2
    
    'if (focusedItem.id = "GP_ALBUM_LISTING") and (m.albumListContent.Count() = m.albummarkupgrid.itemFocused) then
    '    'Display Loading Spinner
    '    showLoadingSpinner(5, "GP_ALBUM_LISTING")
        
    '    'API CALL: Get album listing
    '    doGetAlbumList()
    
    'end if
    
   ' print "FULL: "; m.albumListContent
   ' print "GRID: "; m.albumListContent.Count()
   ' print "FOCUS: "; m.albummarkupgrid.itemFocused
    
    
End Sub


Sub onItemSelected()
    'Item selected

    selection = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemSelected)

    if selection.id = "GP_ALBUM_LISTING_LIBRARY" then
    
        m.albumActiveObject = CreateObject("roAssociativeArray")
        m.albumActiveObject.GetTitle = "Google Photos Library"
        m.albumActiveObject.GetID = "GP_LIBRARY"
        m.albumActiveObject.GetImageCount = 0
        m.albumActiveObject.previousPageTokens = []
        m.albumActiveObject.showCountStart = 1
        m.albumActiveObject.showCountEnd = 0
        m.albumActiveObject.apiCount = 0
    
        m.albumSelection = m.albummarkupgrid.itemSelected
        m.albumName = selection.shortdescriptionline1

print "DEBUG: "; m.albumActiveObject
        
        m.itemLabelMain2.text = m.albumName
        m.itemLabelMain3.text = ""

        'TODO: ADD IN DETAILS ABOUT UNABLE TO COUNT LIBRARY PHOTOS, ETC.  Thanks Google..
        'lastPopup = RegRead("ThousandPopup","Settings")
        'if (lastPopup=invalid or lastPopup<>"v3.0true") then showThousandPopup()
        
        'Display Loading Spinner
        showLoadingSpinner(3, "GP_LOADING")
        
        'API CALL: Get album image listing
        doGetLibraryImages()
        
    else if selection.id = "GP_ALBUM_LISTING" then
        m.albumSelection = m.albummarkupgrid.itemSelected
        m.albumActiveObject = m.albumsObject[m.albummarkupgrid.itemSelected-1]
        m.albumName = selection.shortdescriptionline1

print "DEBUG: "; m.albumActiveObject


        m.albumActiveObject.previousPageTokens = []
        m.albumActiveObject.showCountStart = 1
        m.albumActiveObject.showCountEnd = 0
        m.albumActiveObject.apiCount = 0
        m.imagesMetaData = []
        m.videosMetaData = []
        
        m.itemLabelMain2.text = m.albumName
        m.itemLabelMain3.text = ""

        if m.albumActiveObject.GetImageCount > 1000 then

            lastPopup = RegRead("ThousandPopup","Settings")
            if (lastPopup=invalid or lastPopup<>"v3.0true") then showThousandPopup()
        else

            'Display Loading Spinner
            showLoadingSpinner(3, "GP_LOADING")
        
            'API CALL: Get album image listing
            doGetAlbumImages(m.albumActiveObject.GetID)
        end if
    
    else if selection.id = "GP_PULL_NEXT" then
        print "GP_PULL_NEXT"
        
        if m.albumActiveObject.nextPageToken<>invalid then
            m.albumActiveObject.previousPageTokens.Push(m.albumActiveObject.nextPageToken+"::"+StrI(m.albumActiveObject.showCountStart+m.albumActiveObject.showCountEnd))
        end if
        
        m.albumActiveObject.showCountStart = m.albumActiveObject.showCountStart+m.albumActiveObject.showCountEnd
        m.albumActiveObject.showCountEnd = 0
        m.albumActiveObject.apiCount = 0
        m.imagesMetaData = []
        m.videosMetaData = []
        
        'Display Loading Spinner
        showLoadingSpinner(3, "GP_LOADING")
        
        'API CALL: Get image listing - Next page
        if m.albumActiveObject.GetID = "GP_LIBRARY" then
            doGetLibraryImages(m.albumActiveObject.nextPageToken)
        else
            doGetAlbumImages(m.albumActiveObject.GetID, m.albumActiveObject.nextPageToken)
        end if

    else if selection.id = "GP_PULL_PREVIOUS" then
        print "GP_PULL_PREVIOUS"
        tmpPage = ""
        tmpCount = "1"
        if m.albumActiveObject.previousPageTokens[m.albumActiveObject.previouspagetokens.Count()-2]<>invalid then
            tmpPair = m.albumActiveObject.previousPageTokens[m.albumActiveObject.previouspagetokens.Count()-2].Split("::")
            tmpPage = tmpPair[0]
            tmpCount = tmpPair[1]
            
            print "DEBUG PAGE: "; tmpPage
            print "DEBUG Count: '"; StrToI(tmpCount); "'"
            
        end if
        m.albumActiveObject.previouspagetokens.Pop()
    
        m.albumActiveObject.showCountStart = StrToI(tmpCount)
        m.albumActiveObject.showCountEnd = 0
        m.albumActiveObject.apiCount = 0
        m.imagesMetaData = []
        m.videosMetaData = []
        
        'Display Loading Spinner
        showLoadingSpinner(3, "GP_LOADING")
        
        'API CALL: Get image listing - Previous page
        if m.albumActiveObject.GetID = "GP_LIBRARY" then
            doGetLibraryImages(tmpPage)
        else
            doGetAlbumImages(m.albumActiveObject.GetID, tmpPage)
        end if
        
        
    else if selection.id = "GP_SLIDESHOW_START" then 
        print "START SHOW"
        
        m.screenActive = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.predecessor = m.top.predecessor
        m.screenActive.albumobject = m.albumActiveObject
        m.screenActive.content = m.imagesMetaData
        m.screenActive.id = selection.id
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
    else if selection.id = "GP_VIDEO_BROWSE" then
        print "VIDEO BROWSE"
        displayVideoBrowse()
        
    else if selection.id = "GP_IMAGE_BROWSE" then
        print "IMAGE BROWSE"
        
        m.imageThumbList = createObject("RoSGNode","ContentNode")
        for i = 0 to m.imagesMetaData.Count()-1
            addItem(m.imageThumbList, "GP_BROWSE", m.imagesMetaData[i].url+getResolution("SD"), "", "")
        end for
        
        m.screenActive = createObject("roSGNode", "Browse")
        m.screenActive.id = selection.id
        m.screenActive.albumName = m.albumName + "  -  " + itostr(m.imagesMetaData.Count()) + " Photos"
        m.screenActive.metaData = m.imagesMetaData
        m.screenActive.predecessor = m.top.predecessor
        m.screenActive.albumobject = m.albumActiveObject
        m.screenActive.content = m.imageThumbList
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)

        hideMarkupGrid()
        
    end if
End Sub


Sub addItem(store as object, id as string, hdgridposterurl as string, shortdescriptionline1 as string, shortdescriptionline2 as string)
    item = store.createChild("ContentNode")
    item.id = id
    item.title = shortdescriptionline1
    item.hdgridposterurl = hdgridposterurl
    item.shortdescriptionline1 = shortdescriptionline1
    item.shortdescriptionline2 = shortdescriptionline2
    item.x = "300"
    item.y = "240"
End Sub


Sub googleDisplayAlbums(albumList As Object)

    'Everyone has a Google Photos Library in account
    addItem(m.albumListContent, "GP_ALBUM_LISTING_LIBRARY", m.userInfoPhoto[m.global.selectedUser], "Google Photos Library", "")
    for each album in albumList
        'All other albums
        addItem(m.albumListContent, "GP_ALBUM_LISTING", album.GetThumb, album.GetTitle, Pluralize(album.GetImageCount,"Item"))
    end for
    
    print "DEBUG: "; m.albumListContent.Count()
    m.albummarkupgrid.content = m.albumListContent
    
    centerMarkupGrid()
    showMarkupGrid()
    onItemFocused()
        
    m.albummarkupgrid.observeField("itemFocused", "onItemFocused") 
    m.albummarkupgrid.observeField("itemSelected", "onItemSelected")
        
    'Turn off Loading Spinner
    m.loadingSpinner.visible = "false"
        
    m.itemLabelMain3.text = "<<     Paging     >>"
   
End Sub


Sub googleDisplayImageMenu(albumTitle as String, albumCount=0 as Integer)
    print "Albums.brs - [googleDisplayImageMenu]"
    
    m.menuSelected      = createObject("RoSGNode","ContentNode")
    totalPages          = ceiling(albumCount / 1000)
    listIcon            = "pkg:/images/browse.png"
    listPagePrevious    = "pkg:/images/icon_next.png"
    listPageNext        = "pkg:/images/icon_next.png"
    videoOnly           = false
    
    if m.top.predecessor<>"" then
        title = m.top.predecessor
    else
        title = albumTitle
    end if
    
    pagesShow   = "Media Items"+StrI(m.albumActiveObject.showCountStart)+" -"+StrI(m.albumActiveObject.showCountStart+m.albumActiveObject.showCountEnd-1)
    if albumCount<>0 then
        pagesShow = pagesShow+" of"+StrI(albumCount)
    end if

    menuJumpToItem = 0
    if m.albumActiveObject.previousPageTokens[0]<>invalid then
        addItem(m.menuSelected, "GP_PULL_PREVIOUS", listPageNext, "Previous Media Page", title)
        menuJumpToItem = 1
    end if
   
    if m.videosMetaData.Count()>0 then        
        if m.imagesMetaData.Count()>0 then 'Combined photo and photo album
            addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].url+getResolution("SD"), Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", title)
            addItem(m.menuSelected, "GP_VIDEO_BROWSE", m.videosMetaData[0].url+getResolution("SD"), Pluralize(m.videosMetaData.Count(),"Video") + " - Browse", title)
            addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Browse", title)
       else 'Video only album
            addItem(m.menuSelected, "GP_VIDEO_BROWSE", m.videosMetaData[0].url+getResolution("SD"), Pluralize(m.videosMetaData.Count(),"Video") + " - Browse", title)
            videoOnly = true
        end if
    else 'Photo only album          
        addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].url+getResolution("SD"), Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", title)
        addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Browse", title)
    end if
    
    if m.albumActiveObject.nextpagetoken<>invalid then
        addItem(m.menuSelected, "GP_PULL_NEXT", listPageNext, "Next Media Page", title)
    end if
    
    m.itemLabelMain2.text           = title
    m.itemLabelMain3.text           = pagesShow
    m.settingsIcon.visible          = true
    m.albummarkupgrid.content       = m.menuSelected
    m.albummarkupgrid.jumpToItem    = menuJumpToItem
    
    centerMarkupGrid()
    showMarkupGrid()

    if videoOnly then
        'Remove an unnecessary click for user
        displayVideoBrowse()
    end if
    
    'Unobserve first to make sure we're not already monitoring
    m.albummarkupgrid.unobserveField("itemFocused") 
    m.albummarkupgrid.unobserveField("itemSelected")
    m.albummarkupgrid.observeField("itemFocused", "onItemFocused") 
    m.albummarkupgrid.observeField("itemSelected", "onItemSelected")
    
    'Turn off Loading Spinner
    m.loadingSpinner.visible = "false"  
    
End Sub


Sub centerMarkupGrid()
    'Center the MarkUp Box
    markupRectAlbum = m.albummarkupgrid.boundingRect()
    centerx = (1920 - markupRectAlbum.width) / 2

    m.albummarkupgrid.translation = [ centerx+27, 360 ]
End Sub

 
Sub hideMarkupGrid()
    m.albummarkupgrid.visible = false
    m.itemLabelMain1.visible  = false
    m.itemLabelMain2.visible  = false
    m.itemLabelMain3.visible  = false
    m.settingsIcon.visible    = false
End Sub


Sub showMarkupGrid()
    m.albummarkupgrid.visible = true
    m.itemLabelMain1.visible  = true
    m.itemLabelMain2.visible  = true
    m.itemLabelMain3.visible  = true
    
    m.albummarkupgrid.setFocus(true)
End Sub


Sub displayVideoBrowse()
    m.videoThumbList = createObject("RoSGNode","ContentNode")
    for i = 0 to m.videosMetaData.Count()-1
        addItem(m.videoThumbList, "GP_BROWSE", m.videosMetaData[i].url, "", "")
    end for
            
    m.screenActive = createObject("roSGNode", "Browse")
    m.screenActive.id = "GP_VIDEO_BROWSE"
    m.screenActive.albumName = m.albumName + "  -  " + itostr(m.videosMetaData.Count()) + " Videos"
    m.screenActive.metaData = m.videosMetaData
    m.screenActive.content = m.videoThumbList
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
    
    hideMarkupGrid()
End Sub


Sub displayAlbumImages()
    m.albummarkupgrid.visible = true
    m.itemLabelMain1.visible  = true
    m.itemLabelMain2.visible  = true
    m.itemLabelMain3.visible  = true
    m.settingsIcon.visible    = true

    m.albummarkupgrid.setFocus(true)
End Sub


Sub hideAlbumImages()
    m.albummarkupgrid.visible = false
    m.itemLabelMain1.visible  = false
    m.itemLabelMain2.visible  = false
    m.itemLabelMain3.visible  = false
    m.settingsIcon.visible    = false
End Sub


Sub showLoadingSpinner(gridCount as integer, id as string)
    m.placeholder = createObject("RoSGNode","ContentNode")
    for i = 1 to gridCount
        addItem(m.placeholder, id, "pkg:/images/placeholder.png", "", "")
    end for

    m.albummarkupgrid.content = m.placeholder
    centerMarkupGrid()
    showMarkupGrid()
    
    if m.albumActiveObject<>invalid then
        m.itemLabelMain2.text = m.albumActiveObject.GetTitle
    end if
    
    m.loadingSpinner.visible = "true"
    m.loadingSpinner.setFocus(true)
End Sub


Sub showTempSetting()
    hideMarkupGrid()
    m.screenActive              = createObject("roSGNode", "Settings")
    m.screenActive.contentFile  = "settingsTemporaryContent"
    m.screenActive.id           = "settings"
    m.screenActive.loaded       = true
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub


Sub showThousandPopup()
    hideAlbumImages()
    m.screenActive          = createObject("roSGNode", "InfoPopup")
    m.screenActive.id       = "ThousandPopup"
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible   = false
    m.loadingSpinner.visible = false
    m.albummarkupgrid.setFocus(true)
End Sub



Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if key = "back"
            if (m.screenActive <> invalid)            
                m.top.removeChild(m.screenActive)
                showMarkupGrid()
                m.screenActive = invalid
                m.settingsIcon.visible = true
                return true
            end if      

            if (m.albummarkupgrid.content <> invalid) and ( (m.albummarkupgrid.content.getChild(0).id <> "GP_ALBUM_LISTING_LIBRARY") or (m.albumPageList.hasFocus() = true) )    ' and (m.top.imageContent = invalid)
                m.albummarkupgrid.content       = m.albumListContent
                m.albummarkupgrid.jumpToItem    = m.albumSelection
                m.settingsIcon.visible          = false
                m.itemLabelMain2.text           = ""
                m.itemLabelMain3.text           = "<<     Paging     >>"
                centerMarkupGrid()
                showMarkupGrid()
                return true
            end if
            
        else if (key = "options") and (m.screenActive = invalid) and (m.albummarkupgrid.content.getChild(0).id = "GP_SLIDESHOW_START" or m.albummarkupgrid.content.getChild(0).id = "GP_VIDEO_BROWSE")
            showTempSetting()
            return true
            
        else if ((key = "options") or (key = "left")) and (m.screenActive <> invalid) and (m.screenActive.id = "settings")
            m.top.removeChild(m.screenActive)
            showMarkupGrid()
            m.screenActive          = invalid
            m.settingsIcon.visible  = true
            return true
            
        else if (key = "OK") and (m.screenActive <> invalid) and (m.screenActive.id = "ThousandPopup") and (m.screenActive.closeReady = "true")
            m.top.removeChild(m.screenActive)
            m.screenActive = invalid
            displayAlbumImages()
            return true
            
        else if key = "right" or key = "up" or key = "down"
            'To fix bug with search results
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End function
