
Sub Main()
    'Start main screen
    showGooglePhotosScreen()
    'showGooglePhotosScreensaver()
    'showGooglePhotosScreensaverSettings()
End Sub


Sub showGooglePhotosScreen()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
    
    scene    = screen.CreateScene("GooglePhotosMainScene")
    m.global = screen.getGlobalNode()
 
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: ""} )
    m.global.addFields( {selectedUser: -1} )

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
