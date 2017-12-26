
Sub init()    
    m.VideoPlayer = m.top.findNode("VideoPlayer")
    m.top.observeField("videoUrl","doVideoShow")
End Sub


sub doVideoShow()
    print "DisplayVideo.brs [doVideoShow]"
    
    
    videoStream = CreateObject("roAssociativeArray")
    videoStream.url = "https://lh3.googleusercontent.com/5I_xOonP2vwYrCQGLX2TQqXI3S-QbuWhCTvwF4bv83DGk9wZebNsukO7PF7Nv-1AdWwDmvtvCw=m22"
    'videoStream.quality = true
    videoStream.title = "test ABC"
    videoStream.streamformat = "mp4"
    'videoStream.contentid = "my-mp4"
    
    print "STREAM: "; videoStream
    
    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.ContentType = "movie"
    videoContent.url = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
    'm.top.videoUrl
    videoContent.title = "Test Video"
    videoContent.streamformat = "mp4"




    print "VIDEO PLAY: ";videoContent
    m.VideoPlayer.content = videoContent
    m.VideoPlayer.control = "play"
    
     
End Sub


Function GetVideoMetaData()

    res=[480]
    bitrates=[1000]
    qualities=["SD"]
    
        meta = createObject("RoSGNode", "ContentNode") 
        meta.ContentType="movie"
        meta.Title="TEST"
        meta.ShortDescriptionLine1=meta.Title
        meta.SDPosterUrl=""
        meta.HDPosterUrl=""
        meta.StreamFormat="mp4"
        
        stream = {}
        stream.url = m.top.videoUrl
        stream.bitrate = 480
        
        meta.stream = stream
        
        print "URL: "; m.top.videoUrl
        print "CONTENT: "; meta

    return meta
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY: "; key
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function