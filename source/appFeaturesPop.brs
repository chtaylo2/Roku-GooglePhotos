Sub googlephotos_featurespopup()

    googlephotos = LoadGooglePhotos()

    'Write reg entry to we don't redisplay
    RegWrite("FeaturePopup", googlephotos.releaseVersion,"Settings")

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Version " + googlephotos.releaseVersion, "New Features")
    
    screen.AddHeaderText("New Features")
    screen.AddParagraph("Multiple new screensavers have been added to let you display your Google Photos while this device is inactive. See Tips and Tricks for help with enabling these screensavers.")
    screen.AddParagraph("Bug fixes:")
    screen.AddParagraph("   - Linking non gmail.com accounts issue fixed")
    screen.AddParagraph("   - Slideshow speed changes not being honored in same session")
    screen.AddParagraph("   - Message tip would not show on albums with single photos")
    screen.AddParagraph("Thank you for using the Google Photos Channel. Please remember to rate us!")
    screen.AddButton(1, "Continue")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                exit while
            else
                exit while
            endif
        endif
    end while
End Sub