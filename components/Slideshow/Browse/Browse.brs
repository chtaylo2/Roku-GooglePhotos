'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.ImageGrid      = m.top.findNode("ImageGrid")
    m.itemLabelMain1 = m.top.findNode("itemLabelMain1")
    m.VideoPlayer    = m.top.findNode("VideoPlayer")
    
    m.top.observeField("content","loadImageList")
End Sub


Sub loadImageList()
    print "Browse.brs [loadImageList]"
    m.ImageGrid.content = m.top.content
    m.itemLabelMain1.text = m.top.albumName
End Sub


Sub onItemSelected()
    'Item selected
    print "SELECTED: "; m.ImageGrid.itemSelected
    print "ID: "; m.top.id
    
    print "HERE: ";m.top.metaData[m.ImageGrid.itemSelected]
    
    if m.top.id = "GP_IMAGE_BROWSE" then
        m.screenActive = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.startIndex = m.ImageGrid.itemSelected
        m.screenActive.content = m.top.metaData
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
    else if m.top.id = "GP_VIDEO_BROWSE" then        
        doVideoShow(m.top.metaData[m.ImageGrid.itemSelected])
    end if
End Sub


Sub doVideoShow(videoObj as object)
    print "Browse.brs [doVideoShow]"
    
    mypath = CreateObject("roPath", videoObj.thumbnail)
    fileObj = myPath.Split()
    print "NAME: "; fileObj.filename
    
    
    videoContent              = createObject("RoSGNode", "ContentNode")
    videoContent.ContentType  = "movie"
    videoContent.url          = videoObj.url
    videoContent.streamformat = "mp4"
    videoContent.TitleSeason  = fileobj.filename
    videoContent.Title        = friendlyDate(StrToI(videoObj.timestamp))

    print "VIDEO PLAY: ";videoContent
    m.VideoPlayer.visible = true
    m.VideoPlayer.content = videoContent
    m.VideoPlayer.control = "play"
    m.VideoPlayer.setFocus(true)
    
    m.VideoPlayer.observeField("state", "onVideoStateChange")
End Sub


Sub onVideoStateChange()
    print "Browse.brs - [onVideoStateChange]"
    if (m.VideoPlayer.state = "error") or (m.VideoPlayer.state = "finished") then
        'Close video screen!
        m.VideoPlayer.visible = false
        m.ImageGrid.setFocus(true)
    end if
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                m.ImageGrid.setFocus(true)
                return true
            else if (m.VideoPlayer.visible = true)
                m.VideoPlayer.control = "stop"
                m.VideoPlayer.visible = false
                m.ImageGrid.setFocus(true)
                return true
            end if
        end if 
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function