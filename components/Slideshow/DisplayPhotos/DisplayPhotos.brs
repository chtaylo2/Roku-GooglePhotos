
Sub init()    
    m.PrimaryImage      = m.top.findNode("PrimaryImage")
    m.BlendedImage      = m.top.findNode("BlendedImage")
    m.FadeForeground    = m.top.findNode("FadeForeground")
    m.FadeINAnimation   = m.top.findNode("FadeINAnimation")
    m.FadeOUTAnimation  = m.top.findNode("FadeOUTAnimation")
    m.PauseScreen       = m.top.findNode("PauseScreen")
    m.pauseImageCount   = m.top.findNode("pauseImageCount")
    m.pauseImageDetail  = m.top.findNode("pauseImageDetail")
    m.RotationTimer     = m.top.findNode("RotationTimer")
    m.DownloadTimer     = m.top.findNode("DownloadTimer")

    m.port = CreateObject("roMessagePort")
    device = CreateObject("roDeviceInfo")
    ds     = device.GetDisplaySize()
    
    m.PrimaryImage.loadWidth  = ds.w
    m.PrimaryImage.loadHeight = ds.h
    
    m.imageLocalCacheByURL  = {}
    m.imageLocalCacheByFS   = {}
    m.imageDisplay          = []
    m.imageTracker          = -1
    
    m.PrimaryImage.observeField("loadStatus","onLoadStatusTrigger")
    m.FadeOUTAnimation.observeField("state","onFadeOutTrigger")
    m.RotationTimer.observeField("fire","onRotationTigger")
    m.DownloadTimer.observeField("fire","onDownloadTigger")
    m.top.observeField("content","loadImageList")

    m.showDisplay   = RegRead("SlideshowDisplay", "Settings")
    m.showOrder     = RegRead("SlideshowOrder", "Settings")
    showDelay       = RegRead("SlideshowDelay", "Settings")
    
    print "GooglePhotos Show Delay: "; showDelay
    print "GooglePhotos Show Order: "; m.showOrder
    print "GooglePhotos Show Display: "; m.showDisplay
    
    if showDelay<>invalid
        m.RotationTimer.duration = strtoi(showDelay)
        if strtoi(showDelay) > 3
            m.DownloadTimer.duration = strtoi(showDelay)-3
        else
            m.DownloadTimer.duration = 2
        end if
    else
        m.RotationTimer.duration = 5
        m.DownloadTimer.duration = 2
    end if
    
    m.RotationTimer.repeat = true
    m.DownloadTimer.repeat = true
End Sub


sub loadImageList()
    print "DisplayPhotos.brs [loadImageList]"
    
    'Copy original list since we can't change origin
    originalList = m.top.content
    
    for i = 0 to m.top.content.Count()-1
    
        if m.top.startIndex <> -1 then
            'If coming from browsing, only show in Newest-Oldest order
            nxt = 0
        else
            if m.showOrder = "random" then
                'Create image display list - RANDOM
                nxt = GetRandom(originalList)
            else if m.showOrder = "oldest"
                'Create image display list - OLD FIRST
                nxt = originalList.Count()-1
            else
                'Create image display list - NEW FIRST
                nxt = 0
            end if 
        end if
        
        m.imageDisplay.push(originalList[nxt])
        originalList.Delete(nxt)
                 
    end for
    
    'We have an image list. Start display
    onRotationTigger({})
    onDownloadTigger({})
     
    m.RotationTimer.control = "start"
    m.DownloadTimer.control = "start"
     
    'Trigger a PAUSE if photo selected
    if m.top.startIndex <> -1 then
        onKeyEvent("OK", true)
    end if
     
End Sub


Sub onRotationTigger(event as object)
    print "DisplayPhotos.brs [onRotationTigger]";
    
    rxFade = CreateObject("roRegex", "NoFading", "i")
    if rxFade.IsMatch(m.showDisplay) then
        m.FadeForeground.visible = false
        sendNextImage()
    else
        m.FadeOUTAnimation.control = "start"
    end if
End Sub


Sub onDownloadTigger(event as object)
    print "DisplayPhotos.brs [onDownloadTigger]"
    
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
        m.cacheImageTask = createObject("roSGNode", "ImageGrabber")
        m.cacheImageTask.observeField("localarray", "processDownloads")
        m.cacheImageTask.observeField("filesystem", "contolCache")
        m.cacheImageTask.remotearray = tmpDownload
        m.cacheImageTask.control = "RUN"
    end if
End Sub


Sub processDownloads(event as object)
    print "DisplayPhotos.brs [processDownloads]"
    
    'Take newly downloaded images and add to our localImageStore array for tracking
    response = event.getdata()
    
    for each key in response
        tmpFS = response[key]
        
        m.imageLocalCacheByURL[key] = tmpFS
        m.imageLocalCacheByFS[tmpFS] = key
    end for
End Sub


Sub contolCache(event as object)
    'Free channel, no CASH here! -- Not funny? Ok..
    
    keepImages = 20
    
    'Control the filesystem download cache - After 'keepImages' downloads start removing
    cacheArray = event.getdata()
    if type(cacheArray) = "roArray" then
        print "Local FileSystem Count: "; cacheArray.Count()
        if (cacheArray.Count() > keepImages) then
            for i = keepImages to cacheArray.Count()
                oldImage = cacheArray.pop()
                print "Delete from FileSystem: "; oldImage
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


Sub onLoadStatusTrigger(event as object)
    if event.getdata() = "ready" then
        'Center the MarkUp Box
        markupRectAlbum = m.PrimaryImage.localBoundingRect()
        centerx = (1280 - markupRectAlbum.width) / 2
        centery = (720 - markupRectAlbum.height) / 2

        m.PrimaryImage.translation = [ centerx, centery ]
        m.FadeINAnimation.control = "start"
    end if  
End Sub


Sub onFadeOutTrigger(event as object)
    print "DisplayPhotos.brs [onFadeOutTrigger]"
    
    if event.getdata() = "stopped" then
        'FadeOUT has completed. Trigger next image load
        sendNextImage()     
    end if
End Sub


Sub sendNextImage()
    print "DisplayPhotos.brs [sendNextImage]"
        
    'Get next image to display.
    if m.top.startIndex <> -1 then
        nextID = m.top.startIndex
        m.top.startIndex = -1
    else
        nextID = GetNextImage(m.imageDisplay, m.imageTracker)
    end if
    
    m.imageTracker = nextID
    
    url = m.imageDisplay[nextID].url
    
    'Pull image from downloaded cache if avalable
    if m.imageLocalCacheByURL.DoesExist(url) then
        url = m.imageLocalCacheByURL[url]
    end if
    
    print "NEXT IMAGE: "; nextID; " - "; url
    
    m.PrimaryImage.uri = url
    
    'Controls the background blur
    rxBlur = CreateObject("roRegex", "YesBlur", "i")
    if m.showDisplay = invalid or rxBlur.IsMatch(m.showDisplay) then
        m.BlendedImage.uri = url
    end if
    
    m.pauseImageCount.text  = itostr(nextID+1)+" of "+itostr(m.imageDisplay.Count())
    m.pauseImageDetail.text = friendlyDate(strtoi(m.imageDisplay[nextID].timestamp))
End Sub


Function GetRandom(items As Object)
    return Rnd(items.Count())-1
End Function


Function GetNextImage(items As Object, tracker As Integer)
    if items.Count()-1 = tracker then
        return 0
    else
        return tracker + 1
    end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
        if key = "right" or key = "fastforward"
            print "RIGHT"
            onRotationTigger({})
            onDownloadTigger({})
            m.RotationTimer.control = "stop"
            m.DownloadTimer.control = "stop"
            m.PauseScreen.visible   = "true"
            return true
        else if key = "left" or key = "rewind"
            print "LEFT"
            return true
        else if (key = "play" or key = "OK") and m.RotationTimer.control = "start"
            print "PAUSE"
            m.RotationTimer.control = "stop"
            m.DownloadTimer.control = "stop"
            m.PauseScreen.visible   = "true"
            return true
        else if (key = "play" or key = "OK") and m.RotationTimer.control = "stop"
            print "PLAY"
            onRotationTigger({})
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