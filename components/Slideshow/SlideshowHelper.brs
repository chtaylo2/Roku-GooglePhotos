'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
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
                
                if refreshData.post_data[0]<>invalid and (refreshData.post_data[0] = "doGetScreensaverAlbumList" or refreshData.post_data[0] = "doGetScreensaverAlbumImages" or refreshData.post_data[0] = "doGetAlbumSelection") then
                    'Don't use global set user. Screensaver uses this.
                    m.accessToken[refreshData.post_data[1]]  = getString(json,"access_token")
                else
                    m.accessToken[m.global.selectedUser]  = getString(json,"access_token")
                end if
                    
                m.tokenType          = getString(json,"token_type")
                m.tokenExpiresIn     = getInteger(json,"expires_in")
                refreshToken         = getString(json,"refresh_token")
                
                if refreshToken <> ""
                        m.refreshToken[m.global.selectedUser] = refreshToken
                end if
    
                'Query User info
                'status = m.RequestUserInfo(m.accessToken.Count()-1, false)
    
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
        if refreshData.post_data[0] = "doGetScreensaverAlbumList" then
            doGetScreensaverAlbumList(refreshData.post_data[1])
        else if refreshData.post_data[0] = "doGetScreensaverAlbumImages" then
            doGetScreensaverAlbumImages(refreshData.post_data[1], refreshData.post_data[2])
        else if refreshData.post_data[0] = "doGetAlbumImages" then
            doGetAlbumImages(refreshData.post_data[1], refreshData.post_data[2])
        else if refreshData.post_data[0] = "doGetSearch" then
            doGetSearch(refreshData.post_data[1])
        else if refreshData.post_data[0] = "doGetAlbumSelection" then
            doGetAlbumSelection()
        else
            doGetAlbumList()
        end if
    end if
    
End Function


'*********************************************************
'**
'** ALBUM HANDLERS
'**
'*********************************************************

' Create full album list from XML response
Function googleAlbumListing(jsonlist As Object) As Object
    albumlist=CreateObject("roList")
    
    'print formatJSON(jsonlist)
    for each record in jsonlist["albums"]
        'print "RECORD: "; record
        album=googleAlbumCreateRecord(record)
        
        'print "ALBUM: "; album
        
        if album.GetImageCount() > 0 then
            ' Do not show photos from Google Hangout albums or any marked with "Private" in name
            if album.GetTitle().instr("Hangout:") = -1 and album.GetTitle().instr("rivate") = -1 then
                albumlist.Push(album)
            end if
        end if
    next
    
    return albumlist
End Function


' Create single album record from XML entry
Function googleAlbumCreateRecord(json As Object) As Object
    album = CreateObject("roAssociativeArray")
    album.json=json

    album.GetTitle=function():return getString(m.json,"title"):end function
    album.GetID=function():return getString(m.json,"id"):end function
    album.GetImageCount=function():return Val(getString(m.json,"mediaItemsCount")):end function
    album.GetThumb=function():return getString(m.json,"coverPhotoBaseUrl"):end function
    
    return album
End Function



' ********************************************************************
' **
' ** IMAGE HANDLERS
' **
' ********************************************************************

Function googleImageListing(jsonlist As Object) As Object
    images=CreateObject("roList")
    'print formatJSON(jsonlist)
    for each record in jsonlist["mediaItems"]
        image=googleImageCreateRecord(record)
        if image.GetURL()<>invalid then
            images.Push(image)
        end if
    next
    
    return images
End Function


Function googleImageCreateRecord(json As Object) As Object

    image = CreateObject("roAssociativeArray")
    image.json=json
    image.GetTitle=function():return "":end function
    image.GetID=function():return getString(m.json,"id"):end function
    image.GetDescription=function():return getString(m.json,"description"):end function
    image.GetURL=function():return getString(m.json,"baseUrl"):end function
    image.GetFilename=function():return getString(m.json,"filename"):end function
    image.GetTimestamp=function():return getString(m.json["mediaMetadata"],"creationTime"):end function
    image.IsVideo=function():return (m.json["mediaMetadata"]["video"]<>invalid):end function
    image.GetVideoStatus=function():return getString(m.json["mediaMetadata"]["video"],"status"):end function
    
    print "IsVideo: "; image.IsVideo()
    print "GetVideoStatus: "; image.GetVideoStatus()
    
    return image
End Function


Function get_thumb()
    if m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail").Count()>0 then
        return m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail")[0].GetAttributes()["url"]
    end if
    
    return "pkg:/images/icon_s.png"
End Function


Function get_image_url()
    images=m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:content")
    if m.IsVideo() then
        if m.GetVideoStatus()="final" or m.GetVideoStatus()="ready" then
            for each image in images
                if image.GetAttributes()["type"]="video/mpeg4" then
                    return image.GetAttributes()["url"]
                end if
            end for
        end if
    else
        if images[0]<>invalid then
            return images[0].GetAttributes()["url"]
        end if
    end if
    
    return invalid
End Function
