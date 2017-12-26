
Sub init()
    m.UriHandler = createObject("roSGNode","Photo UrlHandler")
    m.UriHandler.observeField("albumList","handleGetAlbumList")
    m.UriHandler.observeField("albumImages","handleGetAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")

    m.albummarkupgrid = m.top.findNode("albumGrid")
    m.itemLabelMain1  = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2  = m.top.findNode("itemLabelMain2")
    m.settingsIcon    = m.top.findNode("settingsIcon")
    
    m.albumPageList   = m.top.findNode("albumPageList")
    m.albumPageThumb  = m.top.findNode("albumPageThumb")
    m.albumPageInfo1  = m.top.findNode("albumPageInfo1")
    m.albumPageInfo2  = m.top.findNode("albumPageInfo2")

    m.content = createObject("RoSGNode","ContentNode")
    
    'Load common variables
    loadCommon()
    
    'Load registration variables
    loadReg()
    
    'Focus album list
    doGetAlbumList()
    
End Sub


' URL Request to fetch album listing
Sub doGetAlbumList()
    print "Albums.brs [doGetAlbumList]"

    signedHeader = oauth_sign(m.global.selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=220", "GET", "", 0)
End Sub


Sub doGetAlbumImages(album As Object, index=0 as Integer)
    print "Albums.brs - [doGetAlbumImages]"
    
    print "ALBUM: "; album
    totalPages = ceiling(album.GetImageCount() / 1000)
    
    startIndex = 1
    if index > 0 then startIndex=(index*1000)+1

    start = str(startIndex)
    start = start.Replace(" ", "")

    print "GooglePhotos StartIndex: "; start
    print "GooglePhotos Res: "; getResolution()

    signedHeader = oauth_sign(m.global.selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index="+start+"&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax="+getResolution(), "GET", "", 1)
End Sub


Sub doRefreshToken()
    print "Albums.brs [doRefreshToken]"

    params = "client_id="                  + m.clientId
    params = params + "&client_secret="    + m.clientSecret
    params = params + "&refresh_token="    + m.refreshToken[m.global.selectedUser]
    params = params + "&grant_type="       + "refresh_token"

    makeRequest({}, m.oauth_prefix+"/token", "POST", params, 2)
End Sub


Sub handleGetAlbumList(event as object)
    print "Albums.brs [handleGetAlbumList]"
  
    response = event.getData()

    if response.code <> 200 then
        doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
    
        m.albumsObject = googleAlbumListing(rsp.entry)
        googleDisplayAlbums(m.albumsObject)
    end if
End Sub


Sub handleGetAlbumImages(event as object)
    print "Albums.brs [handleGetAlbumImages]"
  
    response = event.getData()
    
    if response.code <> 200 then
        doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
        
        m.imagesObject = googleImageListing(rsp.entry)
        googleDisplayImageMenu(m.albumsObject[m.albummarkupgrid.itemSelected], m.imagesObject)
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
    print "SELECTED: "; m.albummarkupgrid.itemSelected

    selection = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemSelected)
    
    if selection.id = "GP_ALBUM_LISTING" then
        album = m.albumsObject[m.albummarkupgrid.itemSelected]
        m.albumName = album.GetTitle()
    
        if album.GetImageCount() > 1000 then
            'lastPopup = RegRead("ThousandPopup","Settings")
            'if lastPopup=invalid then googlephotos_thousandpopup()
            googleAlbumPages(album)
        else
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

        m.videoThumbList = createObject("RoSGNode","ContentNode")
        for i = 0 to m.videosMetaData.Count()-1
            addItem(m.videoThumbList, "GP_BROWSE", m.videosMetaData[i].thumbnail, "", "")
        end for
        
        m.screenActive = createObject("roSGNode", "Browse")
        m.screenActive.id = selection.id
        m.screenActive.albumName = m.albumName + "  -  " + itostr(m.videosMetaData.Count()) + " Videos"
        m.screenActive.metaData = m.videosMetaData
        m.screenActive.content = m.videoThumbList
        m.screenActive.id = selection.id
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)

        hideAlbum()
        
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
        m.screenActive.id = selection.id
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)

        hideAlbum()
        
    end if
End Sub


Sub addItem(store as object, id as string, hdgridposterurl as string, shortdescriptionline1 as string, shortdescriptionline2 as string)
    item = store.createChild("ContentNode")
    item.id = id
    item.title = shortdescriptionline1
    item.hdgridposterurl = hdgridposterurl
    item.shortdescriptionline1 = shortdescriptionline1
    item.shortdescriptionline2 = shortdescriptionline2
    item.x = "200"
End Sub


Sub googleDisplayAlbums(albumList As Object)
    for each album in albumList
        addItem(m.content, "GP_ALBUM_LISTING", album.GetThumb(), album.GetTitle(), "")
    end for
    
    m.albummarkupgrid.content = m.content
    
    centerMarkupBox()
    
    m.albummarkupgrid.observeField("itemFocused", "onItemFocused") 
    m.albummarkupgrid.observeField("itemSelected", "onItemSelected")
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
        
        addIt = ""
        if i = 1 then
            addIt = " - Newest"
        end if
        
        addItem(m.albumPages, "GP_ALBUM_PAGES", thumb, "Media Page " + str(i) + addIt, "Items: "+page_start_dply+" thru "+page_end_dply)
        
    end for

    m.albumPageList.content = m.albumPages
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
    
    album = m.albumsObject[m.albummarkupgrid.itemSelected]
    doGetAlbumImages(album, m.albumPageList.itemSelected)
End Sub


Sub googleDisplayImageMenu(album As Object, imageList As Object)
    print "Albums.brs - [googleDisplayImageMenu]"
    
    displayAlbum()
    
    m.menuSelected = createObject("RoSGNode","ContentNode")
    title          = album.GetTitle()
    totalPages     = ceiling(album.GetImageCount() / 1000)
    listIcon       = "pkg:/images/browse.png"
    
    m.videosMetaData=[]
    m.imagesMetaData=[]
    for each media in imageList
        tmp           = {}
        tmp.url       = media.GetURL()
        tmp.thumbnail = media.GetThumb()
        tmp.timestamp = media.GetTimestamp()
        
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
        totalPages  = str(totalPages)
        totalPages  = totalPages.Replace(" ", "")
        pagesShow   = "Page "+currentPage+" of "+totalPages
    end if

    if m.videosMetaData.Count()>0 then        
        if m.imagesMetaData.Count()>0 then 'Combined photo and photo album
            addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].thumbnail, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", pagesShow)
            addItem(m.menuSelected, "GP_VIDEO_BROWSE", m.videosMetaData[0].thumbnail, Pluralize(m.videosMetaData.Count(),"Video"), pagesShow)
            addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, "Browse Photos", "")
'       else 'Video only album
'            googlephotos_browse_videos(videos, title)
        end if
    else 'Photo only album          
        addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].thumbnail, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", pagesShow)
        addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, "Browse Photos", "")
    end if
    
    m.itemLabelMain2.text = ""
    m.albummarkupgrid.content = m.menuSelected
    m.albummarkupgrid.jumpToItem = 0
    m.settingsIcon.visible = true
    
    centerMarkupBox()
End Sub


Sub centerMarkupBox()
    'Center the MarkUp Box
    markupRectAlbum = m.albummarkupgrid.boundingRect()
    centerx = (1280 - markupRectAlbum.width) / 2

    m.albummarkupgrid.translation = [ centerx+18, 240 ]
End Sub

 
Sub hideAlbum()
    m.albummarkupgrid.visible = false
    m.settingsIcon.visible    = false
    m.itemLabelMain1.visible  = false
    m.itemLabelMain2.visible  = false  
End Sub


Sub displayAlbum()
    m.albummarkupgrid.visible = true
    m.itemLabelMain1.visible = true
    m.itemLabelMain2.visible = true
    m.settingsIcon.visible = false
    m.albumPageList.visible = false
    
    m.albummarkupgrid.setFocus(true)
End Sub


Sub displayAlbumPages()
    m.albumPageList.visible = true
    m.albummarkupgrid.visible = false
    m.itemLabelMain1.visible = false
    m.itemLabelMain2.visible = false
    m.settingsIcon.visible = false
    
    m.albumPageList.setFocus(true)
    
    'Watch for events
    m.albumPageList.observeField("itemFocused", "onAlbumPageFocused") 
    m.albumPageList.observeField("itemSelected", "onAlbumPageSelected")
    
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                displayAlbum()
                m.screenActive = invalid
                return true
            end if      

            if (m.albummarkupgrid.content <> invalid) and (m.albummarkupgrid.content.getChild(0).id <> "GP_ALBUM_LISTING" )
                m.albummarkupgrid.content = m.content
                centerMarkupBox()
                
                return true
            end if
        end if
    end if
    return false
End function