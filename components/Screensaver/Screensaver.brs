'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    m.UriHandler = createObject("roSGNode","Photo UrlHandler")
    m.UriHandler.observeField("albumList","handleGetScreensaverAlbumList")
    m.UriHandler.observeField("albumImages","handleGetScreensaverAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")

    m.PhotoViewLogo = m.top.findNode("PhotoViewLogo")
    m.apiTimer      = m.top.findNode("apiTimer")
    m.apiTimer.observeField("fire","onApiTimerTrigger")

    device  = createObject("roDeviceInfo")
    ds = device.GetDisplaySize()

    if ds.w = 1920 then
        m.PhotoViewLogo.uri = "pkg://images/screensaver_splash_FHD.png"
    else
        m.PhotoViewLogo.uri = "pkg://images/screensaver_splash_HD.png"
    end if
    
    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
    'Load default settings
    loadDefaults()
    
    userCount    = oauth_count()
    selectedUser = RegRead("SSaverUser","Settings")
    m.userIndex  = 0
    m.apiPending = 0
    m.photoItems = []
    
    if selectedUser = invalid then      
        m.userIndex = 0
    else if selectedUser="All (Random)" then
        m.userIndex = 100
    else
        for i = 0 to userCount-1
            if m.userInfoEmail[i] = selectedUser then m.userIndex = i
        end for
    end if
    
    if userCount = 0 then
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/screensaver_splash.png"
        generic2            = {}
        generic2.timestamp  = "284040000"
        generic2.url        = "pkg:/images/cat_pic_1.jpg"
        generic3            = {}
        generic3.timestamp  = "284040000"
        generic3.url        = "pkg:/images/cat_pic_2.jpg"
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic2)
        m.photoItems.Push(generic3)
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
    
    m.apiTimer.control = "start"
    
End Sub


' URL Request to fetch album listing
Sub doGetScreensaverAlbumList(selectedUser=0 as Integer)
    print "Screensaver.brs [doGetScreensaverAlbumList]"  

    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))", "GET", "", 0)
End Sub


Sub doGetScreensaverAlbumImages(album As Object)
    print "Screensaver.brs - [doGetScreensaverAlbumImages]"
    
    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(0)
    makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index=1&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=330&imgmax="+getResolution(), "GET", "", 1)
End Sub


Sub handleGetScreensaverAlbumList(event as object)
    print "Screensaver.brs [handleGetAlbumList]"
  
    response = event.getData()

    m.apiPending = m.apiPending-1
    if response.code <> 200 then
        '''''doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
    
        album_cache_count   = 0
        albumsObject        = googleAlbumListing(rsp.entry)
        
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
    
    m.apiPending = m.apiPending-1
    
    if response.code <> 200 then
        '''''doRefreshToken()
    else
        rsp=ParseXML(response.content)
        print rsp
        'if rsp=invalid then
        '    ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
        'end if
        
        imagesObject = googleImageListing(rsp.entry)
        
        for each image in imagesObject
            tmp = {}
            tmp.url       = image.GetURL()
            tmp.timestamp = image.GetTimestamp()
            
            if image.IsVideo() then
                print "Ignore: "; image.GetURL()
            else
                print "Push: "; image.GetURL()
                m.photoItems.Push(tmp)
            end if    
        end for
    end if
End Sub


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending; " - Image Count: "; m.photoItems.Count()

    if m.apiPending = 0 then
        execScreensaver()
        m.apiTimer.control = "stop"
    end if

End Sub


Sub execScreensaver()
    print "START SHOW"
    m.screenActive = createObject("roSGNode", "DisplayPhotos")
    m.screenActive.id = "DisplayScreensaver"
    m.screenActive.content = m.photoItems
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub
