
Sub init()
    m.UriHandler = createObject("roSGNode","Photo UrlHandler")
    m.UriHandler.observeField("albumList","handleGetAlbumList")
	m.UriHandler.observeField("albumImages","handleGetAlbumImages")
	m.UriHandler.observeField("refreshToken","handleRefreshToken")

    m.albummarkupgrid = m.top.findNode("albumGrid")
	m.itemLabelMain1  = m.top.findNode("itemLabelMain1")
	m.itemLabelMain2  = m.top.findNode("itemLabelMain2")

	m.content = createObject("RoSGNode","ContentNode")
	
    'Load common variables
    loadCommon()
	
	loadReg()
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


sub doRefreshToken()
    print "Albums.brs [doRefreshToken]"

    params = "client_id="                  + m.clientId
    params = params + "&client_secret="    + m.clientSecret
    params = params + "&refresh_token="    + m.refreshToken[m.global.selectedUser]
    params = params + "&grant_type="       + "refresh_token"

    makeRequest({}, m.oauth_prefix+"/token", "POST", params, 2)
end sub


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
End Sub


Sub onItemSelected()
    'Item selected
    print "SELECTED: "; m.albummarkupgrid.itemSelected

	selection = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemSelected)
	
	'I wish brightscript supported case statements!
	if selection.id = "GP_ALBUM_LISTING" then
		googleAlbumPages(m.albumsObject[m.albummarkupgrid.itemSelected])
	else if selection.id = "GP_SLIDESHOW_START" then 
		print "START SHOW"
		m.screenActive = createObject("roSGNode", "Slideshow")
		m.screenActive.content = m.imagesMetaData
		m.top.appendChild(m.screenActive)
		m.screenActive.setFocus(true)
		
	else if selection.id = "GP_VIDEO_BROWSE" then
		print "VIDEO BROWSE - NOT DONE YET"
	else if selection.id = "GP_IMAGE_BROWSE" then
		print "IMAGE BROWSE - NOT DONE YET"
	end if
End Sub


Sub addItem(store as object, id as string, hdgridposterurl as string, shortdescriptionline1 as string, shortdescriptionline2 as string)
    item = store.createChild("ContentNode")
	item.id = id
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
    if album.GetImageCount() > 1000 then
		'lastPopup = RegRead("ThousandPopup","Settings")
        'if lastPopup=invalid then googlephotos_thousandpopup()
	    'googlephotos_browse_pages(album)
	else
        doGetAlbumImages(album)
	end if
End Sub


Sub googleDisplayImageMenu(album As Object, imageList As Object)
	print "Albums.brs - [googleDisplayImageMenu]"
	
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
			print "VIDEO: "; tmp.url
		else
			m.imagesMetaData.Push(tmp)
			print "IMAGE: "; tmp.url
		end if
	end for
    
	pagesShow  = ""
	if totalPages > 1 then
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
'		else 'Video only album
'            googlephotos_browse_videos(videos, title)
		end if
	else 'Photo only album			
		addItem(m.menuSelected, "GP_SLIDESHOW_START", m.imagesMetaData[0].thumbnail, Pluralize(m.imagesMetaData.Count(),"Photo") + " - Start Slideshow", pagesShow)
		addItem(m.menuSelected, "GP_IMAGE_BROWSE", listIcon, "Browse Photos", "")
	end if
	
	m.itemLabelMain2.text = ""
	m.albummarkupgrid.content = m.menuSelected
	
	centerMarkupBox()
End Sub


Sub centerMarkupBox()
	'Center the MarkUp Box
	markupRectAlbum = m.albummarkupgrid.boundingRect()
	centerx = (1280 - markupRectAlbum.width) / 2

	m.albummarkupgrid.translation = [ centerx+18, 240 ]
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"        
            if (m.albummarkupgrid.content <> invalid) and (m.albummarkupgrid.content.getChild(0).id <> "GP_ALBUM_LISTING" )
				m.albummarkupgrid.content = m.content
				centerMarkupBox()
				
                return true
            end if
        end if
    end if
    return false
End function