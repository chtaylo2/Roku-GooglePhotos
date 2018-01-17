
Sub Main()
    'Start main screen
    showGooglePhotosScreen()
End Sub

Sub showGooglePhotosScreen()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
    device   = CreateObject("roDeviceInfo")
    screen.setMessagePort(port)
    
    scene    = screen.CreateScene("GooglePhotosMainScene")
    m.global = screen.getGlobalNode()
    ds       = device.GetDisplaySize()
 
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: ""} )   
    m.global.addFields( {screenWidth: ds.w, screenHeight: ds.h} )
    m.global.addFields( {selectedUser: -1} )
    
    screen.show()

    while(true)
        msg     = wait(0, port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
End Sub
