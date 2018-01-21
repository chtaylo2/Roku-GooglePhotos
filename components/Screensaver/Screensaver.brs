
Sub init()

	m.UriHandler = createObject("roSGNode","Photo UrlHandler")
	m.UriHandler.observeField("albumList","handleGetScreensaverAlbumList")
    m.UriHandler.observeField("albumImages","handleGetScreensaverAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")

    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
	userCount 	 = oauth_count()
    selectedUser = RegRead("SSaverUser","Settings")
    m.userIndex  = 0
    
    if selectedUser = invalid then      
        m.userIndex = 0
    else if ssUser="All (Random)" then
        m.userIndex = 100
    else
        for i = 0 to userCount-1
            if m.userInfoEmail[i] = selectedUser then m.userIndex = i
        end for
    end if
    
	'm.userIndex = 100
	
    methodAvailable = ["Multi-Scrolling Photos", "Fading Photo - Large", "Fading Photo - Small"]
    selectedMethod  = RegRead("SSaverMethod","Settings")
    
    if selectedMethod = invalid then        
        m.ssMethodSel = methodAvailable[0]
    else if selectedMethod = "Random" then
        m.ssMethodSel = ssMethodAvailable[Rnd(methodAvailable.Count())-1]
    else
        m.ssMethodSel = selectedMethod            
    end if

    print "USER: "; m.userIndex
    print "METHOD: "; m.ssMethodSel
    
	m.photoItems = []
	
    if userCount = 0 then
        rsp="invalid"
    else

        'If m.userIndex is set to 100, means user wants random photos from each linked account shown.
        if m.userIndex = 100 then
            for i = 0 to userCount-1
				doGetScreensaverAlbumList(i)
            end for
        else
			doGetScreensaverAlbumList(m.userIndex)
        end if
    end if
End Sub


' URL Request to fetch album listing
Sub doGetScreensaverAlbumList(selectedUser=0 as Integer)
    print "Screensaver.brs [doGetScreensaverAlbumList]"  

    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))", "GET", "", 0)
End Sub


Sub doGetScreensaverAlbumImages(album As Object)
    print "Screensaver.brs - [doGetScreensaverAlbumImages]"
    
    signedHeader = oauth_sign(0)
    makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index=1&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=330&imgmax="+getResolution(), "GET", "", 1)
End Sub


Sub handleGetScreensaverAlbumList(event as object)
    print "Screensaver.brs [handleGetAlbumList]"
  
    response = event.getData()

    if response.code <> 200 then
        'doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
    
		album_cache_count 	= 0
        albumsObject 		= googleAlbumListing(rsp.entry)
		
		if albumsObject.Count()>0 then
            for each album in albumsObject
                if album_cache_count = 0 and album.GetImageCount()>0 then
                    ' We will always pull node 0 as this is Auto Backup, likely contains most photos
                    album_idx = 0
                else
                    ' Randomly pull 5 additional albums and cache photos
                    album_idx = Rnd(albumsObject.Count())-1
                end if
                    
                album_cache_count = album_cache_count+1

				doGetScreensaverAlbumImages(albumsObject[album_idx])
                albumsObject.delete(album_idx)

                if album_cache_count>=5
					exit for
                end if    
            end for
        end if

    end if
End Sub


Sub handleGetScreensaverAlbumImages(event as object)
    print "Screensaver.brs [handleGetScreensaverAlbumImages]"
  
    response = event.getData()
    
    if response.code <> 200 then
        doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
        
        imagesObject = googleImageListing(rsp.entry)
		
		for each image in imagesObject
            if image.GetURL().instr(".MOV") <> -1 Or image.GetURL().instr(".mp4") <> -1 then
                print "Ignore: "; image.GetURL()
            else
                print "Push: "; image.GetURL()
                m.photoItems.Push(image.GetURL())
            end if    
        end for

    end if
End Sub