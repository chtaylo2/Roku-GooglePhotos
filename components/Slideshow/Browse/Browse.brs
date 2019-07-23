'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2019 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.ImageGrid      = m.top.findNode("ImageGrid")
    m.itemLabelMain1 = m.top.findNode("itemLabelMain1")
    m.itemLabelMain2 = m.top.findNode("itemLabelMain2")
    m.settingsIcon   = m.top.findNode("settingsIcon")
    m.mediaPageList  = m.top.findNode("mediaPageList")
    m.mediaPageThumb = m.top.findNode("mediaPageThumb")
    m.mediaPageInfo1 = m.top.findNode("mediaPageInfo1")
    m.mediaPageInfo2 = m.top.findNode("mediaPageInfo2")
    
    m.VideoPlayer    = m.top.findNode("VideoPlayer")
    
    m.regStore = "positions"
    m.regSection = "VideoStatus"
    
    m.itemLabelMain2.font.size = 25
    m.videoPlayingindex = 0
    m.pageSelected = 0
    m.itemsPerPage = 200
    m.itemsStart = 0
    m.itemsEnd = 0
    
    m.showVideoPlayback = RegRead("VideoContinuePlay", "Settings")
        
    m.top.observeField("content","loadPageList")
End Sub


Sub loadPageList()
    print "Browse.brs [loadPageList]"
    
    m.metaData   = m.top.metaData
    m.mediaPages = createObject("RoSGNode","ContentNode")
    totalPages   = m.metaData.Count() / m.itemsPerPage
    currentCount = m.metaData.Count() 
    page_start   = 0
    page_end     = 0
    
    if (ceiling(totalPages) = 1) then
        buildMediaList(0)
    else
        for i = 1 to ceiling(totalPages)
            page_start = 1 + page_end
            if currentCount > m.itemsPerPage then
                page_end=page_end + m.itemsPerPage
                currentCount = currentCount - m.itemsPerPage
            else
                page_end=page_end + currentCount
            end if
            
            page_start_dply = str(page_start)
            page_start_dply = page_start_dply.Replace(" ", "")
            
            page_end_dply   = str(page_end)
            page_end_dply   = page_end_dply.Replace(" ", "")
    
            addItem(m.mediaPages, "GP_MEDIA_PAGES", "", "Media Page " + str(i), "Items: "+page_start_dply+" thru "+page_end_dply) 
        end for
    
        m.mediaPageList.content = m.mediaPages
        displayMediaPages()
    end if
End Sub


Sub displayMediaPages()
    print "Browse.brs [displaymediaPages]"
    
    m.mediaPageList.visible   = true
    hideMarkupGrid()

    m.mediaPageList.setFocus(true)
    
    'Watch for events - Unobserve first to make sure we're not already monitoring
    m.mediaPageList.unobserveField("itemFocused") 
    m.mediaPageList.unobserveField("itemSelected")
    m.mediaPageList.observeField("itemFocused", "onMediaPageFocused") 
    m.mediaPageList.observeField("itemSelected", "onMediaPageSelected")   
End Sub


Sub onMediaPageFocused()
    'Item focused
    focusedItem = m.mediaPageList.content.getChild(m.mediaPageList.itemFocused)
    m.mediaPageInfo2.text = focusedItem.shortdescriptionline2
End Sub


Sub onMediaPageSelected()
    'Item selected
    'print "SELECTED: "; m.mediaPageList.itemSelected

    buildMediaList(m.mediaPageList.itemSelected)
    
End Sub


Sub buildMediaList(index as integer)
    m.pageSelected = index
    selected   = index + 1
    totalPages = m.metaData.Count() / m.itemsPerPage
    page_end   = 0
    page_start = m.pageSelected * m.itemsPerPage + 1
    currentCount = m.metaData.Count() - page_start
    if currentCount > m.itemsPerPage then
        page_end=page_start + m.itemsPerPage - 1
    else
        page_end=page_start + page_end + currentCount
    end if
    
    m.imageThumbList = createObject("RoSGNode","ContentNode")
    for i = page_start-1 to page_end-1
        addItem(m.imageThumbList, "GP_BROWSE", m.metaData[i].url+getResolution("SD"), "", "")
    end for    
    
    m.itemLabelMain1.text = m.top.albumName+" (page "+selected.ToStr()+" of "+ceiling(totalPages).ToStr()+")"
    loadImageList()
End Sub


Sub loadImageList()
    print "Browse.brs [loadImageList]"
    m.ImageGrid.content = m.imageThumbList
    
    if m.top.id = "GP_VIDEO_BROWSE" then
        'Copy original list since we can't change origin
        m.originalList = m.top.content
    end if
    
    showMarkupGrid()
    print "Done"
    
End Sub


Sub onItemFocused()
    'Item selected
    'print "FOCUSED: "; m.metaData[m.ImageGrid.itemFocused]
    
    if (m.metaData[m.ImageGrid.itemFocused].timestamp <> invalid) then
        mypath = CreateObject("roPath", m.metaData[m.ImageGrid.itemFocused].url)
        fileObj = myPath.Split()   
    
        timestamp = friendlyDate(m.metaData[m.ImageGrid.itemFocused].timestamp)
        m.itemLabelMain2.text = m.metaData[m.ImageGrid.itemFocused].filename + " - " + timestamp
    end if
End Sub


Sub onItemSelected()
    'Item selected
    'print "SELECTED: "; m.ImageGrid.itemSelected
    
    if m.top.id = "GP_IMAGE_BROWSE" then
        m.screenActive              = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.startIndex   = m.ImageGrid.itemSelected + (m.pageSelected * m.itemsPerPage)
        m.screenActive.predecessor  = m.top.predecessor
        m.screenActive.albumobject  = m.top.albumobject
        m.screenActive.content      = m.top.metaData
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
    else if m.top.id = "GP_VIDEO_BROWSE" then
    
        m.showOrder = RegRead("SlideshowOrder", "Settings")
        
        'Check any Temporary settings
        if m.global.SlideshowOrder <> "" m.showOrder = m.global.SlideshowOrder
        if m.global.VideoContinuePlay <> "" m.showVideoPlayback = m.global.VideoContinuePlay
    
        m.videoPlayingindex = m.ImageGrid.itemSelected + (m.pageSelected * m.itemsPerPage)
        doVideoShow(m.metaData[m.ImageGrid.itemSelected + (m.pageSelected * m.itemsPerPage)])
    end if
End Sub


Sub doVideoShow(videoStore as object)
    print "Browse.brs [doVideoShow]"
    
    thumbnailPath = CreateObject("roPath", videoStore.url)
    thumbnailObj  = thumbnailPath.Split()
    
    videoFile     = videoStore.url
    videoPath     = CreateObject("roPath", videoFile)
    videoObj      = videoPath.Split()
    
    regStorage = RegRead(m.regStore, m.regSection)

    videoContent              = createObject("RoSGNode", "ContentNode")
    videoContent.ContentType  = "movie"
    videoContent.url          = videoStore.url+"=m18"
    videoContent.streamformat = "mp4"
    videoContent.Title        = friendlyDate(videoStore.timestamp)
    if videoStore.description <> "" then
        videoContent.TitleSeason = videoStore.description  + " - " + videoStore.filename
    else
        videoContent.TitleSeason = videoStore.filename
    end if
    
    m.VideoPlayer.visible = true
    m.VideoPlayer.content = videoContent
    m.VideoPlayer.seek    = setVideoPosition(videoObj.filename)
    m.VideoPlayer.control = "play"
    m.VideoPlayer.setFocus(true)

    m.VideoPlayer.observeField("state", "onVideoStateChange")
End Sub


Sub onVideoStateChange()
    print "Browse.brs - [onVideoStateChange]"
    if (m.VideoPlayer.state = "error") or (m.VideoPlayer.state = "finished") then
    
        writeVideoPosition(0)
        m.VideoPlayer.unobserveField("state")
       
        if m.showVideoPlayback = "Continuous Video Playback" then
            if m.showOrder = "Random Order" then
                'Create image display list - RANDOM
                m.videoPlayingindex = GetRandom(m.metaData)               
            else if m.showOrder = "Reverse Album Order"
                'Create image display list - REVERSE ALBUM ORDER
                m.videoPlayingindex = m.videoPlayingindex-1
                if (m.metaData[m.videoPlayingindex]=invalid) m.videoPlayingindex = m.metaData.Count()-1
            else
                'Create image display list - ALBUM ORDER
                m.videoPlayingindex = m.videoPlayingindex+1
                if (m.metaData[m.videoPlayingindex]=invalid) m.videoPlayingindex = 0
            end if 
                
            if m.metaData[m.videoPlayingindex]<>invalid
                'Continue playing the next video inline
                doVideoShow(m.metaData[m.videoPlayingindex])
            end if
        else
            'Close video screen
            m.VideoPlayer.visible = false
            m.ImageGrid.setFocus(true)
        end if
    end if
End Sub


Function setVideoPosition(filename as string) as integer

    regStorage = RegRead(m.regStore, m.regSection)
    
    if (filename <> "") and (regStorage <> invalid) and (regStorage <> "") then
        parsedString = regStorage.Split("|")
        for each item in parsedString
            keypair = item.Split(":")
            if keypair[0] = filename
                return StrToI(keypair[1])
            end if
        end for
    end if
    
    return 0
    
End Function


Sub writeVideoPosition(position as integer)

    regStorage = RegRead(m.regStore, m.regSection)
    
    if (m.VideoPlayer.state <> "error") and (m.VideoPlayer.streamInfo.streamUrl <> invalid) and (m.VideoPlayer.streamInfo.streamUrl <> "") then
    
        videoFile = m.VideoPlayer.streamInfo.streamUrl
        videoPath = CreateObject("roPath", videoFile)
        videoObj  = videoPath.Split()
        
        if (videoObj.filename <> "") then
            if (regStorage <> invalid) and (regStorage <> "") then
            
                'Only save last 20 video positions
                parsedString = regStorage.Split("|")
                i = 1
                saveList = ""
                for each item in parsedString
                    keypair = item.Split(":")
                    if keypair[0] <> videoObj.filename
                        saveList = saveList + "|" + item
                    end if
                    i = i + 1
                    if i = 20 EXIT FOR
                end for
                RegWrite(m.regStore, videoObj.filename + ":" + itostr(position) + saveList, m.regSection)
            else
                RegWrite(m.regStore, videoObj.filename + ":" + itostr(position), m.regSection)
            end if
        end if
    end if
End Sub


Sub hideMarkupGrid()
    m.ImageGrid.visible       = false
    m.itemLabelMain1.visible  = false
    m.itemLabelMain2.visible  = false
    m.settingsIcon.visible    = false
End Sub


Sub showMarkupGrid()
    m.mediaPageList.visible   = false
    m.ImageGrid.visible       = true
    m.itemLabelMain1.visible  = true
    m.itemLabelMain2.visible  = true
    m.settingsIcon.visible    = true
    
    m.ImageGrid.setFocus(true)
End Sub


Sub showTempSetting()
    hideMarkupGrid()
    m.screenActive              = createObject("roSGNode", "Settings")
    m.screenActive.contentFile  = "settingsTemporaryContent"
    m.screenActive.id           = "settings"
    m.screenActive.loaded       = true
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End Sub


Sub addItem(store as object, id as string, hdgridposterurl as string, shortdescriptionline1 as string, shortdescriptionline2 as string)
    item = store.createChild("ContentNode")
    item.id = id
    item.title = shortdescriptionline1
    item.hdgridposterurl = hdgridposterurl
    item.shortdescriptionline1 = shortdescriptionline1
    item.shortdescriptionline2 = shortdescriptionline2
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                showMarkupGrid()
                return true
            else if (m.VideoPlayer.visible = true)
                m.VideoPlayer.control = "stop"
                m.VideoPlayer.visible = false
                m.ImageGrid.setFocus(true)
                m.VideoPlayer.unobserveField("state")   
                writeVideoPosition(m.VideoPlayer.position)
                return true
            else if (m.mediaPageList.visible = false) and (ceiling(m.metaData.Count() / m.itemsPerPage) > 1)
                displayMediaPages()
                return true
            end if
        else if (key = "options") and (m.screenActive = invalid)
            showTempSetting()
            return true
        else if ((key = "options") or (key = "left")) and (m.screenActive <> invalid) and (m.screenActive.id = "settings")
            m.top.removeChild(m.screenActive)
            showMarkupGrid()
            m.screenActive          = invalid
            m.settingsIcon.visible  = true
            return true
        end if 
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
