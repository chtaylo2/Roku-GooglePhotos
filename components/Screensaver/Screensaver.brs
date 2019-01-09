'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumList","handleGetScreensaverAlbumList")
    m.UriHandler.observeField("albumImages","handleGetScreensaverAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    m.UriHandler.observeField("searchResult","handleGetScreensaverAlbumImages")

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
            'Check Token Validity
            doGetScreensaverAlbumList(m.userIndex)
        end if
    end if
    
    m.apiTimer.control = "start"

End Sub


' URL Request to fetch album listing
Sub doGetScreensaverAlbumList(selectedUser=0 as Integer)
    print "Screensaver.brs [doGetScreensaverAlbumList]"  

    tmpData = [ "doGetScreensaverAlbumList", selectedUser ]

    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))", "GET", "", 0, tmpData)
End Sub


' URL Request to fetch Image listing
Sub doGetScreensaverAlbumImages(album As Object, selectedUser=0 as Integer)
    print "Screensaver.brs - [doGetScreensaverAlbumImages]"
    
    tmpData = [ "doGetScreensaverAlbumImages", album, selectedUser ]
    
    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index=1&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=330&imgmax="+getResolution(), "GET", "", 1, tmpData)
End Sub


' URL Request to fetch search
Sub doGetScreensaverSearch(album As Object, selectedUser=0 as Integer)
    print "Screensaver.brs [doGetScreensaverSearch]"
    
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
    
    if album = "Day" then
        keyword = "%22OFF"+currentMonth+" "+currentDay+"%22 "+"-"+currentYear
    else if album = "Week" then
        keyword = "%22"+pastMonth+" "+pastDay+" - "+currentMonth+" "+currentDay+"%22 "+"-"+pastYear+" -"+currentYear
    else if album = "Month" then
        keyword = "%22"+currentMonth+"%22 "+"-"+currentYear
    end if

    tmpData = [ "doGetScreensaverSearch", keyword ]
    keyword = keyword.Replace(" ", "+")
    
    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "?kind=photo&v=3.0&q="+keyword+"&max-results=1000&thumbsize=220&imgmax="+getResolution(), "GET", "", 3, tmpData)
End Sub


Sub handleGetScreensaverAlbumList(event as object)
    print "Screensaver.brs [handleGetAlbumList]"
  
    regStore  = "SSaverAlbums"
    regAlbums = RegRead(regStore, "Settings")
    response  = event.getData()

    m.apiPending = m.apiPending-1
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[1])
    else if response.code = 200
        rsp=ParseXML(response.content)
        print rsp
        if rsp<>invalid then
    
            album_cache_count   = 0
            albumsObject        = googleAlbumListing(rsp.entry)
 
            'Look for Time in History
            albumHistory = "Day|Week|Month".Split("|")
            for each album in albumHistory
                if (regAlbums <> invalid) and (regAlbums <> "")
                    parsedString = regAlbums.Split("|")
                    for each item in parsedString
                        albumUser = item.Split(":")
                        if albumUser[0] = album then
                             m.predecessor = "This "+album+" in History"
                             doGetScreensaverSearch(album, response.post_data[1])
                        end if
                    end for
                end if
             end for   
            
            if albumsObject.Count()>0 then
                for each album in albumsObject
                    'User has selected albums for screensaver
                    if (regAlbums <> invalid) and (regAlbums <> "")
                        parsedString = regAlbums.Split("|")
                        for each item in parsedString
                            albumUser = item.Split(":")
                            if albumUser[0] = album.GetID() then
                                m.predecessor = "null"
                                doGetScreensaverAlbumImages(album, response.post_data[1])
                            end if
                        end for
                    else
                        if album_cache_count = 0 and album.GetImageCount()>0 then
                            ' We will always pull node 0 as this is Auto Backup, likely contains most photos
                            album_idx = 0
                        else
                            ' Randomly pull 5 additional albums and cache photos
                            album_idx = Rnd(albumsObject.Count())-1
                        end if
                            
                        album_cache_count = album_cache_count+1

                        m.predecessor = "null"
                        doGetScreensaverAlbumImages(albumsObject[album_idx], response.post_data[1])
                        albumsObject.delete(album_idx)
        
                        if album_cache_count>=5
                            exit for
                        end if
                    end if
                end for
            end if
        end if
    end if
End Sub


Sub handleGetScreensaverAlbumImages(event as object)
    print "Screensaver.brs [handleGetScreensaverAlbumImages]"
  
    response     = event.getData()
    m.apiPending = m.apiPending-1

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[2])
    else if response.code = 200
        rsp=ParseXML(response.content)
        print rsp
        if rsp<>invalid then        
            imagesObject = googleImageListing(rsp.entry)
            
            for each image in imagesObject
                tmp = {}
                tmp.url         = image.GetURL()
                tmp.timestamp   = image.GetTimestamp()
                tmp.description = image.GetDescription()
                
                if image.IsVideo() then
                    'print "Ignore: "; image.GetURL()
                else
                    'print "Push: "; image.GetURL()
                    m.photoItems.Push(tmp)
                end if    
            end for
        end if
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

    if m.photoItems.Count() = 0 then
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/screensaver_splash.png"
        m.photoItems.Push(generic1)
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/black_pixel.png"
        m.photoItems.Push(generic1)
        m.predecessor       = "No images found. Try another album"
    end if

    print "START SHOW"
    m.screenActive = createObject("roSGNode", "DisplayPhotos")
    m.screenActive.id = "DisplayScreensaver"
    m.screenActive.predecessor = m.predecessor
    m.screenActive.content = m.photoItems
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub
