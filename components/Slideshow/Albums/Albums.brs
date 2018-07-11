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
    
        album = CreateObject("roAssociativeArray")
        album.GetTitle=function():return "Search Results":end function
        album.GetImageCount=function():return Int(1):end function
        m.albumName = album.GetTitle()

        rsp=ParseXML(m.top.imageContent.content)
        m.imagesObject = googleImageListing(rsp.entry)
        googleDisplayImageMenu(album, m.imagesObject)
        
    else
        'Get user albums
        
        'Display Loading Spinner
        showLoadingSpinner(5, "GP_ALBUM_LISTING")
        
        'API CALL: Get album listing
        doGetAlbumList()
    end if
End Sub


' URL Request to fetch album listing
Sub doGetAlbumList()
    print "Albums.brs [doGetAlbumList]"  

    tmpData = [ "doGetAlbumList" ]

    signedHeader = oauth_sign(m.global.selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=300", "GET", "", 0, tmpData)
End Sub


Sub doGetAlbumImages(album As Object, index=0 as Integer)
    print "Albums.brs - [doGetAlbumImages]"
    
    totalPages = ceiling(album.GetImageCount() / 1000)
    
    startIndex = 1
    if index > 0 then startIndex=(index*1000)+1

    start = str(startIndex)
    start = start.Replace(" ", "")

    print "GooglePhotos StartIndex: "; start
    print "GooglePhotos Res: "; getResolution()

    tmpData = [ "doGetAlbumImages", album, start ]

    signedHeader = oauth_sign(m.global.selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index="+start+"&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=330&imgmax="+getResolution(), "GET", "", 1, tmpData)
End Sub


Sub handleGetAlbumList(event as object)
    print "Albums.brs [handleGetAlbumList]"
  
    errorMsg = ""
    response = event.getData()

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occured in 'handleGetAlbumList'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else
            m.albumsObject = googleAlbumListing(rsp.entry)
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
        errorMsg = "An Error Occured in 'handleGetAlbumImages'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else
            showall = 1
            if ( m.albumsObject[m.albummarkupgrid.itemSelected].GetTitle() = "Google Photos Timeline" ) then
                ' Remove any archived items from default store
                showall = 0
            end if

            m.imagesObject = googleImageListing(rsp.entry, showall)
            googleDisplayImageMenu(m.albumsObject[m.albummarkupgrid.itemSelected], m.imagesObject)
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
End Sub


Sub onItemSelected()
    'Item selected

    selection = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemSelected)

    if selection.id = "GP_ALBUM_LISTING" then
        m.albumSelection = m.albummarkupgrid.itemSelected
        album = m.albumsObject[m.albummarkupgrid.itemSelected]
        m.albumName = album.GetTitle()

        m.itemLabelMain2.text = m.albumName
        m.itemLabelMain3.text = ""

        if album.GetImageCount() > 1000 then
            googleAlbumPages(album)

            lastPopup = RegRead("ThousandPopup","Settings")
            if (lastPopup=invalid or lastPopup<>"true") then showThousandPopup()
        else

            'Display Loading Spinner
            showLoadingSpinner(3, "GP_LOADING")
        
            'API CALL: Get album image listing
            doGetAlbumImages(album)
        end if
        
    else if selection.id = "GP_SLIDESHOW_START" then 
        print "START SHOW"
        m.screenActive = createObject("roSGNode", "DisplayPhotos")
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
            addItem(m.imageThumbList, "GP_BROWSE", m.imagesMetaData[i].thumbnail, "", "")
        end for
        
        m.screenActive = createObject("roSGNode", "Browse")
        m.screenActive.id = selection.id
        m.screenActive.albumName = m.albumName + "  -  " + itostr(m.imagesMetaData.Count()) + " Photos"
        m.screenActive.metaData = m.imagesMetaData
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

    if albumList.Count() = 0 then
        m.itemLabelMain1.text = "There are no albums to display"
        m.itemLabelMain2.text = "See 'Tips and Tricks' on how to create new albums"

        'Turn off Loading Spinner
        m.loadingSpinner.visible = "false"
        
    else
        for each album in albumList
            addItem(m.albumListContent, "GP_ALBUM_LISTING", album.GetThumb(), album.GetTitle(), Pluralize(album.GetImageCount(),"Item"))
        end for
        
        m.albummarkupgrid.content = m.albumListContent
        
        centerMarkupGrid()
        showMarkupGrid()
        onItemFocused()
        
        m.albummarkupgrid.observeField("itemFocused", "onItemFocused") 
        m.albummarkupgrid.observeField("itemSelected", "onItemSelected")
        
        'Turn off Loading Spinner
        m.loadingSpinner.visible = "false"
        
        m.itemLabelMain3.text = "<<     Paging     >>"
    end if
    
End Sub


Sub googleAlbumPages(album As Object)
    
    m.albumPages = createObject("RoSGNode","ContentNode")
    totalPages   = album.GetImageCount() / 1000
    currentCount = album.GetImageCount()
    page_start   = 0
    page_end     = 0
    title        = album.GetTitle()
    thumb        = album.GetThumb()
    
    for i = 1 to ceiling(totalPages)
        page_start = 1 + page_end
        if currentCount > 1000 then
            page_end=page_end + 1000
            currentCount = currentCount - 1000
        else
            page_end=page_end + currentCount
        end if
        
        page_start_dply = str(page_start)
        page_start_dply = page_start_dply.Replace(" ", "")
        
        page_end_dply   = str(page_end)
        page_end_dply   = page_end_dply.Replace(" ", "")
        
        tmpExtra = ""
        if i = 1 then
            tmpExtra = " - Newest"
        end if
        

        if i < 12 then
            addItem(m.albumPages, "GP_ALBUM_PAGES", thumb, "Media Page " + str(i) + tmpExtra, "Items: "+page_start_dply+" thru "+page_end_dply)
        else if i = 12 then
            addItem(m.albumPages, "GP_ALBUM_PAGES", thumb, "Media Pages 12+", "Items: "+page_start_dply+"+")
        end if    
    end for

    m.albumPageList.content = m.albumPages
    m.albumPageInfo1.text     = title
    m.albumPageThumb.uri    = thumb
    displayAlbumPages()
    
End Sub


Sub onAlbumPageFocused()
    'Item focused
    focusedItem = m.albumPageList.content.getChild(m.albumPageList.itemFocused)
    m.albumPageInfo2.text = focusedItem.shortdescriptionline2
End Sub


Sub onAlbumPageSelected()
    'Item selected
    print "SELECTED: "; m.albumPageList.itemSelected
    
    if (m.albumPageList.itemSelected = 11) then
        showOverLoadPopup()
    else
        'Display Loading Spinner
        showLoadingSpinner(3, "GP_ALBUM_PAGES")    
    
        'API CALL: Get image based on page selected
        album = m.albumsObject[m.albummarkupgrid.itemSelected]
        doGetAlbumImages(album, m.albumPageList.itemSelected)
    end if
End Sub


Sub googleDisplayImageMenu(album As Object, imageList As Object)
    print "Albums.brs - [googleDisplayImageMenu]"
    
    m.menuSelected = createObject("RoSGNode","ContentNode")
    title          = album.GetTitle()
    totalPages     = ceiling(album.GetImageCount() / 1000)
    listIcon       = "pkg:/images/browse.png"
    videoOnly      = false
    
    m.videosMetaData=[]
    m.imagesMetaData=[]
    for each media in imageList
        tmp             = {}
        tmp.url         = media.GetURL()
        tmp.thumbnail   = media.GetThumb()
        tmp.timestamp   = media.GetTimestamp()
        tmp.description = media.GetDescription()
        
        if media.IsVideo() then
            m.videosMetaData.Push(tmp)
            'print "VIDEO: "; tmp.url
        else
            m.imagesMetaData.Push(tmp)
            'print "IMAGE: "; tmp.url
        end if
    end for
    
    pagesShow  = ""
    if totalPages > 1 then
        index = m.albumPageList.itemSelected
        currentPage = str(index + 1)
        currentPage = currentPage.Replace(" ", "")
        if totalPages > 11 then totalPages = 11
        totalPages  = str(totalPages)
        totalPages  = totalPages.Replace(" ", "")
        pagesShow   = "Page "+currentPage+" of "+totalPages
    end if

    if m.videosMetaData.Count()>0 then        
        if m.imagesMetaData.Count()>0 then 'Combined photo and photo album
            addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].thumbnail, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", title)
            addItem(m.menuSelected, "GP_VIDEO_BROWSE", m.videosMetaData[0].thumbnail, Pluralize(m.videosMetaData.Count(),"Video") + " - Browse", title)
            addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Browse", title)
       else 'Video only album
            addItem(m.menuSelected, "GP_VIDEO_BROWSE", m.videosMetaData[0].thumbnail, Pluralize(m.videosMetaData.Count(),"Video") + " - Browse", title)
            videoOnly = true
        end if
    else 'Photo only album          
        addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].thumbnail, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", title)
        addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Browse", title)
    end if
    
    m.itemLabelMain3.text           = pagesShow
    m.settingsIcon.visible          = true
    m.albummarkupgrid.content       = m.menuSelected
    m.albummarkupgrid.jumpToItem    = 0
    
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
    m.albummarkupgrid.visible   = true
    m.itemLabelMain1.visible    = true
    m.itemLabelMain2.visible    = true
    m.itemLabelMain3.visible    = true
    m.albumPageList.visible     = false
    
    m.albummarkupgrid.setFocus(true)
End Sub


Sub hideAlbumPages()
    m.albumPageList.visible     = false
    
    'Stop watching for events
    m.albumPageList.unobserveField("itemFocused") 
    m.albumPageList.unobserveField("itemSelected")  
End Sub


Sub displayVideoBrowse()
    m.videoThumbList = createObject("RoSGNode","ContentNode")
    for i = 0 to m.videosMetaData.Count()-1
        addItem(m.videoThumbList, "GP_BROWSE", m.videosMetaData[i].thumbnail, "", "")
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


Sub displayAlbumPages()
    m.albumPageList.visible     = true
    m.albummarkupgrid.visible   = false
    m.itemLabelMain1.visible    = false
    m.itemLabelMain2.visible    = false
    m.itemLabelMain3.visible    = false
    m.settingsIcon.visible      = false

    m.albumPageList.setFocus(true)
    
    'Watch for events - Unobserve first to make sure we're not already monitoring
    m.albumPageList.unobserveField("itemFocused") 
    m.albumPageList.unobserveField("itemSelected")
    m.albumPageList.observeField("itemFocused", "onAlbumPageFocused") 
    m.albumPageList.observeField("itemSelected", "onAlbumPageSelected")   
End Sub


Sub showLoadingSpinner(gridCount as integer, id as string)
    m.placeholder = createObject("RoSGNode","ContentNode")
    for i = 1 to gridCount
        addItem(m.placeholder, id, "pkg:/images/placeholder.png", "", "")
    end for
    
    m.albummarkupgrid.content = m.placeholder
    centerMarkupGrid()
    showMarkupGrid()
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
    hideAlbumPages()
    m.screenActive          = createObject("roSGNode", "InfoPopup")
    m.screenActive.id       = "ThousandPopup"
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub


Sub showOverLoadPopup()
    hideAlbumPages()
    m.screenActive          = createObject("roSGNode", "InfoPopup")
    m.screenActive.id       = "OverLoadPopup"
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
                
                if (m.albummarkupgrid.content.getChild(0).id = "GP_SLIDESHOW_START")
                    m.settingsIcon.visible = true
                end if
                
                return true
            end if      

            if (m.albummarkupgrid.content <> invalid) and ( (m.albummarkupgrid.content.getChild(0).id <> "GP_ALBUM_LISTING") or (m.albumPageList.hasFocus() = true) ) and (m.top.imageContent = invalid)
                m.albummarkupgrid.content       = m.albumListContent
                m.albummarkupgrid.jumpToItem    = m.albumSelection
                m.settingsIcon.visible          = false
                m.itemLabelMain2.text           = ""
                m.itemLabelMain3.text           = "<<     Paging     >>"
                centerMarkupGrid()
                showMarkupGrid()
                return true
            end if
            
        else if (key = "options") and (m.screenActive = invalid) and (m.albummarkupgrid.content.getChild(0).id = "GP_SLIDESHOW_START")
            showTempSetting()
            return true
            
        else if ((key = "options") or (key = "left")) and (m.screenActive <> invalid) and (m.screenActive.id = "settings")
            m.top.removeChild(m.screenActive)
            showMarkupGrid()
            m.screenActive          = invalid
            m.settingsIcon.visible  = true
            return true
            
        else if (key = "OK") and (m.screenActive <> invalid) and (m.screenActive.id = "ThousandPopup" or m.screenActive.id = "OverLoadPopup") and (m.screenActive.closeReady = "true")
            m.top.removeChild(m.screenActive)
            m.screenActive = invalid
            displayAlbumPages()
            return true
            
        else if key = "right" or key = "up" or key = "down"
            'To fix bug with search results
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End function
