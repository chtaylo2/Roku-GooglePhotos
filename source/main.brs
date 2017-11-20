
sub Main()
    showGooglePhotosScreen()
end sub

sub showGooglePhotosScreen()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    device = CreateObject("roDeviceInfo")
    screen.setMessagePort(m.port)
    scene = screen.CreateScene("GooglePhotosMainScene")
  
    m.global = screen.getGlobalNode()
 
    ds=device.GetDisplaySize()
    
    m.global.addFields( {screenWidth: ds.w, screenHeight: ds.h, selectedUser: 0} )
    m.global.addFields( {selectedUser: 0} )
    
    screen.show()

    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
          if msg.isScreenClosed() then return
        end if
    end while
end sub
