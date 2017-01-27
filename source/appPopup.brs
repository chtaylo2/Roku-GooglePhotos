Sub googlephotos_featurespopup()

    googlephotos = LoadGooglePhotos()

    'Write reg entry to we don't redisplay
    RegWrite("FeaturePopup", googlephotos.releaseVersion,"Settings")

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Version " + googlephotos.releaseVersion, "New Features")
    
    screen.AddHeaderText("New Channel Features")
    screen.AddParagraph("1. Multiple new screensavers have been added to let you enjoy your photos while this device is inactive. Including multi-photo scrolling!")
    screen.AddParagraph("2. Album paging has been added for large albums with over 1,000 items.")
    screen.AddParagraph("Bug fixes:")
    screen.AddParagraph("   - Linking non gmail.com accounts issue fixed")
    screen.AddParagraph("   - Slideshow speed changes not being honored in same session")
    screen.AddParagraph("   - Message tip would not show on albums with single photo")
    screen.AddParagraph("   - Various other small bugs")
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

Sub googlephotos_thousandpopup()

    'Write reg entry to we don't redisplay
    RegWrite("ThousandPopup", "true","Settings")

    port   = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Media Limitations", "Tips")
    
    screen.AddHeaderText("Large Album Details")
    screen.AddParagraph("Please be aware Google limits the amount of media we can pull back per request to 1,000 items. To account for this limitation, we have implemented paging to allow to you view all media.")
    screen.AddParagraph(" ")
    screen.AddParagraph("Paging also allows accessing your photos much quicker as it reduces API calls. Be aware, a lower page number holds more recent media content.")
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