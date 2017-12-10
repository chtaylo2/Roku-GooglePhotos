
Sub init()
				
	m.PrimaryImage      = m.top.findNode("PrimaryImage")
	m.BlendedImage      = m.top.findNode("BlendedImage")
	m.FadeINAnimation   = m.top.findNode("FadeINAnimation")
	m.FadeOUTAnimation  = m.top.findNode("FadeOUTAnimation")
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
	    m.RotationTimer.duration = 3
		m.DownloadTimer.duration = 2
    end if
	
    m.RotationTimer.repeat = true
    m.DownloadTimer.repeat = true

End Sub


sub loadImageList()
    print "Slideshow.brs [loadImageList]"
	
    'Copy original list since we can't change origin
    originalList = m.top.content
	
    'Create image display list - RANDOM
    for i = 0 to m.top.content.Count()-1 
        rnd = GetRandom(originalList)
        m.imageDisplay.push(originalList[rnd])
		originalList.Delete(rnd)
	end for
	
	'We have an image list. Start display
	onRotationTigger({})
	onDownloadTigger({})
	
    m.RotationTimer.control = "start"
    m.DownloadTimer.control = "start"
End Sub


Sub onRotationTigger(event as object)
    print "Slideshow.brs [onRotationTigger]"
	
	m.FadeOUTAnimation.control = "start"
End Sub


Sub onDownloadTigger(event as object)
    print "Slideshow.brs [onDownloadTigger]"
	
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
    print "Slideshow.brs [processDownloads]"
	
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
    print "Slideshow.brs [onFadeOutTrigger]"
	
    if event.getdata() = "stopped" then
	    'FadeOUT has completed. Trigger next image load
        sendNextImage()		
	end if
End Sub


Sub sendNextImage()
    print "Slideshow.brs [sendNextImage]"
		
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
	m.BlendedImage.uri = url
	
	
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