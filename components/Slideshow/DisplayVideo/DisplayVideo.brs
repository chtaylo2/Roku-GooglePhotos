
Sub init()    
    m.VideoPlayer = m.top.findNode("VideoPlayer")
    m.top.observeField("videoUrl","doVideoShow")
End Sub


Sub doVideoShow()
    print "DisplayVideo.brs [doVideoShow]"
    
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.ContentType = "movie"
    videoContent.url = m.top.videoUrl
    videoContent.streamformat = "mp4"

    print "VIDEO PLAY: ";videoContent
    m.VideoPlayer.content = videoContent
    m.VideoPlayer.control = "play"
    
    m.VideoPlayer.observeField("state", "onVideoStateChange")
    
End Sub


Sub onVideoStateChange()
    print "DetailsScreen.brs - [onVideoStateChange]"
    if (m.VideoPlayer.state = "error") or (m.VideoPlayer.state = "finished") then
        'Close video screen!

    end if
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function