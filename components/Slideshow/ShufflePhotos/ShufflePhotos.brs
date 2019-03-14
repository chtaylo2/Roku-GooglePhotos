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
    m.UriHandler.observeField("refreshToken","handleRefreshToken")

    m.noticeDialog  = m.top.findNode("noticeDialog")
    m.PhotoViewLogo = m.top.findNode("PhotoViewLogo")
    m.apiTimer      = m.top.findNode("apiTimer")
    m.pullPhotos    = m.top.findNode("pullPhotos")
    
    m.apiTimer.observeField("fire","onApiTimerTrigger")
    m.pullPhotos.observeField("fire","onPullPhotoTrigger")

    device  = createObject("roDeviceInfo")
    ds = device.GetDisplaySize()

    if ds.w = 1920 then
        m.PhotoViewLogo.uri = "pkg:/images/shuffle_splash_FHD.png"
    else
        m.PhotoViewLogo.uri = "pkg:/images/shuffle_splash_HD.png"
    end if
    
    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
    m.apiPending = 0
    m.photoItems = []

    'API CALL: Get album listing
    doGetAlbumList()
    m.apiTimer.control = "start"
    
End Sub


' URL Request to fetch album listing
'Sub doGetAlbumList()
'    print "ShufflePhotos.brs [doGetAlbumList]"  

'    tmpData = [ "doGetAlbumList" ]
    
''    m.apiPending = m.apiPending+1
 ''   signedHeader = oauth_sign(m.global.selectedUser)
'    makeRequest(signedHeader, m.gp_prefix + "?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=300", "GET", "", 0, tmpData)
'End Sub


'Sub doGetAlbumImages(album As Object)
 '   print "ShufflePhotos.brs - [doGetAlbumImages]"

 '   tmpData = [ "doGetAlbumImages", album ]
    
 '   m.apiPending = m.apiPending+1
 '   signedHeader = oauth_sign(m.global.selectedUser)
 '   makeRequest(signedHeader, m.gp_prefix + "/albumid/"+album.GetID()+"?start-index=1&max-results=1000&kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:streamId,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=330&imgmax="+getResolution(), "GET", "", 1, tmpData)
'End Sub


Sub handleGetAlbumListOFF(event as object)
    print "ShufflePhotos.brs [handleGetAlbumList]"
  
    errorMsg = ""
    response = event.getData()

    m.apiPending = m.apiPending-1

    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumList'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else
    
            album_cache_count   = 0
            m.albumsObject      = googleAlbumListing(rsp.entry)
            
            if m.albumsObject.Count()>0 then
                for each album in m.albumsObject
                    ' Randomly pull 5 additional albums and cache photos
                    album_idx = Rnd(m.albumsObject.Count())-1
                        
                    album_cache_count = album_cache_count+1
    
                    doGetAlbumImages(m.albumsObject[album_idx])
                    m.albumsObject.delete(album_idx)
    
                    if album_cache_count>=5
                        exit for
                    end if    
                end for
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
        m.apiTimer.control = "stop"
        m.pullPhotos.control = "stop"
    end if  
    
End Sub


Sub handleGetAlbumImagesOFF(event as object)
    print "ShufflePhotos.brs [handleGetAlbumImages]"

    errorMsg = ""
    response = event.getData()
    
    m.apiPending = m.apiPending-1
    
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data)
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumImages'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseXML(response.content)
        print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else
        
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
            
            'If apiTimer is stopped, we'll push photos directly into the DisplayPhoto screen
            if m.apiTimer.control = "stop" then
                'Randomize the photos, regardless of settings. It's Shuffled photos!
                tmp = []
                for i = 0 to m.photoItems.Count()-1
                    nxt = GetRandom(m.photoItems)
                    tmp.push(m.photoItems[nxt])
                end for
                m.screenActive.content = tmp
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
        m.apiTimer.control = "stop"
        m.pullPhotos.control = "stop"
    end if
    
End Sub


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending; " - Image Count: "; m.photoItems.Count()
    if m.apiPending = 0 then
        execSlideshow()
        m.apiTimer.control = "stop"
    end if
End Sub


Sub onPullPhotoTrigger()
    'Reset photoItems
    m.photoItems = []
    
    if m.albumsObject.Count()>0 then
        album_idx = Rnd(m.albumsObject.Count())-1 
        doGetAlbumImages(m.albumsObject[album_idx])
        m.albumsObject.delete(album_idx)
    else
        m.pullPhotos.control = "stop"
    end if
End Sub


Sub execSlideshow()
    'Randomize the photos, regardless of settings. It's Shuffled photos!
    tmp = []
    for i = 0 to m.photoItems.Count()-1
        nxt = GetRandom(m.photoItems)
        tmp.push(m.photoItems[nxt])
    end for
    
    if tmp.Count() > 0 then 
        print "START SHOW"
        m.screenActive = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.id = "DisplayPhotos"
        m.screenActive.content = tmp
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
        m.pullPhotos.control = "start"
    else
        m.noticeDialog.visible  = true
        m.noticeDialog.title    = "Notice"
        m.noticeDialog.message  = "There are no photos to display, please add photos and try again"
        m.noticeDialog.buttons  = ""
        m.apiTimer.control      = "stop"
        m.pullPhotos.control    = "stop"
        m.PhotoViewLogo.setFocus(true)
    end if
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible = false
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
    end if
    return false
End function
