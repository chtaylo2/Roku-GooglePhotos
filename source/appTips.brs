' Get the list of menu items to show on the Settings screen
Function getTipsList() As Dynamic

    tipsList = [
        {
            Title:"Utilizing Google's Smart Search",
            ID:"1",
            ShortDescriptionLine2: "Smart search including person, place or thing recognition"
        },
        {
            Title:"Setting up Google Photo's Screensaver",
            ID:"2",
            ShortDescriptionLine2: "Did you know this channel is also a screensaver?"
        },
        {
            Title:"Setting up Albums in Google Photos",
            ID:"3",
            ShortDescriptionLine2: "Albums are the best way to stay orginized, find out how!"
        },
        {
            Title:"Reporting Bugs or Feature Requests",
            ID:"4",
            ShortDescriptionLine2: "We'd love to hear your feedback"
        }
    ]
    return tipsList
End Function

Sub googlephotos_browse_tips()
    screen=CreateObject("roListScreen")
    screen.SetContent(getTipsList())
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Tips and Tricks")
    screen.show()
    
    menuSelections = [googlephotos_tips_smartsearch, googlephotos_tips_screensaver, googlephotos_tips_albums, googlephotos_tips_feedback]
    
    while(true)
        msg = wait(0,port)
        if msg.isScreenClosed() then 'ScreenClosed event
            exit while
        else if (type(msg) = "roListScreenEvent")
            if(msg.isListItemSelected())
                menuSelections[msg.GetIndex()]()
                screen.SetContent(getTipsList())
            endif
        endif
    end while
    
End Sub

Sub googlephotos_tips_smartsearch()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Smart Search", "Tips and Tricks")
    screen.AddHeaderText("Find people, things and places in your photos")
    screen.AddParagraph("This is by far one of best features of Google Photos. Smart search allows you to search for anything. A friends name, a location, a color; the options are endless. This channel supports all of these searches!")
    screen.AddParagraph(" ")
    screen.AddParagraph(" To apply names to faces:")
    screen.AddParagraph("   STEP 1: Using your computer (photos.google.com/search) or Google Photos smartphone app.")
    screen.AddParagraph("   STEP 2: Tap the search bar and select a face. At the top click [Who's this?]")
    screen.AddParagraph(" ")
    screen.AddParagraph("For more details: https://support.google.com/photos/answer/6128838")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub

Sub googlephotos_tips_screensaver()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Screensaver", "Tips and Tricks")
    screen.AddHeaderText("Google Photo's Screensaver")
    screen.AddParagraph("Built into this Roku channel is a screensaver which lets will stream your photos while the device is inactive.")
    screen.AddParagraph(" ")
    screen.AddParagraph(" To enable screensaver:")
    screen.AddParagraph("   STEP 1: Roku Home > Settings > Screensaver > select [Google Photos]")
    screen.AddParagraph("   STEP 2: In the Custom Settings, select a linked account (if you have multiple)")
    screen.AddParagraph("   STEP 3: Back out to [Wait time] and ensure screensaver is active")
    screen.AddParagraph(" ")
    screen.AddParagraph("For more details: https://support.roku.com/article/212015418")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub

Function googlephotos_tips_albums()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Album Tips", "Tips and Tricks")
    screen.AddHeaderText("Google Photo Albums")
    screen.AddParagraph("Photo albums let you orginize your photos quick and easy. You no longer have to break out the glue gun and it's much more powerful then your grandmothers dusty album book!")
    screen.AddParagraph("On the Google Photos site (photos.google.com) or Google Photos smartphone app, simply create an album and select photos you want added. You may also add text and locations to help you with searching later on. (See 'Smart Search' tip) ")
    screen.AddParagraph("Ten years down the road, you'll be happy the photos are orginized and easily found.")
    screen.AddParagraph(" ")
    screen.AddParagraph("For more details: https://support.google.com/photos/answer/6128849")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Function

Sub googlephotos_tips_feedback()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Feedback", "Tips and Tricks")
    screen.AddHeaderText("Report Bugs or Feature Requests")
    screen.AddParagraph("This channel is not affiliated with Google. See version history back on the Settings > About page.")
    screen.AddParagraph(" ")
    screen.AddParagraph("To report bugs and request features, please open a [New Issue] here:")
    screen.AddParagraph("  https://github.com/chtaylo2/Roku-GooglePhotos/issues")
    screen.AddParagraph(" ")
    screen.AddParagraph("Thank you!")
    screen.Show()

    while true
        msg = wait(0, screen.GetMessagePort())

        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub
