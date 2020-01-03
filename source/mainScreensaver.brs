'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

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
    cecstatus = CreateObject("roCECStatus")
   
    scene    = screen.CreateScene("GooglePhotosScreensaver")
    m.global = screen.getGlobalNode()
 
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: "", VideoContinuePlay: ""} )
    m.global.addFields( {selectedUser: -1, CECStatus: true} )
    
    cecstatus.SetMessagePort(port)
    screen.setMessagePort(port)    
    screen.show()

    'Calculate uptime for devices that were booted in last 30 minutes and not touched. Otherwise, IsActiveSource() == false
    currentuptime = UpTime(0)

    if (CECStatus <> invalid) and (CECStatus.IsActiveSource() = false) and (currentuptime > 1805) then
        'HDMI-CEC status is false
        m.global.CECStatus = false
    else
        'HDMI-CEC status is true
        m.global.CECStatus = true
    end if

    while(true)
        msg     = wait(0, port)
        msgType = type(msg)

        if msgType = "roCECStatusEvent"
            'print "RECEIVED roCECStatusEvent event - CECStatus.IsActiveSource: -> "; CECStatus.IsActiveSource()
            
            if CECStatus <> invalid and CECStatus.IsActiveSource() = false then
                'HDMI-CEC status has changed to false
                m.global.CECStatus = false
            else
                'HDMI-CEC status has changed to true
                m.global.CECStatus = true
            end if
            
        end if
        
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
 
    m.global.addFields( {SSaverUser: "", SSaverRes: "", SSaverMethod: "", SSaverDelay: "", SSaverOrder: "", SSaverVideo: "", SSaverCEC: ""} )
    m.global.addFields( {SlideshowRes: "", SlideshowDisplay: "", SlideshowDelay: "", SlideshowOrder: "", VideoContinuePlay: ""} )
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

