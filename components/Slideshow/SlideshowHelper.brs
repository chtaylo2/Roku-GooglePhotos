'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

' This is our slideshow function declaration script.
' Since ROKU doesn't support global functions, the following must be added to each XML file where needed
' <script type="text/brightscript" uri="pkg:/components/Utils/SlideshowHelper.brs" />


'*********************************************************
'**
'** OAUTH HANDLERS
'**
'*********************************************************

Sub doRefreshToken(post_data=[] as Object, selectedUser=-1 as Integer)
    print "SlideshowHelper.brs [doRefreshToken]"

    post_data.Push(selectedUser)
    
    params = "client_id="                  + m.clientId
    params = params + "&client_secret="    + m.clientSecret
    params = params + "&grant_type="       + "refresh_token"
    
    if selectedUser<>-1 then
        params = params + "&refresh_token="    + m.refreshToken[selectedUser]
    else
        params = params + "&refresh_token="    + m.refreshToken[m.global.selectedUser]
    end if

    makeRequest({}, m.oauth_prefix+"/token", "POST", params, 2, post_data)
End Sub


Function handleRefreshToken(event as object)
    print "SlideshowHelper.brs [handleRefreshToken]"

    status = -1
    errorMsg = ""
    refreshData = m.UriHandler.refreshToken
    
    if refreshData <> invalid
        if (refreshData.code <> 200) and (refreshData.code <> 400)
            errorMsg = "An Error Occurred in 'handleRefreshToken'. Code: "+(refreshData.code).toStr()+" - " +refreshData.error
        else if refreshData.code = 400
            'CODE: 400 - Google will not allow us to use refresh token. Likely expired.
            m.screenActive          = createObject("roSGNode", "ExpiredPopup")
            m.screenActive.id       = "ExpiredPopup"
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
        else
            json = ParseJson(refreshData.content)
            if json = invalid
                errorMsg = "Unable to parse Json response: handleRefreshToken"
                status = 1
            else if type(json) <> "roAssociativeArray"
                errorMsg = "Json response is not an associative array: handleRefreshToken"
                status = -1
            else if json.DoesExist("error")
                errorMsg = "Json error response: [handleRefreshToken] " + json.error
                status = 1
            else
                status = 0
                ' We have our tokens

                m.accessToken[refreshData.post_data[refreshData.post_data.Count()-1]]  = getString(json,"access_token")
                    
                m.tokenType          = getString(json,"token_type")
                m.tokenExpiresIn     = getInteger(json,"expires_in")
                refreshToken         = getString(json,"refresh_token")
                
                if refreshToken <> ""
                        m.refreshToken[refreshData.post_data[refreshData.post_data.Count()-1]] = refreshToken
                end if

                'Save cached values to registry
                saveReg()
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
    
    if status = 0 then
        if refreshData.post_data[0] = "doGetLibraryImages" then
            doGetLibraryImages(refreshData.post_data[1], refreshData.post_data[2], refreshData.post_data[3])
        else if refreshData.post_data[0] = "doGetAlbumImages" then
            doGetAlbumImages(refreshData.post_data[1], refreshData.post_data[2], refreshData.post_data[3])
        else if refreshData.post_data[0] = "doGetSearch" then
            doGetSearch(refreshData.post_data[1], refreshData.post_data[2], refreshData.post_data[3], refreshData.post_data[4])
        else if refreshData.post_data[0] = "doGetAlbumSelection" then
            doGetAlbumSelection()
        else
            doGetAlbumList(refreshData.post_data[1])
        end if
    end if
End Function


'*********************************************************
'**
'** ALBUM HANDLERS
'**
'*********************************************************

' URL Request to fetch album listing
Sub doGetAlbumList(selectedUser=0 as Integer, pageNext="" As String)
    print "SlideshowHelper.brs [doGetAlbumList]"  

    tmpData = [ "doGetAlbumList", selectedUser, pageNext ]

    params = "pageSize=50"
    if pageNext<>"" then
        params = params + "&pageToken=" + pageNext
    end if

    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/albums?"+params, "GET", "", 0, tmpData)
End Sub


' Create full album list from XML response
Function googleAlbumListing(jsonlist As Object) As Object
    albumlist=CreateObject("roList")
    
    'print formatJSON(jsonlist)
    for each record in jsonlist["albums"]
        album=googleAlbumCreateRecord(record)

        if album.GetImageCount > 0 then
            ' Do not show photos from Google Hangout albums or any marked with "Private" in name
            if album.GetTitle.instr("Hangout:") = -1 and album.GetTitle.instr("rivate") = -1 then
                albumlist.Push(album)
            end if
        end if
    next
    
    return albumlist
End Function


' Create single album record from JSON entry
Function googleAlbumCreateRecord(json As Object) As Object
    album               = CreateObject("roAssociativeArray")
    album.GetTitle      = getString(json,"title")
    album.GetID         = getString(json,"id")
    album.GetImageCount = Val(getString(json,"mediaItemsCount"))
    album.GetThumb      = getString(json,"coverPhotoBaseUrl")+getResolution("SD")
        
    return album
End Function


' ********************************************************************
' **
' ** SEARCH HANDLERS
' **
' ********************************************************************

Function doSearchGenerate() As Object
    'Get Dates
    date         = CreateObject("roDateTime")
    datepast     = createobject("rodatetime")
    date.ToLocalTime()
    datepast.ToLocalTime()
 
    'Calculate 7 days prior
    d1seconds    = datepast.asseconds() - (60 * 60 * 24 * 7)
    datepast.FromSeconds(d1seconds)
    
    cYear1 = date.GetYear()-1
    cYear2 = date.GetYear()-2
    cYear3 = date.GetYear()-3
    cYear4 = date.GetYear()-4
    cYear5 = date.GetYear()-5
    cMonth = date.GetMonth().ToStr()
    cDay   = date.GetDayOfMonth().ToStr()
    
    pYear1 = datepast.GetYear()-1
    pYear2 = datepast.GetYear()-2
    pYear3 = datepast.GetYear()-3
    pYear4 = datepast.GetYear()-4
    pYear5 = datepast.GetYear()-5
    pMonth = datepast.GetMonth().ToStr()
    pDay   = datepast.GetDayOfMonth().ToStr()
    
    searchStrings       = {}
    searchStrings.day   = "{'dateFilter': {'dates': [{'day': "+cDay+",'month': "+cMonth+",'year': "+cYear1.ToStr()+"},{'day': "+cDay+",'month': "+cMonth+",'year': "+cYear2.ToStr()+"},{'day': "+cDay+",'month': "+cMonth+",'year': "+cYear3.ToStr()+"},{'day': "+cDay+",'month': "+cMonth+",'year': "+cYear4.ToStr()+"},{'day': "+cDay+",'month': "+cMonth+",'year': "+cYear5.ToStr()+"}]}}"
    searchStrings.week  = "{'dateFilter': {'ranges': [{'startDate': {'day': "+pDay+",'month': "+pMonth+",'year': "+pYear1.ToStr()+"},'endDate': {'day': "+cDay+",'month': "+cMonth+",'year': "+cYear1.ToStr()+"}},{'startDate': {'day': "+pDay+",'month': "+pMonth+",'year': "+pYear2.ToStr()+"},'endDate': {'day': "+cDay+",'month': "+cMonth+",'year': "+cYear2.ToStr()+"}},{'startDate': {'day': "+pDay+",'month': "+pMonth+",'year': "+pYear3.ToStr()+"},'endDate': {'day': "+cDay+",'month': "+cMonth+",'year': "+cYear3.ToStr()+"}},{'startDate': {'day': "+pDay+",'month': "+pMonth+",'year': "+pYear4.ToStr()+"},'endDate': {'day': "+cDay+",'month': "+cMonth+",'year': "+cYear4.ToStr()+"}},{'startDate': {'day': "+pDay+",'month': "+pMonth+",'year': "+pYear5.ToStr()+"},'endDate': {'day': "+cDay+",'month': "+cMonth+",'year': "+cYear5.ToStr()+"}}]}}"
    searchStrings.month = "{'dateFilter': {'dates': [{'month': "+cMonth+",'year': "+cYear1.ToStr()+"},{'month': "+cMonth+",'year': "+cYear2.ToStr()+"},{'month': "+cMonth+",'year': "+cYear3.ToStr()+"},{'month': "+cMonth+",'year': "+cYear4.ToStr()+"},{'month': "+cMonth+",'year': "+cYear5.ToStr()+"}]}}"

    return searchStrings
End Function


Sub doGetSearch(albumid As String, keyword as string, selectedUser=0 as Integer, pageNext="" As String)
    print "SlideshowHelper.brs [doGetSearch]"
    
    if keyword <> ""    
        tmpData = [ "doGetSearch", albumid, keyword, selectedUser, pageNext ]

        params = "'pageSize': '100',"

        if pageNext<>"" then
            params = params + "'pageToken': '" + pageNext + "',"
        end if
        
        params = params + "'filters': " + keyword

        print "params: "; params
        
        m.apiPending = m.apiPending+1
        signedHeader = oauth_sign(selectedUser)
        signedHeader["Content-type"] = "application/json"
        makeRequest(signedHeader, m.gp_prefix + "/mediaItems:search/", "POST", "{" + params + "}", 3, tmpData)  
    end if
End Sub


' ********************************************************************
' **
' ** IMAGE HANDLERS
' **
' ********************************************************************

Sub doGetLibraryImages(albumid As String, selectedUser=0 as Integer, pageNext="" As String)
    print "SlideshowHelper.brs - [doGetLibraryImages]"
    
    print "GooglePhotos pageNext: "; pageNext

    tmpData = [ "doGetLibraryImages", albumid, selectedUser, pageNext ]
    
    params = "pageSize=100"
    if pageNext<>"" then
        params = params + "&pageToken=" + pageNext
    else
        'First query, reset MetaData
        m.videosMetaData    = []
        m.imagesMetaData    = []
    end if
    
    m.apiPending = m.apiPending+1
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/mediaItems?"+params, "GET", "", 1, tmpData)
End Sub


Sub doGetAlbumImages(albumid As String, selectedUser=0 as Integer, pageNext="" As String)
    print "SlideshowHelper.brs - [doGetAlbumImages]"

    print "GooglePhotos pageNext: "; pageNext

    tmpData = [ "doGetAlbumImages", albumid, selectedUser, pageNext ]

    params = "pageSize=100"
    params = params + "&albumId=" + albumid
    if pageNext<>"" then
        params = params + "&pageToken=" + pageNext
    else
        'First query, reset MetaData
        m.videosMetaData    = []
        m.imagesMetaData    = []
    end if
   
    m.apiPending = m.apiPending+1 
    signedHeader = oauth_sign(selectedUser)
    makeRequest(signedHeader, m.gp_prefix + "/mediaItems:search/", "POST", params, 1, tmpData)
End Sub


Function googleImageListing(jsonlist As Object) As Object
    images=CreateObject("roList")
    for each record in jsonlist["mediaItems"]
        image=googleImageCreateRecord(record)
        if image.GetURL<>invalid then
            images.Push(image)
        end if
    next
    
    return images
End Function


Function googleImageCreateRecord(json As Object) As Object
    image                = CreateObject("roAssociativeArray")
    image.GetTitle       = ""
    image.GetID          = getString(json,"id")
    image.GetDescription = getString(json,"description")
    image.GetURL         = getString(json,"baseUrl")
    image.GetFilename    = getString(json,"filename")
    image.GetTimestamp   = getString(json["mediaMetadata"],"creationTime")
    image.IsVideo        = (json["mediaMetadata"]["video"]<>invalid)
    image.GetVideoStatus = getString(json["mediaMetadata"]["video"],"status")
    
    return image
End Function


' ********************************************************************
' **
' ** REFRESH HANDLERS
' **
' ********************************************************************

Sub onURLRefreshTigger()
    print "SlideshowHelper.brs [onURLRefreshTigger]"
    
    m.albumActiveObject = m.top.albumobject

    for each albumid in m.albumActiveObject
    
      print "ALBUMID: "; albumid
      print "OBJECT: "; m.albumActiveObject[albumid]
    
        if type(m.albumActiveObject[albumid]) = "roAssociativeArray" then
            tmpPage  = ""
            tmpCount = "1"
            if m.albumActiveObject[albumid].previousPageTokens[m.albumActiveObject[albumid].previouspagetokens.Count()-1]<>invalid then
                tmpPair = m.albumActiveObject[albumid].previousPageTokens[m.albumActiveObject[albumid].previouspagetokens.Count()-1].Split("::")
                tmpPage = tmpPair[0]
                tmpCount = tmpPair[1]
            end if
        
            m.albumActiveObject[albumid].showCountStart = StrToI(tmpCount)
            m.albumActiveObject[albumid].showCountEnd = 0
            m.albumActiveObject[albumid].apiCount = 0
                
            if albumid.Instr("GP_LIBRARY") >= 0 then
                doGetLibraryImages(albumid, m.albumActiveObject[albumid].GetUserIndex, tmpPage)
            else if albumid.Instr("SearchResults") >= 0 then
            
                m.albumActiveObject[albumid].GetImageCount = 0
                m.albumActiveObject[albumid].previousPageTokens = []
                m.albumActiveObject[albumid].showCountStart = 1
                m.albumActiveObject[albumid].showCountEnd = 0
                m.albumActiveObject[albumid].apiCount = 0
                m.albumActiveObject[albumid].imagesMetaData = []
            
                m.apiTimer.control = "start"
                
                searchStrings = doSearchGenerate()
                doGetSearch(albumid, searchStrings[m.albumActiveObject[albumid].keyword], m.albumActiveObject[albumid].GetUserIndex, tmpPage)
            else
                doGetAlbumImages(albumid, m.albumActiveObject[albumid].GetUserIndex, tmpPage)
            end if
        end if
    end for
End Sub