
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
	
	 m.imageLocalStore = {}
	 m.imageDisplay    = []
	 m.imageTracker    = -1
	
	 m.PrimaryImage.observeField("loadStatus","onLoadStatusTrigger")
	 m.FadeOUTAnimation.observeField("state","onFadeOutTrigger")
	 m.RotationTimer.observeField("fire","onRotationTigger")
	 m.DownloadTimer.observeField("fire","onDownloadTigger")
	 m.top.observeField("content","loadImageList")

     m.showDisplay = RegRead("SlideshowDisplay", "Settings")
	 m.showOrder = RegRead("SlideshowOrder", "Settings")

     showDelay = RegRead("SlideshowDelay", "Settings")
	 print "GooglePhotos Show Delay: "; showDelay
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
         if m.showOrder = "random" then
		     'Create image display list - RANDOM
		     nxt = GetRandom(originalList)
         else if m.showOrder = "newest"
		     'Create image display list - NEW FIRST
		     nxt = 0
         else
		     'Create image display list - OLD FIRST
		     nxt = originalList.Count()-1
         end if
		 
		 'Track startPhoto if valid
		 if m.top.startPhoto = originalList[nxt].url then
			 m.imageDisplay.unshift(originalList[nxt])
         else
		     m.imageDisplay.push(originalList[nxt])
		 end if
		 
         originalList.Delete(nxt)
				 
	 end for
	
	 'We have an image list. Start display
	 onRotationTigger({})
	 onDownloadTigger({})
	 
     m.RotationTimer.control = "start"
     m.DownloadTimer.control = "start"
	 
     'Trigger a PAUSE if photo selected
     if m.top.startPhoto <> "" then
	     onKeyEvent("OK", true)
	 end if
	 
End Sub


Sub onRotationTigger(event as object)
     print "DisplayPhotos.brs [onRotationTigger]";
	
    if m.showDisplay = "NoFading_YesBlur" or m.showDisplay = "NoFading_NoBlur" then
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
		
		if not m.imageLocalStore.DoesExist(nextURL) then
            tmpDownload.push(m.imageDisplay[nextID])
		    print "DOWNLOAD NEXT: "; nextID; " URL: "; m.imageDisplay[nextID].url
        end if
		
		end if
	end for	
	
    if tmpDownload.Count() > 0 then
        m.readContentTask = createObject("roSGNode", "ImageGrabber")
        m.readContentTask.observeField("localarray", "processDownloads")
        m.readContentTask.remotearray = tmpDownload
        m.readContentTask.control = "RUN"
	end if
End Sub


Sub processDownloads(event as object)
    print "DisplayPhotos.brs [processDownloads]"
	
	'Take newly downloaded images and add to our localImageStore array for tracking
	response = event.getdata()
	
	for each key in response
        m.imageLocalStore[key] = response[key]
	end for
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
    nextID = GetNextImage(m.imageDisplay, m.imageTracker)
    m.imageTracker = nextID
	
    url = m.imageDisplay[nextID].url
	
    'Pull image from downloaded cache if avalable
    if m.imageLocalStore.DoesExist(url) then
        url = m.imageLocalStore[url]
    end if
	
    print "NEXT IMAGE: "; nextID; " - "; url
	
    m.PrimaryImage.uri = url
	
	'Controls the background blur
	if m.showDisplay = "YesFading_YesBlur" or m.showDisplay = "NoFading_YesBlur" then
	    m.BlendedImage.uri = url
	end if
	
	m.pauseImageCount.text  = itostr(nextID+1)+" of "+itostr(m.imageDisplay.Count())
    m.pauseImageDetail.text = friendlyDate(strtoi(m.imageDisplay[nextID].timestamp))
	
	''''' THIS IS CRASHING THE ROKU...
    'Delete cached images after display completed
    'r = CreateObject("roRegex", "tmp:/", "i")
    'if r.IsMatch(old) then
	'    print "DELETE: "; old
    '    DeleteFile(old)
    'end if
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
        else if (key = "options") and m.PauseScreen.visible = false
			print "OPTIONS - SHOW"
			m.PauseScreen.visible   = "true"
            return true
        else if (key = "options") and m.PauseScreen.visible = true
			print "OPTIONS - HIDE"
			m.PauseScreen.visible   = "false"
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function