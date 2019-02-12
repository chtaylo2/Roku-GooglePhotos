'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub Main()
    'Start main screen
    showGooglePhotosScreen()
End Sub


Sub showGooglePhotosScreen()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
    
    scene    = screen.CreateScene("GooglePhotosMainScene")
    m.global = screen.getGlobalNode()
 
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: "", VideoContinuePlay: ""} )
    m.global.addFields( {selectedUser: -1, tmpDEBUG: 0} )

    screen.setMessagePort(port)    
    screen.show()

    while(true)
        msg     = wait(0, port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
End Sub
