
' Get the list of menu items to show on the Settings screen
Function getSettingsList() As Dynamic
    currentSlideshowDelay = RegRead("SlideshowDelay","Settings")
    'currentServerPort = RegRead("server_port", "preferences", "Not Set")
    
    if currentSlideshowDelay=invalid then
        delaytext="Not set (default 3 seconds)"
    else
        delaytext=currentSlideshowDelay+" seconds"
    end if

    settingsList = [
        {
            Title:"Set Slideshow Delay",
            ID:"1",
            ShortDescriptionLine1: "Current setting: " + delaytext
            ShortDescriptionLine2: "Defines photo delay during slideshow"
        },
        {
            Title:"Deactivate Player",
            ID:"2",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "Remove link from Picasa account"
        },
        {
            Title:"About",
            ID:"2",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "About this channel"
        }
    ]
    return settingsList
End Function

Sub picasa_browse_settings()
    'screen=uitkPreShowPosterMenu("","Settings")
    screen=CreateObject("roListScreen")
    screen.SetContent(getSettingsList())
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    screen.show()
    
    'settingmenu = [
    '    {ShortDescriptionLine1:"Slideshow Delay", ShortDescriptionLine2:"Change slideshow delay", HDPosterUrl:highlights[4], SDPosterUrl:highlights[4]},
    '    {ShortDescriptionLine1:"Deactivate Player", ShortDescriptionLine2:"Remove link from Picasa account", HDPosterUrl:highlights[5], SDPosterUrl:highlights[5]},
    '    {ShortDescriptionLine1:"About", ShortDescriptionLine2:"About the channel", HDPosterUrl:highlights[6], SDPosterUrl:highlights[6]},
    ']
    'onselect = [0, m, "SlideshowSpeed","DelinkPlayer","About"]
    
    menuSelections = [picasa_set_slideshow_speed, picasa_delink, picasa_about]
    
    while(true)
        msg = wait(0,port)
        if msg.isScreenClosed() then 'ScreenClosed event
            exit while
        else if (type(msg) = "roListScreenEvent")
            if(msg.isListItemSelected())
                menuSelections[msg.GetIndex()]()
                screen.SetContent(getSettingsList())
            endif
        endif
    end while
    
End Sub

Sub picasa_set_slideshow_speed()
    ssdur=RegRead("SlideshowDelay","Settings")
    if ssdur=invalid then
        delaytext="Not set (default 3 seconds)"
    else
        delaytext=ssdur+" seconds"
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    screen.AddHeaderText("Slideshow Delay")
    screen.AddParagraph("This setting defines the length of delay between photos during your slideshow.")
    screen.AddParagraph("Current setting: " + delaytext)
    screen.AddButton(1, "1 second")
    screen.AddButton(3, "3 seconds (Default)")
    screen.AddButton(5, "5 seconds")
    screen.AddButton(10, "10 seconds")
    screen.AddButton(30, "30 seconds")
    screen.AddButton(0, "Custom")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                button_idx=msg.GetIndex()
                if button_idx = 0 then
                    speed=picasa_set_custom_slideshow_speed()
                else
                    speed=button_idx
                end if
                
                if speed<>invalid then
                    RegWrite("SlideshowDelay",Str(speed),"Settings")
                    m.SlideshowDuration=button_idx
                end if
                
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub

Function picasa_set_custom_slideshow_speed()
    port = CreateObject("roMessagePort")
    pin = CreateObject("roPinEntryDialog")
    pin.SetMessagePort(port)
    
    pin.SetTitle("Enter Custom Slideshow Speed")
    pin.SetNumPinEntryFields(3)
    pin.AddButton(0, "OK")
    pin.AddButton(1, "Cancel")
    pin.Show()
    
    while true
        msg = wait(0, pin.GetMessagePort())
        
        if type(msg) = "roPinEntryDialogEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                return invalid
            else if msg.isButtonPressed()
                buttonID = msg.GetIndex()
                print "buttonID pressed: "; buttonID
                if (buttonID = 0)
                    pinCode = pin.Pin()
                    print "Got pin: " + pinCode
                    return Val(pinCode)
                else if (buttonID = 1)
                    print "Cancel Pressed"
                    pin.Close()
                    return invalid
                end if
                return Val(pin.Pin())
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                return invalid
            end if
        end if
    end while
End Function

Sub picasa_delink()
    ans=ShowDialog2Buttons("Deactivate Player","Remove link to your Picasa account?","Confirm","Cancel")
    if ans=0 then 
        oa = Oauth()
        oa.erase()
    end if
End Sub

Sub picasa_about()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    
    screen.AddHeaderText("About the channel")
    
    screen.AddParagraph("The channel is not affiliated with Google.")

    para = "The Picasa Web Albums Channel (v1) was originally developed by Chris Hoffman. "
    para = para + "Picasa Web Albums Channel (v2) was developed by Belltown which added OAuth2 and bug fixes."
    screen.AddParagraph(para)
    
    screen.AddParagraph("This version of the channel (v3) was developed by Chris Taylor which adds a number of functionality improvements. ")
    screen.AddParagraph("If you have any questions or comments, post them in forums.roku.com in the General Discussions forum (preferably in an existing Picasa thread).")

    screen.AddButton(1, "Back")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            endif
        endif
    end while
End Sub

