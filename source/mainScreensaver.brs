
Sub RunScreensaver()
    'Start main screensaver
    showGooglePhotosScreensaver()
End Sub


Sub showGooglePhotosScreensaver()
    screen   = CreateObject("roSGScreen")
    port     = CreateObject("roMessagePort")
   
    scene    = screen.CreateScene("GooglePhotosScreensaver")
 
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
