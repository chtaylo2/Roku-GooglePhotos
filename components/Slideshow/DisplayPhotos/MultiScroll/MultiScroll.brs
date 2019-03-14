'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("albumImages","handleGetAlbumImages")
    m.UriHandler.observeField("searchResult","handleGetSearch")
    m.UriHandler.observeField("refreshToken","handleRefreshToken")
    
    m.scroll_node_1     = m.top.findNode("scroll_node_1")
    m.scroll_node_2     = m.top.findNode("scroll_node_2")
    m.scroll_node_3     = m.top.findNode("scroll_node_3")
    m.scroll_node_4     = m.top.findNode("scroll_node_4")
    m.scroll_node_5     = m.top.findNode("scroll_node_5")
    m.scroll_node_6     = m.top.findNode("scroll_node_6")
    m.scroll_node_7     = m.top.findNode("scroll_node_7")
    m.scroll_node_8     = m.top.findNode("scroll_node_8")

    m.WaveTimer         = m.top.findNode("waveTimer")
    m.RefreshTimer      = m.top.findNode("refreshTimer")
    m.Watermark         = m.top.findNode("Watermark")
    m.MoveTimer         = m.top.findNode("moveWatermark")
    m.RediscoverScreen  = m.top.findNode("RediscoverScreen")
    m.RediscoverDetail  = m.top.findNode("RediscoverDetail")
    m.DownloadTimer     = m.top.findNode("DownloadTimer")
    m.URLRefreshTimer   = m.top.findNode("URLRefreshTimer")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    m.apiTimer          = m.top.findNode("apiTimer")
    m.DisplayTimer      = m.top.findNode("DisplayTimer")
    
    m.WaveTimer.observeField("fire","onWaveTigger")
    m.RefreshTimer.observeField("fire","onRefreshTigger")
    m.top.observeField("loaded","loadImageList")
    m.apiTimer.observeField("fire","onApiTimerTrigger")
    m.scroll_node_1.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_2.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_3.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_4.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_5.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_6.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_7.observeField("loadStatus","onLoadMonitor")
    m.scroll_node_8.observeField("loadStatus","onLoadMonitor")

    m.DownloadTimer.repeat   = true
    m.URLRefreshTimer.repeat = false
    m.DisplayTimer.repeat    = false
    
    m.imageLocalCacheByURL   = {}
    m.imageLocalCacheByFS    = {}
    m.WaveStep               = 0
    m.imageTracker           = -1
    m.apiPending             = 0
    m.albumActiveObject      = invalid
    
    m.RediscoverDetail.font.size  = 25
    endPoint=-600
    
    'Node 1 adjustments
        tmpStart = []
        tmpStart.Push(50)
        tmpStart.Push(1095)
        m.scroll_node_1.loadWidth           = 291
        m.scroll_node_1.loadHeight          = 291
        m.scroll_node_1.imageTranslation    = tmpStart
        m.scroll_node_1.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
            
    'Node 2 adjustments
        tmpStart = []
        tmpStart.Push(450)
        tmpStart.Push(1095)
        m.scroll_node_2.loadWidth           = 375
        m.scroll_node_2.loadHeight          = 375
        m.scroll_node_2.imageTranslation    = tmpStart
        m.scroll_node_2.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 3 adjustments
        tmpStart = []
        tmpStart.Push(1314)
        tmpStart.Push(1095)
        m.scroll_node_3.loadWidth           = 291
        m.scroll_node_3.loadHeight          = 291
        m.scroll_node_3.imageTranslation    = tmpStart
        m.scroll_node_3.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
                
    'Node 4 adjustments
        tmpStart = []
        tmpStart.Push(1050)
        tmpStart.Push(1095)
        m.scroll_node_4.loadWidth           = 324
        m.scroll_node_4.loadHeight          = 324
        m.scroll_node_4.imageTranslation    = tmpStart
        m.scroll_node_4.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 5 adjustments
        tmpStart = []
        tmpStart.Push(675)
        tmpStart.Push(1095)
        m.scroll_node_5.loadWidth           = 450
        m.scroll_node_5.loadHeight          = 450
        m.scroll_node_5.imageTranslation    = tmpStart
        m.scroll_node_5.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 6 adjustments
        tmpStart = []
        tmpStart.Push(1500)
        tmpStart.Push(1095)
        m.scroll_node_6.loadWidth           = 375
        m.scroll_node_6.loadHeight          = 375
        m.scroll_node_6.imageTranslation    = tmpStart
        m.scroll_node_6.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 7 adjustments
        tmpStart = []
        tmpStart.Push(900)
        tmpStart.Push(1095)
        m.scroll_node_7.loadWidth           = 564
        m.scroll_node_7.loadHeight          = 564
        m.scroll_node_7.imageTranslation    = tmpStart
        m.scroll_node_7.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 8 adjustments
        tmpStart = []
        tmpStart.Push(150)
        tmpStart.Push(1095)
        m.scroll_node_8.loadWidth           = 564
        m.scroll_node_8.loadHeight          = 564
        m.scroll_node_8.imageTranslation    = tmpStart
        m.scroll_node_8.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
    
    'Load common variables
    loadCommon()
    
    'Load privlanged variables
    loadPrivlanged()

    'Load registration variables
    loadReg()
    
End Sub


Sub loadImageList()

    m.imageDisplay = m.top.content

    m.scroll_node_1.imageUri = GetNextImage()
    m.scroll_node_5.imageUri = GetNextImage()
    m.scroll_node_6.imageUri = GetNextImage()
    m.scroll_node_4.imageUri = GetNextImage()
    m.scroll_node_8.imageUri = GetNextImage()
    m.scroll_node_2.imageUri = GetNextImage()
    m.scroll_node_3.imageUri = GetNextImage()
    m.scroll_node_7.imageUri = GetNextImage()
    
    if m.top.id = "DisplayScreensaver" then
        'Show watermark on screensaver - Stop bitching, we need some advertisment!
        device  = createObject("roDeviceInfo")
        ds = device.GetDisplaySize()

        if ds.w = 1920 then
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_FHD.png"
        else
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_HD.png"
        end if
        m.Watermark.visible = true
        
        m.MoveTimer.observeField("fire","onMoveTrigger")
        m.MoveTimer.control        = "start"
        m.DisplayTimer.duration    = "18000"  '5 hours
    else
        m.DisplayTimer.duration    = "43200"  '12 hours
    end if    
    
    m.DisplayTimer.observeField("fire","onDisplayTimer")
    m.DisplayTimer.control     = "start"
    
    m.scroll_node_1.control = "start"
    m.scroll_node_5.control = "start"
    m.WaveTimer.control     = "start"
    m.RefreshTimer.control  = "start"
    m.DownloadTimer.control = "start"
    
    'Enable RediscoverScreen to display photo date on Rediscovery section
    m.rxHistory = CreateObject("roRegex", "History", "i") 
    if m.rxHistory.IsMatch(m.top.predecessor) then
        m.RediscoverScreen.visible = "true"
        m.RediscoverDetail.text    = m.top.predecessor.Replace("Rediscover this", "This")
    end if
End Sub


Sub onMoveTrigger()
    'To prevent screen burn-in
    if m.Watermark.translation[1] = 1010 then
         m.Watermark.translation        = "[1700,10]"
         m.RediscoverScreen.translation = "[0,25]"
    else
        m.Watermark.translation        = "[1700,1010]"
        m.RediscoverScreen.translation = "[0,1010]"
    end if
End Sub


Sub onWaveTigger()
    if m.WaveStep = 0 then
        m.scroll_node_6.control = "start"
    else if m.WaveStep = 1
        m.scroll_node_4.control = "start"
        m.scroll_node_8.control = "start"'
    else if m.WaveStep = 2
        m.scroll_node_2.control = "start"
        m.scroll_node_3.control = "start"
        m.scroll_node_7.control = "start"
        m.WaveTimer.control     = "stop"
    end if

    m.WaveStep = m.WaveStep + 1

End Sub


Sub onRefreshTigger()

    'FHD Support
    endPoint=-600
    
    if (m.scroll_node_1.imageTranslation[1] = endPoint) then
        m.scroll_node_1.imageUri = GetNextImage()
        m.scroll_node_1.control  = "start"
    end if
 
    if (m.scroll_node_2.imageTranslation[1] = endPoint) then
        m.scroll_node_2.imageUri = GetNextImage()
        m.scroll_node_2.control  = "start"
    end if

    if (m.scroll_node_3.imageTranslation[1] = endPoint) then
        m.scroll_node_3.imageUri = GetNextImage()
        m.scroll_node_3.control  = "start"
    end if
        
    if (m.scroll_node_4.imageTranslation[1] = endPoint) then
        m.scroll_node_4.imageUri = GetNextImage()
        m.scroll_node_4.control  = "start"
    end if

    if (m.scroll_node_5.imageTranslation[1] = endPoint) then
        m.scroll_node_5.imageUri = GetNextImage()
        m.scroll_node_5.control  = "start"
    end if

    if (m.scroll_node_6.imageTranslation[1] = endPoint) then
        m.scroll_node_6.imageUri = GetNextImage()
        m.scroll_node_6.control  = "start"
    end if
            
    if (m.scroll_node_7.imageTranslation[1] = endPoint) then
        m.scroll_node_7.imageUri = GetNextImage()
        m.scroll_node_7.control  = "start"
    end if
            
    if (m.scroll_node_8.imageTranslation[1] = endPoint) then
        m.scroll_node_8.imageUri = GetNextImage()
        m.scroll_node_8.control  = "start"
    end if       
    
    m.keyResetTask = createObject("roSGNode", "KeyReset")
    m.keyResetTask.control = "RUN"
    
End Sub


Sub handleGetAlbumImages(event as object)
    print "MultiScroll.brs [handleGetAlbumImages]"
  
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
                    imagesMetaData.[media.GetID] = media.GetURL+getResolution(m.top.showres)
                end if
            end for

            'Refresh the URL with new image (Valid for 60 minutes)
            count = 0
            for each storeItem in m.imageDisplay
                if (imagesMetaData.[storeItem.id]<>invalid) then
                    'print "DEBUG: OLD: "; m.imageDisplay[count].url
                    'print "DEBUG: NEW: "; imagesMetaData.[storeItem.id]
                
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

    print m.albumActiveObject["SearchResults"]
    print "COUNT: "; m.albumActiveObject[albumid].imagesMetaData.Count()
    
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
                tmp.url         = media.GetURL + getResolution(m.top.showres)
                tmp.timestamp   = media.GetTimestamp
                tmp.description = media.GetDescription
                tmp.filename    = media.GetFilename
        
                if media.IsVideo = 0 then
                    m.albumActiveObject[albumid].imagesMetaData.Push(tmp)
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


Function GetNextImage()

    print "NEXT: "; m.imageTracker

    if m.imageDisplay.Count()-1 = m.imageTracker then
        m.imageTracker = 0
        url = m.imageDisplay[m.imageTracker].url
    else
        m.imageTracker = m.imageTracker + 1
        url = m.imageDisplay[m.imageTracker].url
    end if
    
    return url
    
End Function


Sub onLoadMonitor(event as object)
    print "Status: "; event.getdata()
    if event.getdata() = "failed" then
        print "ERROR TRIGGERED"
        if m.URLRefreshTimer.control <> "start" then
            onURLRefreshTigger()
            m.URLRefreshTimer.control = "start"
        else
            print "NO TRIGGER"
        end if
    end if

End Sub


Sub onDisplayTimer()

    ' ** Why the hell is this here you ask? **
    '  Screensaver will now expire after 5 hours due to the API and download limitations Google has set. I don't want all API usage going to people not sitting in front of thier device. Sorry, but that's the way it is right now, plan and simple.
    '  In months to come, I'll review how this channel is doing on the API usage and see if this can be extended or removed.
    '  Last review: March, 2019

    m.RefreshTimer.control     = "stop"
    m.DownloadTimer.control    = "stop"
    m.RediscoverScreen.visible = "false"
End Sub


Sub onApiTimerTrigger()
    print "API CALLS LEFT: "; m.apiPending

    if m.apiPending = 0 then
        m.apiTimer.control = "stop"
        
        if m.albumActiveObject["SearchResults"].showcountend > 0 then
            m.imageDisplay = m.albumActiveObject["SearchResults"].imagesMetaData          
        end if
    end if
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key <> "back"
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
