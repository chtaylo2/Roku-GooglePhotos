
' Menu items for the Screensaver Settings screen
Function getSSaverSettingsList() As Dynamic
    oa = Oauth()
    
    linked=oa.linked()
    userCount=oa.count()
    
    ssUser=RegRead("SSaverUser","Settings")
    if ssUser=invalid then		
        userName=m.oa.userInfoName[0]
    else if ssUser="All (Random)" then
        userName="All (Random)"
    else
        userIndex=0
        for i=0 to userCount-1
            if m.oa.userInfoEmail[i] = ssUser then userIndex=i
        end for
        userName=m.oa.userInfoName[userIndex]				
    end if
    
    ssMethod=RegRead("SSaverMethod","Settings")
    if ssMethod=invalid then		
        ssMethodSel="Multi-Scrolling Photos"	
    else
        ssMethodSel=ssMethod			
    end if
    
    
    ssMethod=RegRead("SSaverMethod","Settings")

    settingsList = [
        {
            Title:"Select Linked User",
            ID:"1",
            ShortDescriptionLine1: "Current setting: " + userName
            ShortDescriptionLine2: "Defines which account to pull photos from"
        },
        {
            Title:"Set Screensaver Display Method",
            ID:"2",
            ShortDescriptionLine1: "Current setting: " + ssMethodSel
            ShortDescriptionLine2: "Defines how the screensaver shows photos"
        },
        {
            Title:"About",
            ID:"3",
            ShortDescriptionLine1: ""
            ShortDescriptionLine2: "About this channel"
        }
    ]
    return settingsList
End Function

Sub googlephotos_browse_ssaversettings()
    screen=CreateObject("roListScreen")
    screen.SetContent(getSSaverSettingsList())
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Screensaver", "Settings")
    screen.show()
    
    menuSelections = [googlephotos_set_ss_link, googlephotos_set_ss_method, googlephotos_about]
    
    while(true)
        msg = wait(0,port)
        if msg.isScreenClosed() then 'ScreenClosed event
            exit while
        else if (type(msg) = "roListScreenEvent")
            if(msg.isListItemSelected())
                menuSelections[msg.GetIndex()]()
                screen.SetContent(getSSaverSettingsList())
            endif
        endif
    end while
    
End Sub

Sub googlephotos_set_ss_method()
    ssMethod=RegRead("SSaverMethod","Settings")
    if ssMethod=invalid then		
        ssMethodSel="Multi-Scrolling Photos"	
    else
        ssMethodSel=ssMethod			
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Screensaver Display", "Settings")
    screen.AddHeaderText("Screensaver Display Method")
    screen.AddParagraph("Lets you determine how the screensaver displays your photos. If you can't decide, select Random and Google Photos will select for you when your screensaver runs.")
    screen.AddParagraph(" ")
    screen.AddParagraph("Current setting: " + ssMethodSel)
    screen.AddButton(0, "Multi-Scrolling Photos")
    screen.AddButton(1, "Fading Photo - Large")
    screen.AddButton(2, "Fading Photo - Small")
    screen.AddButton(3, "Random")
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
                        RegWrite("SSaverMethod","Multi-Scrolling Photos","Settings")
                    else if res=1
                        RegWrite("SSaverMethod","Fading Photo - Large","Settings")
                    else if res=2
                        RegWrite("SSaverMethod","Fading Photo - Small","Settings")
                    else if res=3
                        RegWrite("SSaverMethod","Random","Settings")
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

Sub googlephotos_set_ss_link()
    oa = Oauth()
    
    linked=m.oa.linked()
    userCount=m.oa.count()

    ssUser=RegRead("SSaverUser","Settings")
    if ssUser=invalid then		
        ssUserSel=m.oa.userInfoName[0]
    else if ssUser="All (Random)" then
        ssUserSel="All (Random)"
    else
        userIndex=0
        for i=0 to userCount-1
            if m.oa.userInfoEmail[i] = ssUser then userIndex=i
        end for
        ssUserSel=m.oa.userInfoName[userIndex]				
    end if		

    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Screensaver Display", "Settings")
    screen.AddHeaderText("Screensaver Display User")
    if linked then
        screen.AddParagraph("Your Google Photos account is successfully linked. This screensavor will randomly display the personal photos from the user selected below.")
        screen.AddParagraph(" ")
        screen.AddParagraph("Choose which linked user to display photos from")
        screen.AddParagraph("Current setting: " + ssUserSel)
            
        for i = 0 to userCount-1
            screen.AddButton(i, m.oa.userInfoName[i])
        end for
        if userCount > 1 then
            screen.AddButton(98, "All (Random)")
        end if
        
    else
        screen.AddParagraph("Your Google Photos account is not linked.  Please link your account through the Google Photos channel to view your personal photos.")
    end if
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
                if button_idx <> 98 then
                    RegWrite("SSaverUser",m.oa.userInfoEmail[button_idx],"Settings")
                else
                    RegWrite("SSaverUser","All (Random)","Settings")
                end if
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub

