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
    m.VideoPlayer    = m.top.findNode("VideoPlayer")
    
    m.regStore = "positions"
    m.regSection = "VideoStatus"
    
    m.itemLabelMain2.font.size = 25
    m.videoPlayingindex = 0
    
    m.showVideoPlayback = RegRead("VideoContinuePlay", "Settings")
        
    m.top.observeField("content","loadImageList")
End Sub


Sub loadImageList()
    print "Browse.brs [loadImageList]"
    m.ImageGrid.content = m.top.content
    m.itemLabelMain1.text = m.top.albumName
    
    if m.top.id = "GP_VIDEO_BROWSE" then
        'Copy original list since we can't change origin
        m.originalList = m.top.content
    end if
    
End Sub


Sub onItemFocused()
    'Item selected
    'print "FOCUSED: "; m.top.metaData[m.ImageGrid.itemFocused]
    
    if (m.top.metaData[m.ImageGrid.itemFocused].timestamp <> invalid) then
        mypath = CreateObject("roPath", m.top.metaData[m.ImageGrid.itemFocused].url)
        fileObj = myPath.Split()   
    
        timestamp = friendlyDate(m.top.metaData[m.ImageGrid.itemFocused].timestamp)
        m.itemLabelMain2.text = m.top.metaData[m.ImageGrid.itemFocused].filename + " - " + timestamp
    end if
End Sub


Sub onItemSelected()
    'Item selected
    'print "SELECTED: "; m.ImageGrid.itemSelected
    
    if m.top.id = "GP_IMAGE_BROWSE" then
        m.screenActive              = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.startIndex   = m.ImageGrid.itemSelected
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
    
        m.videoPlayingindex = m.ImageGrid.itemSelected
        doVideoShow(m.top.metaData[m.ImageGrid.itemSelected])
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
        videoContent.TitleSeason = videoStore.description  + " - " + thumbnailObj.filename
    else
        videoContent.TitleSeason = thumbnailObj.filename
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
                m.videoPlayingindex = GetRandom(m.top.metaData)               
            else if m.showOrder = "Reverse Album Order"
                'Create image display list - REVERSE ALBUM ORDER
                m.videoPlayingindex = m.videoPlayingindex-1
                if (m.top.metaData[m.videoPlayingindex]=invalid) m.videoPlayingindex = m.top.metaData.Count()-1
            else
                'Create image display list - ALBUM ORDER
                m.videoPlayingindex = m.videoPlayingindex+1
                if (m.top.metaData[m.videoPlayingindex]=invalid) m.videoPlayingindex = 0
            end if 
                
            if m.top.metaData[m.videoPlayingindex]<>invalid
                'Continue playing the next video inline
                doVideoShow(m.top.metaData[m.videoPlayingindex])
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
