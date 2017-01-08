
' Get the list of menu items to show on the Settings screen
Function getSettingsList() As Dynamic
    currentSlideshowDelay = RegRead("SlideshowDelay","Settings")
    
    if currentSlideshowDelay=invalid then
        delaytext="Not set (default 3 seconds)"
    else
        delaytext=currentSlideshowDelay+" seconds"
    end if

    currentSlideshowRes = RegRead("SlideshowRes","Settings")

    if currentSlideshowRes=invalid then
        device = createObject("roDeviceInfo")
        is4k = (val(device.GetVideoMode()) = 2160)
        is1080p = (val(device.GetVideoMode()) = 1080)

        if is4k then
            restext="Not set (default FHD)"
        else if is1080p
            restext="Not set (default HD)"
        else
            restext="Not set (default SD)"
        end if
    else
        restext=currentSlideshowRes
    end if

    settingsList = [
        {
            Title:"Set Photo Download Resolution",
            ID:"1",
            ShortDescriptionLine1: "Current setting: " + restext
            ShortDescriptionLine2: "Defines photo size downloaded"
        },
        {
            Title:"Set Slideshow Delay",
            ID:"2",
            ShortDescriptionLine1: "Current setting: " + delaytext
            ShortDescriptionLine2: "Defines photo delay during slideshow"
        },
        {
            Title:"Link additional Google Photos account",
            ID:"3",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "Link additional Google Photos account"
        },
        {
            Title:"Deactivate Player",
            ID:"4",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "Remove link from Google Photos account"
        },
        {
            Title:"About",
            ID:"5",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "About this channel"
        }
    ]
    return settingsList
End Function

Sub googlephotos_browse_settings()
    screen=CreateObject("roListScreen")
    screen.SetContent(getSettingsList())
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    screen.show()
    
    menuSelections = [googlephotos_set_slideshow_res, googlephotos_set_slideshow_speed, doAdditionalReg, googlephotos_delink, googlephotos_about]
    
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

Sub googlephotos_set_slideshow_res()
    ssres=RegRead("SlideshowRes","Settings")

    device = createObject("roDeviceInfo")
    is4k = (val(device.GetVideoMode()) = 2160)
    is1080p = (val(device.GetVideoMode()) = 1080)

    if ssres=invalid then
        if is4k then
            restext="Not set (default FHD)"
        else if is1080p
            restext="Not set (default HD)"   
        else
            restext="Not set (default SD)"
        end if
    else
        restext=ssres
    end if

    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    screen.AddHeaderText("Photo Download Resolution")
    screen.AddParagraph("This setting defines the photo size downloaded during your slideshow. If you have a slow internet connection, it's recommended to decrease this setting.")
    screen.AddParagraph("Current setting: " + restext)
    if is4k then
        screen.AddButton(2, "Full High Definition (FHD)")
    end if
    if is4k Or is1080p then
        screen.AddButton(1, "High Definition (HD)")
    end if
    screen.AddButton(0, "Standard Definition (SD)")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                res=msg.GetIndex()

                if res<>invalid then
                    if res=0 then
                        RegWrite("SlideshowRes","SD","Settings")
                        m.SlideshowRes="SD"
                    else if res=1
                        RegWrite("SlideshowRes","HD","Settings")
                        m.SlideshowRes="HD"
                    else if res=2
                        RegWrite("SlideshowRes","FHD","Settings")
                        m.SlideshowRes="FHD"
                    end if
                end if

                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub

Sub googlephotos_set_slideshow_speed()
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
                    speed=googlephotos_set_custom_slideshow_speed()
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

Function googlephotos_set_custom_slideshow_speed()
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

Sub googlephotos_comingSoon()
    ans=ShowDialog1Button("Link additional account","Ability to link additional account coming soon!","Back")
End Sub

Sub googlephotos_delink()
    ans=ShowDialog2Buttons("Deactivate Player","Remove link to your Google Photos account?","Confirm","Cancel")
    if ans=0 then 
        oa = Oauth()
        oa.erase()
        
        ans2=ShowDialog1Button("Success","You have successfully unlinked this Roku device.","Close")
        doRegistration()
    end if
End Sub

Sub googlephotos_about()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Settings")
    
    screen.AddHeaderText("About this channel")
    
    screen.AddParagraph("The channel is not affiliated with Google.")

    screen.AddParagraph("The Google Photos Channel, current version (v3) was developed by Chris Taylor which adds a numbers of functional improvements. It has also been rebranded for Google Photos as Picasa has been discontinued by Google.")
    screen.AddParagraph("The original Picasa Web Albums Channel (v1) was developed by Chris Hoffman and Belltown developing (v2) which added OAuth2 and other bug fixes.")
    screen.AddParagraph("If you have any questions or comments, post them in forums.roku.com in the General Discussions forum.")

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

