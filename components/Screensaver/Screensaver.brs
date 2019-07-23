'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()

    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumList","handleGetAlbumList")
    m.UriHandler.observeField("albumImages","handleGetAlbumImages")
    m.UriHandler.observeField("searchResult","handleGetAlbumImages")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    m.UriHandler.observeField("searchResult","handleGetScreensaverAlbumImages")

    m.PhotoViewLogo = m.top.findNode("PhotoViewLogo")
    m.apiTimer      = m.top.findNode("apiTimer")
    m.apiTimer.observeField("fire","onApiTimerTrigger")
    
    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
    'Load default settings
    loadDefaults()

    ds = m.device.GetDisplaySize()

    if ds.w = 1920 then
        m.PhotoViewLogo.uri = "pkg://images/screensaver_splash_FHD.png"
    else
        m.PhotoViewLogo.uri = "pkg://images/screensaver_splash_HD.png"
    end if

    m.userCount              = oauth_count()
    selectedUser             = RegRead("SSaverUser","Settings")
    regAlbums                = RegRead("SSaverAlbums", "Settings")
    m.userIndex              = 0
    m.apiPending             = 0
    m.photoItems             = []
    m.albumActiveObject      = {}
    m.albumsObject           = {}
    m.albumsObject["albums"] = []
    m.albumsObject.apiCount = 0
    
    if selectedUser = invalid then      
        m.userIndex = 0
    else if selectedUser="All (Random)" then
        m.userIndex = 100
    else
        for i = 0 to m.userCount-1
            if m.userInfoEmail[i] = selectedUser then m.userIndex = i
        end for
    end if
    
    if m.userCount = 0 then
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/screensaver_splash.png"
        generic1.filename   = "screensaver_splash.png"
        generic2            = {}
        generic2.timestamp  = "284040000"
        generic2.url        = "pkg:/images/cat_pic_1.jpg"
        generic2.filename   = "cat_pic_1.jpg"
        generic3            = {}
        generic3.timestamp  = "284040000"
        generic3.url        = "pkg:/images/cat_pic_2.jpg"
        generic3.filename   = "cat_pic_1.jpg"
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic1)
        m.photoItems.Push(generic2)
        m.photoItems.Push(generic3)
    else
        'If m.userIndex is set to 100, means user wants random photos from each linked account shown.
        if m.userIndex = 100 then
            for i = 0 to m.userCount-1
                doGetAlbumList(i)
            end for
        else if (regAlbums = invalid or regAlbums = "")
            doGetAlbumList(m.userIndex)
        else
            'Do nothing here. apiTimer will trigger processAlbums()
        end if
    end if
    
    m.apiTimer.control = "start"

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
        keyword = "%22"+currentMonth+" "+currentDay+"%22 "+"-"+currentYear
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


Sub handleGetAlbumList(event as object)
    print "Screensaver.brs [handleGetAlbumList]"
  
    response  = event.getData()

    m.apiPending = m.apiPending-1
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[1])
    else if response.code = 200
        rsp=ParseJson(response.content)
        if rsp<>invalid then   
            albumList = googleAlbumListing(rsp)         
            
            for each album in albumList
                    album.GetUserIndex = response.post_data[1]
                    m.albumsObject["albums"].Push(album)
            end for          

            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumsObject.nextPageToken = pageNext
                m.albumsObject.apiCount = m.albumsObject.apiCount + 1
                if m.albumsObject.apiCount < m.maxApiPerPage then
                    doGetAlbumList(response.post_data[1], pageNext)
                end if
            end if
        end if       
    end if
End Sub


Sub processAlbums()

    regStore  = "SSaverAlbums"
    regAlbums = RegRead(regStore, "Settings")
    album_cache_count = 0
       
    'Look for Time in History - We'll only allow 1 of these selections. Doesn't make sense to allow multiple as they are inclusive.
    albumHistory = "Day|Week|Month".Split("|")
    searchStrings = doSearchGenerate()
    for each album in albumHistory
        if (regAlbums <> invalid) and (regAlbums <> "")
            parsedString = regAlbums.Split("|")
            for each item in parsedString
                albumUser = item.Split(":")
                if albumUser[0] = album then
                    m.predecessor = "This "+album+" in History"
                    tmp                    = {}
                    tmp.GetImageCount      = 0
                    tmp.showCountStart     = 1
                    tmp.showCountEnd       = 0
                    tmp.apiCount           = 0
                    tmp.previousPageTokens = []
                    tmp.GetID              = "SearchResults"
                    tmp.GetUserIndex       = Strtoi(albumUser[1])
                    tmp.keyword            = album
                    m.albumActiveObject[tmp.GetID] = tmp
                    doGetSearch(tmp.GetID, Strtoi(albumUser[1]), searchStrings[album])
                end if
            end for
        end if
    end for
    
    if m.albumActiveObject["SearchResults"] = invalid then
    
        'Handle GooglePhotos Library Albums
        if (regAlbums <> invalid) and (regAlbums <> "") and (m.userIndex <> 100)
            'User has selected albums for screensaver
            parsedString = regAlbums.Split("|")
            for each item in parsedString
                albumUser = item.Split(":")
                if albumUser[0] = "GP_LIBRARY" then
                    m.predecessor = "null"
                    tmp                    = {}
                    tmp.GetImageCount      = 0
                    tmp.showCountStart     = 1
                    tmp.showCountEnd       = 0
                    tmp.apiCount           = 0
                    tmp.previousPageTokens = []
                    tmp.GetID              = "GP_LIBRARY_" + albumUser[1]
                    tmp.GetUserIndex       = Strtoi(albumUser[1])
                    m.albumActiveObject[tmp.GetID] = tmp
                    
                    print "TEMP: "; tmp.GetID
                    
                    doGetLibraryImages(tmp.GetID, Strtoi(albumUser[1]))
                end if
            end for
    
        else
            'If m.userIndex is set to 100, means user wants random photos from each linked account shown.
            if m.userIndex = 100 then
                for i = 0 to m.userCount-1
                    tmp                    = {}
                    tmp.GetImageCount      = 0
                    tmp.showCountStart     = 1
                    tmp.showCountEnd       = 0
                    tmp.apiCount           = 0
                    tmp.previousPageTokens = []
                    tmp.GetID              = "GP_LIBRARY_" + i.ToStr()
                    tmp.GetUserIndex       = i
                    m.albumActiveObject[tmp.GetID] = tmp
                    doGetLibraryImages(tmp.GetID, i)
                end for
            else
                tmp                    = {}
                tmp.GetImageCount      = 0
                tmp.showCountStart     = 1
                tmp.showCountEnd       = 0
                tmp.apiCount           = 0
                tmp.previousPageTokens = []
                tmp.GetID              = "GP_LIBRARY_" + m.userIndex.ToStr()
                tmp.GetUserIndex       = m.userIndex
                m.albumActiveObject[tmp.GetID] = tmp
                doGetLibraryImages(tmp.GetID, m.userIndex)
            end if
        end if
    
        'User has selected albums for screensaver
        if (regAlbums <> invalid) and (regAlbums <> "") and (m.userIndex <> 100)
            parsedString = regAlbums.Split("|")
            for each item in parsedString
                if item <> "" then
                    albumUser = item.Split(":")
                    if albumUser[0] <> "GP_LIBRARY" then
                        m.predecessor = "null"
                        m.albumActiveObject[albumUser[0]] = {}
                        m.albumActiveObject[albumUser[0]].GetID = albumUser[0]
                        m.albumActiveObject[albumUser[0]].GetUserIndex = Strtoi(albumUser[1])
                        doGetAlbumImages(albumUser[0], Strtoi(albumUser[1]))
                    end if
                end if
            end for
            
        else if m.albumsObject["albums"].Count()>0 then
        
            for each album in m.albumsObject["albums"]
                ' Randomly pull 5 additional albums and cache photos
                album_idx = Rnd(m.albumsObject["albums"].Count())-1
        
                m.albumActiveObject[m.albumsObject["albums"][album_idx].GetID] = {}
                m.albumActiveObject[m.albumsObject["albums"][album_idx].GetID].GetID = m.albumsObject["albums"][album_idx].GetID
                m.albumActiveObject[m.albumsObject["albums"][album_idx].GetID].GetUserIndex = m.albumsObject["albums"][album_idx].GetUserIndex
                doGetAlbumImages(m.albumsObject["albums"][album_idx].GetID, m.albumsObject["albums"][album_idx].GetUserIndex)
                m.albumsObject["albums"].delete(album_idx)
                                    
                album_cache_count = album_cache_count+1
                m.predecessor = "null"
                
                if album_cache_count>=5
                    exit for
                end if
            end for
        end if
    end if
End Sub


Sub handleGetAlbumImages(event as object)
    print "Screensaver.brs [handleGetAlbumImages]"
  
    response     = event.getData()
    m.apiPending = m.apiPending-1
    albumid      = response.post_data[1]

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[2])
    else if response.code = 200
        rsp=ParseJson(response.content)
        'print rsp
        if rsp<>invalid then        
            imagesObject = googleImageListing(rsp)
            
            localCount = 0
            for each image in imagesObject
                tmp = {}
                tmp.id          = image.GetID
                tmp.url         = image.GetURL
                tmp.timestamp   = image.GetTimestamp
                tmp.description = image.GetDescription
                tmp.filename    = image.GetFilename
                
                localCount = localCount + 1
                if image.IsVideo then
                    'print "Ignore: "; image.GetURL
                else
                    'print "Push: "; image.GetURL
                    m.photoItems.Push(tmp)
                end if    
            end for

            if m.albumActiveObject[albumid].showCountEnd=invalid then
                m.albumActiveObject[albumid].showCountEnd = 0
            end if
            if m.albumActiveObject[albumid].apiCount=invalid then
                m.albumActiveObject[albumid].apiCount = 0
            end if
            if m.albumActiveObject[albumid].previousPageTokens=invalid then
                m.albumActiveObject[albumid].previousPageTokens = []
            end if
            
            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumActiveObject[albumid].nextPageToken = pageNext
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + localCount
                m.albumActiveObject[albumid].apiCount = m.albumActiveObject[albumid].apiCount + 1

                if (m.albumActiveObject[albumid].apiCount < m.maxApiPerPage) and (m.albumActiveObject[albumid].showCountEnd < m.maxImagesPerPage) then    
                    if albumid.Instr("GP_LIBRARY") >= 0 then
                        doGetLibraryImages(albumid, response.post_data[2], pageNext)
                    else if albumid.Instr("SearchResults") >= 0 then
                        searchStrings = doSearchGenerate()
                        doGetSearch(albumid, response.post_data[2], searchStrings[m.albumActiveObject[albumid].keyword], pageNext)
                    else
                        doGetAlbumImages(albumid, response.post_data[2], pageNext)
                    end if
                end if
            else
                m.albumActiveObject[albumid].nextPageToken = invalid
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + localCount
            end if
            
        end if
    end if
End Sub


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending; " - Image Count: "; m.photoItems.Count()

    if m.apiPending = 0 then
        if (m.albumActiveObject.Count() = 0) and (m.userCount <> 0) then
            processAlbums()
        else
            execScreensaver()
            m.apiTimer.control = "stop"
        end if
    end if

End Sub


Sub execScreensaver()

    if m.photoItems.Count() = 0 then
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/screensaver_splash.png"
        generic1.filename   = "screensaver_splash.png"
        m.photoItems.Push(generic1)
        generic1            = {}
        generic1.timestamp  = "284040000"
        generic1.url        = "pkg:/images/black_pixel.png"
        generic1.filename   = "black_pixel.png"
        m.photoItems.Push(generic1)
        m.predecessor       = "No images found. Try another album"
    end if

    print "TOTAL SENDING: "; m.photoItems.Count()
    print "START SHOW"
    m.screenActive = createObject("roSGNode", "DisplayPhotos")
    m.screenActive.id = "DisplayScreensaver"
    m.screenActive.predecessor = m.predecessor
    m.screenActive.albumobject = m.albumActiveObject
    m.screenActive.content = m.photoItems
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub
