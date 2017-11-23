
sub init()
    m.UriHandler = createObject("roSGNode","Photo UrlHandler")
    m.UriHandler.observeField("response","handleResponse")

    m.albummarkupgrid = m.top.findNode("albumGrid")
	m.itemLabelMain1  = m.top.findNode("itemLabelMain1")

	m.content = createObject("RoSGNode","ContentNode")
	
    'Load common variables
    loadCommon()
	
	loadReg()
	doGetAlbumList()
	
end sub


sub doGetAlbumList()
    print "Albums.brs [doGetAlbumList]"

	signedHeader = oauth_sign(m.global.selectedUser)
	print "HEADER: "; signedHeader

    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=220", "GET", "", 0)
end sub


sub handleResponse(event as object)
    print "Albums.brs [handleResponse]"
  
    response = event.getData()

    rsp=ParseXML(response.content)
	print rsp
    'if rsp=invalid then
    '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
    'end if
	
    albums=googleAlbumListing(rsp.entry)
	googleAlbumDisplay(albums)

end sub


sub onItemFocused()
    'Item focused
    focusedItem = m.albummarkupgrid.content.getChild(m.albummarkupgrid.itemFocused)
    m.itemLabelMain1.text = focusedItem.shortdescriptionline1
end sub


sub onItemSelected()
    'Item selected
    print "SELECTED: "; m.albummarkupgrid.itemSelected
    'm.global.selectedUser = m.albummarkupgrid.itemSelected
end sub


sub addItem(store as object, hdgridposterurl as string, shortdescriptionline1 as string)
    item = store.createChild("ContentNode")
    item.hdgridposterurl = hdgridposterurl
    item.shortdescriptionline1 = shortdescriptionline1
	item.x = "200"
end sub


Function googleAlbumListing(xmllist As Object) As Object
    albumlist=CreateObject("roList")
    for each record in xmllist
        album=googleAlbumCreateRecord(record)
        if album.GetImageCount() > 0 then
			' Do not show photos from Google Hangout albums or any marked with "Private" in name
			if album.GetTitle().instr("Hangout:") = -1 and album.GetTitle().instr("rivate") = -1 then
				albumlist.Push(album)
			end if
        end if
    next
    
    return albumlist
End Function


Function googleAlbumCreateRecord(xml As Object) As Object
    album = CreateObject("roAssociativeArray")
    album.xml=xml

    album.GetUsername=function():return m.xml.GetNamedElements("gphoto:user")[0].GetText():end function
    album.GetTitle=function():return m.xml.title[0].GetText():end function
    album.GetID=function():return m.xml.GetNamedElements("gphoto:id")[0].GetText():end function
    album.GetImageCount=function():return Val(m.xml.GetNamedElements("gphoto:numphotos")[0].GetText()):end function
    album.GetThumb=get_thumb
	
    return album
End Function


Function googleAlbumDisplay(albums As Object)
    for each album in albums
        addItem(m.content, album.GetThumb(), album.GetTitle())
    end for
	
	m.albummarkupgrid.content = m.content
	
	'Center the MarkUp Box
    markupRectAlbum = m.albummarkupgrid.boundingRect()
    centerx = (1280 - markupRectAlbum.width) / 2
    m.albummarkupgrid.translation = [ centerx+18, 240 ]
	
	m.albummarkupgrid.observeField("itemFocused", "onItemFocused") 
    m.albummarkupgrid.observeField("itemSelected", "onItemSelected")
End Function


Function get_thumb()
    if m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail").Count()>0 then
        return m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail")[0].GetAttributes()["url"]
    end if
    
    return "pkg:/images/icon_s.png"
End Function