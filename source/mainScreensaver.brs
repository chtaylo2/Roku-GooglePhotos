
Sub RunScreensaver()
    'Start main screensaver
    showGooglePhotosScreensaver()
End Sub


Sub RunScreenSaverSettings()
    'Start screensaver settings
    showGooglePhotosScreensaverSettings()
End Sub


Sub showGooglePhotosScreensaver()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
   
    scene    = screen.CreateScene("GooglePhotosScreensaver")
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


Sub showGooglePhotosScreensaverSettings()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
   
    scene    = screen.CreateScene("GooglePhotosScreensaverSettings")
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

