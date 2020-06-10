'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2020 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumImages","handleGetAlbumImages")
    m.UriHandler.observeField("searchResult","handleGetSearch")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    
    m.PrimaryImage              = m.top.findNode("PrimaryImage")
    m.SecondaryImage            = m.top.findNode("SecondaryImage")
    m.BlendedPrimaryImage       = m.top.findNode("BlendedPrimaryImage")
    m.BlendedSecondaryImage     = m.top.findNode("BlendedSecondaryImage")
    m.FadeInPrimaryAnimation    = m.top.findNode("FadeInPrimaryAnimation")
    m.FadeInSecondaryAnimation  = m.top.findNode("FadeInSecondaryAnimation")
    m.FadeForeground            = m.top.findNode("FadeForeground")
    m.FadeOutForeground         = m.top.findNode("FadeOutForeground")
    m.PauseScreen               = m.top.findNode("PauseScreen")
    m.pauseImageCount           = m.top.findNode("pauseImageCount")
    m.pauseImageDetail          = m.top.findNode("pauseImageDetail")
    m.pauseImageDetail2         = m.top.findNode("pauseImageDetail2")
    m.RotationTimer             = m.top.findNode("RotationTimer")
    m.DownloadTimer             = m.top.findNode("DownloadTimer")
    m.URLRefreshTimer           = m.top.findNode("URLRefreshTimer")
    m.DisplayTimer              = m.top.findNode("DisplayTimer")
    m.DateTimer                 = m.top.findNode("DateTimer")
    m.Watermark                 = m.top.findNode("Watermark")
    m.MoveTimer                 = m.top.findNode("moveWatermark")
    m.RediscoverScreen          = m.top.findNode("RediscoverScreen")
    m.RediscoverDetail          = m.top.findNode("RediscoverDetail")
    m.currentTime               = m.top.findNode("currentTime")
    m.noticeDialog              = m.top.findNode("noticeDialog")
    m.confirmDialog             = m.top.findNode("confirmDialog")
    m.apiTimer                  = m.top.findNode("apiTimer")

    m.fromBrowse                = false
    m.imageLocalCacheByURL      = {}
    m.imageLocalCacheByFS       = {}
    m.imageDisplay              = []
    m.imageTracker              = -1
    m.imageOnScreen             = ""
    m.apiPending                = 0
    m.albumActiveObject         = invalid
    
    m.pauseImageCount.font.size   = 29
    m.pauseImageDetail.font.size  = 29
    m.pauseImageDetail2.font.size = 25
    m.RediscoverDetail.font.size  = 25

    m.PrimaryImage.observeField("loadStatus","onPrimaryLoadedTrigger")
    m.SecondaryImage.observeField("loadStatus","onSecondaryLoadedTrigger")
    m.RotationTimer.observeField("fire","onRotationTigger")
    m.DownloadTimer.observeField("fire","onDownloadTigger")
    m.apiTimer.observeField("fire","onApiTimerTrigger")
    m.top.observeField("content","loadImageList")

    m.showRes       = RegRead("SlideshowRes", "Settings")
    m.showDisplay   = RegRead("SlideshowDisplay", "Settings")
    m.showOrder     = RegRead("SlideshowOrder", "Settings")
    showDelay       = RegRead("SlideshowDelay", "Settings")
    m.settingCEC    = ""
    
    'Check any Temporary settings
    if m.global.SlideshowRes <> "" m.showRes = m.global.SlideshowRes
    if m.global.SlideshowDisplay <> "" m.showDisplay = m.global.SlideshowDisplay
    if m.global.SlideshowOrder <> "" m.showOrder = m.global.SlideshowOrder
    if m.global.SlideshowDelay <> "" showDelay = m.global.SlideshowDelay
    
    print "GooglePhotos Show Res:     "; m.showRes
    print "GooglePhotos Show Delay:   "; showDelay
    print "GooglePhotos Show Order:   "; m.showOrder
    print "GooglePhotos Show Display: "; m.showDisplay
    
    if showDelay<>invalid
        m.RotationTimer.duration = strtoi(showDelay)
        if strtoi(showDelay) > 50
            'We do this to stop the ROKU screensaver if set to 1 minute
            m.DownloadTimer.duration = 50
        else if strtoi(showDelay) > 3
            m.DownloadTimer.duration = strtoi(showDelay)-3
        else
            m.DownloadTimer.duration = 2
        end if
    else
        m.RotationTimer.duration = 5
        m.DownloadTimer.duration = 2
    end if
    
    m.RotationTimer.repeat   = true
    m.DownloadTimer.repeat   = true
    m.URLRefreshTimer.repeat = false
    m.DisplayTimer.repeat    = false

    'Load common variables
    loadCommon()
    
    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
End Sub


Sub loadImageList()
    print "DisplayPhotos.brs [loadImageList]"
    
    if m.top.id = "DisplayScreensaver" then
        'Override settings for screensaver
        m.showRes       = RegRead("SSaverRes", "Settings")
        m.showDisplay   = RegRead("SSaverMethod", "Settings")
        m.showOrder     = RegRead("SSaverOrder", "Settings")
        m.showTime      = RegRead("SSaverTime", "Settings")
        showDelay       = RegRead("SSaverDelay", "Settings")
        m.settingCEC    = RegRead("SSaverCEC", "Settings")
    
        m.RotationTimer.duration = showDelay
        
        print "GooglePhotos Screensaver Res:     "; m.showRes
        print "GooglePhotos Screensaver Delay:   "; showDelay
        print "GooglePhotos Screensaver Order:   "; m.showOrder
        print "GooglePhotos Screensaver Display: "; m.showDisplay
        print "GooglePhotos Screensaver ShowTime: "; m.showTime
        
        'Show watermark on screensaver - Stop bitching, we need some advertisment!
        ds = m.device.GetDisplaySize()

        if ds.w = 1920 then
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_FHD.png"
        else
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_HD.png"
        end if
        m.Watermark.visible = true
        
        m.MoveTimer.observeField("fire","onMoveTrigger")
        m.MoveTimer.control        = "start"
        m.DisplayTimer.duration    = "43200"  '12 hours
        
        
        if m.showTime = "Enabled" then
            m.DateTimer.observeField("fire","onDateTimerTrigger")
            m.DateTimer.control = "start"
            m.currentTime.text  = getLocalTime()
        end if

    else
        m.DisplayTimer.duration    = "43200"  '12 hours
    end if    
    
    m.DisplayTimer.observeField("fire","onDisplayTimer")
    m.DisplayTimer.control     = "start"
    
    'Copy original list since we can't change origin
    originalList = m.top.content
    
    for i = 0 to m.top.content.Count()-1
    
        if m.top.startIndex <> -1 then
            'If coming from browsing, only show in Album Order
            nxt = 0
        else
            if m.showOrder = "Random Order" then
                'Create image display list - RANDOM
                nxt = GetRandom(originalList)
            else if m.showOrder = "Reverse Album Order"
                'Create image display list - REVERSE ALBUM ORDER
                nxt = originalList.Count()-1
            else
                'Create image display list - ALBUM ORDER
                nxt = 0
            end if 
        end if
 
        rxLocal = CreateObject("roRegex", "pkg:/", "i")
        if rxLocal.IsMatch(originalList[nxt].url) then
            originalList[nxt].url = originalList[nxt].url
        else
            originalList[nxt].url = originalList[nxt].url+getResolution(m.showRes)
        end if
        m.imageDisplay.push(originalList[nxt])
        originalList.Delete(nxt)
                 
    end for

    'Enable RediscoverScreen to display photo date on Rediscovery section
    m.rxHistory = CreateObject("roRegex", "History", "i")
    rxNoFound = CreateObject("roRegex", "No images found", "i")
    if m.rxHistory.IsMatch(m.top.predecessor) then
        m.RediscoverScreen.visible = "true"
    else if rxNoFound.IsMatch(m.top.predecessor) then
        m.RediscoverDetail.text    = m.top.predecessor
        m.RediscoverScreen.visible = "true"
    end if
    
    if m.screenActive<>invalid then
        m.screenActive.content = m.imageDisplay
    else
    
        if not rxNoFound.IsMatch(m.top.predecessor) then
            'We have an image list. Start display
            onRotationTigger({})
            onDownloadTigger({})
             
            m.RotationTimer.control = "start"
            m.DownloadTimer.control = "start"
        end if
        
        'Trigger a PAUSE if photo selected
        if m.top.startIndex <> -1 then
            onKeyEvent("OK", true)
        end if       
    end if
End Sub


Sub onRotationTigger(event as object)
    'print "DisplayPhotos.brs [onRotationTigger]";

    if m.top.startIndex <> -1 then m.fromBrowse = true

    if m.showDisplay = "Multi-Scrolling" and m.fromBrowse = false then
    
        'We only allow multi scroll if starting direct, can't come from Browse Images.
        if m.screenActive = invalid then
            m.screenActive             = createObject("roSGNode", "MultiScroll")
            m.screenActive.id          = m.top.id
            m.screenActive.predecessor = m.top.predecessor
            m.screenActive.content     = m.imageDisplay
            m.screenActive.albumobject = m.top.albumobject
            m.screenActive.showres     = m.showRes
            m.screenActive.showorder   = m.showOrder
            m.screenActive.loaded      = "true"
            m.top.appendChild(m.screenActive)
            m.screenActive.setFocus(true)
        end if

        m.Watermark.visible     = false
        m.currentTime.visible   = false
        m.DateTimer.control     = "stop"
        m.RotationTimer.control = "stop"
        m.DownloadTimer.control = "stop"
    else
        sendNextImage()
    end if
End Sub


Sub handleGetAlbumImages(event as object)
    print "DisplayPhotos.brs [handleGetAlbumImages]"
  
    errorMsg = ""
    response = event.getData()
    albumid  = response.post_data[1]
    
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[2])
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetAlbumImages'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)

        if rsp = invalid
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetAlbumImages"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetAlbumImages] " + json.error
        else
            imageList = googleImageListing(rsp)

            imagesMetaData = {}
            for each media in imageList
                if media.IsVideo = 0 then
                    imagesMetaData.[media.GetID] = media.GetURL+getResolution(m.showRes)
                end if
            end for

            'Refresh the URL with new image (Valid for 60 minutes)
            count = 0
            for each storeItem in m.imageDisplay
                if (imagesMetaData.[storeItem.id]<>invalid) then
                    m.imageDisplay[count].url = imagesMetaData.[storeItem.id]
                end if
                count++
            end for

            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumActiveObject[albumid].nextPageToken = pageNext
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + imageList.Count()
                m.albumActiveObject[albumid].apiCount = m.albumActiveObject[albumid].apiCount + 1
                if (m.albumActiveObject[albumid].apiCount < m.maxApiPerPage) and (m.albumActiveObject[albumid].showCountEnd < m.maxImagesPerPage) then
                    if m.albumActiveObject[albumid].GetID.Instr("GP_LIBRARY") >= 0 then
                        doGetLibraryImages(m.albumActiveObject[albumid].GetID, m.albumActiveObject[albumid].GetUserIndex, pageNext)
                    else
                        doGetAlbumImages(m.albumActiveObject[albumid].GetID, m.albumActiveObject[albumid].GetUserIndex, pageNext)
                    end if
                end if                
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
    
End Sub


Sub handleGetSearch(event as object)
    print "DisplayPhotos.brs [handleGetSearch]"

    errorMsg = ""
    response = event.getData()
    albumid  = response.post_data[1]
    keywords = response.post_data[3]
    
    m.apiPending = m.apiPending-1
    if (response.code = 401) or (response.code = 403) then
        'Expired Token
        doRefreshToken(response.post_data, response.post_data[2])
    else if response.code <> 200
        errorMsg = "An Error Occurred in 'handleGetSearch'. Code: "+(response.code).toStr()+" - " +response.error
    else
        rsp=ParseJson(response.content)
        'print rsp
        if rsp=invalid then
            errorMsg = "Unable to parse Google Photos API response. Exit the channel then try again later. Code: "+(response.code).toStr()+" - " +response.error
        else if type(rsp) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: handleGetSearch"
        else if rsp.DoesExist("error")
            errorMsg = "Json error response: [handleGetSearch] " + json.error
        else

            imageList = googleImageListing(rsp)

            for each media in imageList
                tmp             = {}
                tmp.id          = media.GetID
                tmp.url         = media.GetURL + getResolution(m.showRes)
                tmp.timestamp   = media.GetTimestamp
                tmp.description = media.GetDescription
                tmp.filename    = media.GetFilename
        
                if media.IsVideo = 0 then
                    m.albumActiveObject[albumid].imagesMetaData.Push(tmp)
                    'print "IMAGE: "; tmp.url
                end if
            end for
            
            if rsp["nextPageToken"]<>invalid then
                pageNext = rsp["nextPageToken"]
                m.albumActiveObject[albumid].nextPageToken = pageNext
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + imageList.Count()
                m.albumActiveObject[albumid].apiCount = m.albumActiveObject[albumid].apiCount + 1
                if (m.albumActiveObject[albumid].apiCount < m.maxApiPerPage) and (m.albumActiveObject[albumid].showCountEnd < m.maxImagesPerPage) then
                    doGetSearch(albumid, m.albumActiveObject[albumid].GetUserIndex, keywords, pageNext)
                end if
            else
                m.albumActiveObject[albumid].nextPageToken = invalid
                m.albumActiveObject[albumid].showCountEnd = m.albumActiveObject[albumid].showCountEnd + imageList.Count()
            end if
            
            print m.albumActiveObject["SearchResults"]
            print "COUNT: "; m.albumActiveObject[albumid].imagesMetaData.Count()
        end if
    end if

    if errorMsg<>"" then
        'ShowError
        m.noticeDialog.visible = true
        buttons =  [ "OK" ]
        m.noticeDialog.title   = "Error"
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if   

End Sub


Sub onDownloadTigger(event as object)
    'print "DisplayPhotos.brs [onDownloadTigger]"

    tmpDownload = []
    
    'Download Next 5 images - Only when needed
    for i = 1 to 5
        nextID = GetNextImage(m.imageDisplay, m.imageTracker+i)
        
        if m.imageDisplay.Count()-1 >= nextID
        nextURL = m.imageDisplay[nextID].url
        
        if not m.imageLocalCacheByURL.DoesExist(nextURL) then
            tmpDownload.push(m.imageDisplay[nextID])
        end if
        
        end if
    end for
    
    if tmpDownload.Count() > 0 then
        m.cacheImageTask = createObject("roSGNode", "ImageCacher")
        m.cacheImageTask.observeField("localarray", "processDownloads")
        m.cacheImageTask.observeField("filesystem", "contolCache")
        m.cacheImageTask.remotearray = tmpDownload
        m.cacheImageTask.control = "RUN"
    end if
     
    m.keyResetTask = createObject("roSGNode", "KeyReset")
    m.keyResetTask.control = "RUN"
    
End Sub


Sub processDownloads(event as object)
    'print "DisplayPhotos.brs [processDownloads]"
    
    'Take newly downloaded images and add to our localImageStore array for tracking
    response = event.getdata()
    
    for each key in response
        tmpFS = response[key]
        
        m.imageLocalCacheByURL[key] = tmpFS
        m.imageLocalCacheByFS[tmpFS] = key
        
        if (tmpFS = "403") and (m.URLRefreshTimer.control <> "start") then
            onURLRefreshTigger()
            m.URLRefreshTimer.control = "start"
        end if
    end for
    
End Sub


Sub contolCache(event as object)
    'Free channel, no CASH here! -- Not funny? Ok..
    
    keepImages = 20
    
    'Control the filesystem download cache - After 'keepImages' downloads start removing
    cacheArray = event.getdata()
    if type(cacheArray) = "roArray" then
        'print "Local FileSystem Count: "; cacheArray.Count()
        if (cacheArray.Count() > keepImages) then
            for i = keepImages to cacheArray.Count()
                oldImage = cacheArray.pop()
                'print "Delete from FileSystem: "; oldImage
                DeleteFile("tmp:/"+oldImage)
                
                urlLookup = m.imageLocalCacheByFS.Lookup("tmp:/"+oldImage)
                if urlLookup<>invalid
                    'Cleanup cache
                    m.imageLocalCacheByURL.Delete(urlLookup)
                    m.imageLocalCacheByFS.Delete("tmp:/"+oldImage)
                end if
            end for
        end if
    end if
    
End Sub


Sub onPrimaryLoadedTrigger(event as object)

    if event.getdata() = "ready" then
        'Center the MarkUp Box
        markupRectAlbum = m.PrimaryImage.localBoundingRect()
        centerx = (1920 - markupRectAlbum.width) / 2
        centery = (1080 - markupRectAlbum.height) / 2

        m.PrimaryImage.translation = [ centerx, centery ]

        'Controls the image fading
        rxFade = CreateObject("roRegex", "NoFading", "i")        
        if rxFade.IsMatch(m.showDisplay) or rxFade.IsMatch(m.imageOnScreen) then
            m.BlendedPrimaryImage.visible       = true
            m.BlendedSecondaryImage.visible     = false
            m.PrimaryImage.visible              = true
            m.SecondaryImage.visible            = false
            m.BlendedPrimaryImage.opacity       = 1
            m.PrimaryImage.opacity              = 1
            m.FadeForeground.opacity            = 0
        else
            m.BlendedPrimaryImage.visible       = true
            m.PrimaryImage.visible              = true
            m.FadeInPrimaryAnimation.control    = "start"
            
            if m.FadeForeground.opacity = 1 then
                m.FadeOutForeground.control     = "start"
            end if
            
        end if
    end if  
End Sub


Sub onSecondaryLoadedTrigger(event as object)

    if event.getdata() = "ready" then
        'Center the MarkUp Box
        markupRectAlbum = m.SecondaryImage.localBoundingRect()
        centerx = (1920 - markupRectAlbum.width) / 2
        centery = (1080 - markupRectAlbum.height) / 2

        m.SecondaryImage.translation = [ centerx, centery ]

        'Controls the image fading
        rxFade = CreateObject("roRegex", "NoFading", "i")       
        if rxFade.IsMatch(m.showDisplay) or rxFade.IsMatch(m.imageOnScreen) then
            m.BlendedPrimaryImage.visible       = false
            m.BlendedSecondaryImage.visible     = true
            m.PrimaryImage.visible              = false
            m.SecondaryImage.visible            = true
            m.BlendedSecondaryImage.opacity     = 1
            m.SecondaryImage.opacity            = 1
        else
            m.BlendedSecondaryImage.visible     = true
            m.SecondaryImage.visible            = true
            m.FadeInSecondaryAnimation.control  = "start"
        end if
    end if  
End Sub


Sub sendNextImage(direction=invalid)
    print "DisplayPhotos.brs [sendNextImage]"

    'Check HDMI-CEC status for TV's which support this
    'For some reason, Roku TV's do not properly support this method.
    if (m.global.CECStatus = false) and (m.device.GetModelType() <> "TV") then
        if (m.top.id = "DisplayScreensaver") then
            if m.settingCEC = "HDMI-CEC Enabled" then
                m.confirmDialog.observeField("buttonSelected","confirmContinue")
                onCECTrigger()
            end if
        else
            m.confirmDialog.observeField("buttonSelected","confirmContinue")
            onCECTrigger()
        end if
    end if
     
    'Get next image to display.
    if m.top.startIndex <> -1 then
        nextID = m.top.startIndex
        m.top.startIndex = -1
    else
        if direction<>invalid and direction = "previous"
            nextID = GetPreviousImage(m.imageDisplay, m.imageTracker)
        else
            nextID = GetNextImage(m.imageDisplay, m.imageTracker)
        end if
    end if
    
    m.imageTracker = nextID

    url = m.imageDisplay[nextID].url
    
    'Pull image from downloaded cache if avalable
    if m.imageLocalCacheByURL.DoesExist(url) then
        url = m.imageLocalCacheByURL[url]
    end if
    
    print "Next Image: "; url
    
    'Controls the background blur
    rxBlur = CreateObject("roRegex", "YesBlur", "i")
    
    ' Whats going on here:
    '   If a direction button is pressed (previous or next) we disable fading for a better user experiance.
    '   Since the images trigger on "loadstatus" change, we first set the URI to null, then populate.
    '   Due to issue with 2 image albums, we first set the display to null, then populate w/filename
    if direction<>invalid
        if m.imageOnScreen = "PrimaryImage" or m.imageOnScreen = "PrimaryImage_NoFading" then
            m.SecondaryImage.uri = ""
            m.SecondaryImage.uri = url
            m.imageOnScreen      = "SecondaryImage_NoFading"
            if m.showDisplay = invalid or rxBlur.IsMatch(m.showDisplay) then m.BlendedSecondaryImage.uri = url
        else
            m.PrimaryImage.uri   = ""
            m.PrimaryImage.uri   = url
            m.imageOnScreen      = "PrimaryImage_NoFading"
            if m.showDisplay = invalid or rxBlur.IsMatch(m.showDisplay) then m.BlendedPrimaryImage.uri = url
        end if
    else
        if m.imageOnScreen = "PrimaryImage" or m.imageOnScreen = "PrimaryImage_NoFading" then
            if m.imageDisplay.Count() = 2 then m.SecondaryImage.uri = ""
            m.SecondaryImage.uri = url
            m.imageOnScreen      = "SecondaryImage"
            if m.showDisplay     = invalid or rxBlur.IsMatch(m.showDisplay) then m.BlendedSecondaryImage.uri = url
        else
            if m.imageDisplay.Count() = 2 then m.PrimaryImage.uri = ""
            m.PrimaryImage.uri   = url
            m.imageOnScreen      = "PrimaryImage"
            if m.showDisplay = invalid or rxBlur.IsMatch(m.showDisplay) then m.BlendedPrimaryImage.uri = url
        end if
    end if
    
    m.pauseImageCount.text   = itostr(nextID+1)+" of "+itostr(m.imageDisplay.Count())
    m.pauseImageDetail.text  = friendlyDate(m.imageDisplay[nextID].timestamp)

    'RediscoverScreen text change if needed      
    if m.rxHistory.IsMatch(m.top.predecessor) and (m.RediscoverDetail.text <> "Screensaver Paused") then
        m.RediscoverDetail.text  = m.top.predecessor.Replace("Rediscover this", "This")+" - "+ friendlyDateShort(m.imageDisplay[nextID].timestamp)
    end if
    
    if m.imageDisplay[nextID].description <> invalid and m.imageDisplay[nextID].description <> "" then
        m.pauseImageDetail2.text = m.imageDisplay[nextID].description + " - " + m.imageDisplay[nextID].filename
    else
        m.pauseImageDetail2.text = m.imageDisplay[nextID].filename
    end if
    
    'Stop rotating if only 1 image album
    if m.imageDisplay.Count() = 1 then
        m.RotationTimer.control = "stop"
        m.DownloadTimer.control = "stop"
    end if
End Sub


Function GetNextImage(items As Object, tracker As Integer)
    if items.Count()-1 = tracker then
        return 0
    else
        return tracker + 1
    end if
End Function


Function GetPreviousImage(items As Object, tracker As Integer)
    if tracker = 0 then
        return items.Count()-1
    else
        return tracker - 1
    end if
End Function


Sub onMoveTrigger()
    'To prevent screen burn-in
    if m.Watermark.translation[1] = 1010 then
        m.Watermark.translation        = "[1700,10]"
        m.RediscoverScreen.translation = "[0,25]"
        m.currentTime.translation      = "[0,970]"
    else
        m.Watermark.translation        = "[1700,1010]"
        m.RediscoverScreen.translation = "[0,1010]"
        m.currentTime.translation      = "[0,25]"
    end if
End Sub


Sub onDisplayTimer()

    ' ** Why the hell is this here you ask? **
    '  Screensaver will now expire after 4 (now 12) hours due to the API and download limitations Google has set. I don't want all API usage going to people not sitting in front of thier device. Sorry, but that's the way it is right now, plan and simple.
    '  In months to come, I'll review how this channel is doing on the API usage and see if this can be extended or removed.
    '  Last review: July, 2019

    m.RotationTimer.control    = "stop"
    m.DownloadTimer.control    = "stop"
    
    generic1            = {}
    generic1.timestamp  = "284040000"
    generic1.url        = "pkg:/images/black_pixel.png"
    generic1.filename   = "black_pixel.png"
    m.imageTracker      = 0
    m.imageDisplay      = []
    m.imageDisplay.Push(generic1)
    
    sendNextImage()
    if m.top.id = "DisplayScreensaver" then
        m.RediscoverDetail.text    = "Screensaver has expired after 12 hours"
    else
        m.RediscoverDetail.text    = "Slideshow has expired after 12 hours"
    end if
    m.RediscoverScreen.visible = "true"
End Sub


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending

    if m.apiPending = 0 then
        m.apiTimer.control = "stop"
        
        if m.albumActiveObject["SearchResults"].showcountend > 0 then
            'Copy original list since we can't change origin
            originalList = m.albumActiveObject["SearchResults"].imagesMetaData

            m.imageDisplay = []

            for i = 0 to m.albumActiveObject["SearchResults"].imagesMetaData.Count()-1
    
                if m.top.startIndex <> -1 then
                    'If coming from browsing, only show in Album Order
                    nxt = 0
                else
                    if m.showOrder = "Random Order" then
                        'Create image display list - RANDOM
                        nxt = GetRandom(originalList)
                    else if m.showOrder = "Reverse Album Order"
                        'Create image display list - REVERSE ALBUM ORDER
                        nxt = originalList.Count()-1
                    else
                        'Create image display list - ALBUM ORDER
                        nxt = 0
                    end if 
                end if
 
                originalList[nxt].url = originalList[nxt].url
                m.imageDisplay.push(originalList[nxt])
                originalList.Delete(nxt)   
            end for
        end if
    end if
End Sub


Sub onDateTimerTrigger()
    m.currentTime.text = getLocalTime()
End Sub


Sub onCECTrigger()
    if m.top.id = "DisplayScreensaver" then
        m.PrimaryImage.unobserveField("loadStatus")
        m.SecondaryImage.unobserveField("loadStatus")

        m.PrimaryImage.uri          = "pkg:/images/black_pixel.png"
        m.SecondaryImage.uri        = "pkg:/images/black_pixel.png"
        m.BlendedPrimaryImage.uri   = "pkg:/images/black_pixel.png"
        m.BlendedSecondaryImage.uri = "pkg:/images/black_pixel.png"

        m.RediscoverDetail.text     = "Screensaver Paused"
        m.RediscoverScreen.visible  = "true"
    else
        m.confirmDialog.visible = true
        buttons                 =  [ "Continue" ]
        m.confirmDialog.message = "Do you want to continue viewing slideshow?"
        m.confirmDialog.buttons = buttons
        m.confirmDialog.setFocus(true)
    end if
        
    m.RotationTimer.control = "stop"
    m.DownloadTimer.control = "stop"
End Sub


Sub confirmContinue(event as object)
    'Force true to prevent a race condition
    m.global.CECStatus = true
    
    m.PrimaryImage.setFocus(true)
    m.confirmDialog.visible = false
    m.confirmDialog.unobserveField("buttonSelected")
    sendNextImage()
    m.RotationTimer.control = "start"
    m.DownloadTimer.control = "start"
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if key = "right" or key = "fastforward"
            print "RIGHT"
            sendNextImage("next")
            onDownloadTigger({})
            if m.RotationTimer.control = "start"
                m.RotationTimer.control = "stop"
                m.DownloadTimer.control = "stop"
                m.PauseScreen.visible   = "true"
            end if
            return true
        else if key = "left" or key = "rewind"
            print "LEFT"
            sendNextImage("previous")
            if m.RotationTimer.control = "start"
                m.RotationTimer.control = "stop"
                m.DownloadTimer.control = "stop"
                m.PauseScreen.visible   = "true"
            end if
            return true
        else if (key = "play" or key = "OK") and m.RotationTimer.control = "start"
            print "PAUSE"
            m.RotationTimer.control = "stop"
            m.DownloadTimer.control = "stop"
            m.PauseScreen.visible   = "true"
            return true
        else if (key = "play" or key = "OK") and m.RotationTimer.control = "stop"
            print "PLAY"
            sendNextImage()
            m.RotationTimer.control = "start"
            m.DownloadTimer.control = "start"
            m.PauseScreen.visible   = "false"
            return true
        else if ((key = "up") or (key = "down")) and m.PauseScreen.visible = false
            print "OPTIONS - SHOW"
            m.PauseScreen.visible   = "true"
            return true
        else if ((key = "up") or (key = "down")) and m.PauseScreen.visible = true
            print "OPTIONS - HIDE"
            m.PauseScreen.visible   = "false"
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
