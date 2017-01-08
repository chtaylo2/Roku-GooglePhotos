Sub Init()
    if m.oa = invalid then m.oa = InitOauth(getClientId(), getClientSecret())
    if m.googlephotos = invalid then m.googlephotos = InitGooglePhotos()
End Sub

Sub RunUserInterface()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    ' Pop up start of UI for some instant feedback while we load the icon data
    screen=uitkPreShowPosterMenu("", "")
	
    if screen=invalid then
        print "unexpected error in uitkPreShowPosterMenu"
        return
    end if
	
    Init()
    oa = Oauth()
    googlephotos = LoadGooglePhotos()
    
    ' Attempt to register if we are not already registered
    doRegistration()

    SelectLinkedUser()
	
    sleep(25)
End Sub

Sub SelectLinkedUser()

    oa = Oauth()

    usersLoaded = oa.count()
    if usersLoaded=invalid then
        oa.erase()
    
        port = CreateObject("roMessagePort")
        screen = CreateObject("roParagraphScreen")
        screen.SetMessagePort(port)
        screen.SetBreadcrumbText("", "Select User")
        screen.AddParagraph("Oops, we have a problem")
		screen.AddParagraph(" ")
        screen.AddParagraph("There appears to be an error loading users linked to this device. This is possible if you recently upgraded this Roku Channel. Please re-register to your Google Photos account by clicking the 'continue' button below.")
        screen.AddButton(1, "Continue")
        screen.Show()
    
        while true
            msg = wait(0, screen.GetMessagePort())
        
            if type(msg) = "roParagraphScreenEvent"
                if msg.isScreenClosed()
                    print "Screen closed"
                    exit while                
                else if msg.isButtonPressed()
                    doRegistration()
                    exit while
                else
                    print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                    exit while
                endif
            endif
        end while
    else
	
	    if usersLoaded > 1 then
            screen=uitkPreShowPosterMenu("","Select User", "flat-category")
    
            userdata=[]
            for i = 0 to usersLoaded-1
		        print "User: "; oa.userInfoName[i]
		        userdata.Push({ShortDescriptionLine1: oa.userInfoName[i], ShortDescriptionLine2: oa.userInfoEmail[i], HDPosterUrl: oa.userInfoPhoto[i], SDPosterUrl: oa.userInfoPhoto[i]})
		    end for
		
            onselect = [1, users, m, function(users, googlephotos, set_idx):ShowMainMenu(set_idx):end function]
            uitkDoPosterMenu(userdata, screen, onselect)
        else
		    ShowMainMenu(0)
	    end if
    end if
    
End Sub

Sub ShowMainMenu(userIndex=0 As Integer)

    oa = Oauth()
	oa.currentAccessTokenInd = userIndex
	
    ' Pop up start of UI for some instant feedback while we load the icon data
    screen=uitkPreShowPosterMenu(oa.userInfoName[userIndex], "Main Menu")
	
    if screen=invalid then
        print "unexpected error in uitkPreShowPosterMenu"
        return
    end if    

    photoIcon="pkg:/images/icon_photo_big.png"
    searchIcon="pkg:/images/search.png"
    settingsIcon="pkg:/images/gear.png"
    favoriteIcon="pkg:/images/favorite.png"
    tagsIcon="pkg:/images/tags.png"
    randomIcon="pkg:/images/random_icon.png"
    
    menudata=[
        {ShortDescriptionLine1:"My Albums", ShortDescriptionLine2:"Browse your albums", HDPosterUrl:photoIcon, SDPosterUrl:photoIcon},
        {ShortDescriptionLine1:"Search", ShortDescriptionLine2:"Search your albums", HDPosterUrl:searchIcon, SDPosterUrl:searchIcon},
        {ShortDescriptionLine1:"Tags", ShortDescriptionLine2:"Browse your tags", HDPosterUrl:tagsIcon, SDPosterUrl:tagsIcon},
        {ShortDescriptionLine1:"Favorites", ShortDescriptionLine2:"Browse your favorites", HDPosterUrl:favoriteIcon, SDPosterUrl:favoriteIcon},
        {ShortDescriptionLine1:"Shuffle Photos", ShortDescriptionLine2:"Display a random slideshow of your photos", HDPosterUrl:randomIcon, SDPosterUrl:randomIcon},
        {ShortDescriptionLine1:"Settings", ShortDescriptionLine2:"Edit channel settings", HDPosterUrl:settingsIcon, SDPosterUrl:settingsIcon},
    ]
    onselect=[0, m.googlephotos, "BrowseAlbums","SearchAlbums","BrowseTags","BrowseFavorites","ShufflePhotos", "BrowseSettings"]
    
    uitkDoPosterMenu(menudata, screen, onselect)    
    
	sleep(25)
End Sub

'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'*************************************************************

Sub initTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")
    
    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "10"
    theme.OverhangSliceSD               = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD         = "pkg:/images/Logo_Overhang_SD.png"
    
    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "10"
    theme.OverhangSliceHD               = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD         = "pkg:/images/Logo_Overhang_HD.png"
    
    theme.GridScreenLogoHD              = "pkg:/images/Logo_Overhang_HD.png"
    theme.GridScreenOverhangSliceHD     = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.GridScreenLogoOffsetHD_X      = "123"
    theme.GridScreenLogoOffsetHD_Y      = "10"
    theme.GridScreenOverhangHeightHD    = "140"

    theme.GridScreenLogoSD              = "pkg:/images/Logo_Overhang_SD.png"
    theme.GridScreenOverhangSliceSD     = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.GridScreenLogoOffsetSD_X      = "72"
    theme.GridScreenLogoOffsetSD_Y      = "10"
    theme.GridScreenOverhangHeightSD    = "95"
	
    theme.BackgroundColor               = "#EBEBEB"
    theme.GridScreenBackgroundColor     = "#EBEBEB"
    theme.BreadcrumbDelimiter           = "#808080"
    theme.BreadcrumbTextLeft            = "#808080"
    theme.BreadcrumbTextRight           = "#B3B3B3"
    theme.GridScreenListNameColor       = "#808080"
    theme.GridScreenRetrievingColor     = "#808080"
	
    app.SetTheme(theme)
	
    print "initTheme()"
	
End Sub
