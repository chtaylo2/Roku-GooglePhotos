Sub Init()
    if m.oa = invalid then m.oa = InitOauth(getClientId(), getClientSecret())
    if m.googlephotos = invalid then m.googlephotos = InitGooglePhotos()
End Sub

Sub RunUserInterface()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()

    ' Pop up start of UI for some instant feedback while we load the icon data
    screen=uitkPreShowPosterMenu(0, "", "")
	
    if screen=invalid then
        print "unexpected error in uitkPreShowPosterMenu"
        return
    end if
	
	
    Init()
    oa = Oauth()
    googlephotos = LoadGooglePhotos()
    
	
    'Show new features popup once
    lastPopup = RegRead("FeaturePopup","Settings")
    if lastPopup=invalid then
        googlephotos.FeaturesPopup()
	else if (lastPopup <> googlephotos.releaseVersion) then
        googlephotos.FeaturesPopup()
    end if	
	
    ' Attempt to register if we are not already registered
    usersLoaded = oa.count()
    if usersLoaded=invalid then
        ShowInvalidUser()
    end if

    while true
        regStatus = doRegistration()
        if regStatus<>1
            exit while
        end if
    end while

    if regStatus<>invalid
        SelectLinkedUser()
    end if
	
End Sub

Sub SelectLinkedUser()

    oa = Oauth()

    usersLoaded = oa.count()
    if usersLoaded=invalid then
        ShowInvalidUser()
    else if usersLoaded > 1 then
        screen=uitkPreShowPosterMenu(0, "","Select User", "flat-category")
	
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
    
End Sub

Sub ShowInvalidUser()

    ''TODO: Need to see if this is still even needed. May not be now because of the legacy user addition
	
    oa = Oauth()
    oa.erase()

    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("", "Select User")
    screen.AddParagraph("Application Upgrade")
    screen.AddParagraph(" ")
    screen.AddParagraph("If this is the first time you're seeing this, it's likely this channel was recently upgraded allowing multiple accounts. Please re-register to your Google Photos account by clicking the 'continue' button below to be properly linked.")
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
End Sub

Sub ShowMainMenu(userIndex=0 As Integer)

    oa = Oauth()
    oa.currentAccessTokenInd = userIndex
	
    ' Pop up start of UI for some instant feedback while we load the icon data
    screen=uitkPreShowPosterMenu(0, oa.userInfoName[userIndex], "Main Menu")
	
    if screen=invalid then
        print "unexpected error in uitkPreShowPosterMenu"
        return
    end if    

    photoIcon="pkg:/images/icon_photo_big.png"
    searchIcon="pkg:/images/search.png"
    settingsIcon="pkg:/images/gear.png"
    randomIcon="pkg:/images/random_icon.png"
	tipsIcon="pkg:/images/tipsandtricks.png"
    
    menudata=[
        {ShortDescriptionLine1:"My Albums", ShortDescriptionLine2:"Browse your albums", HDPosterUrl:photoIcon, SDPosterUrl:photoIcon},
        {ShortDescriptionLine1:"Search", ShortDescriptionLine2:"Search your albums", HDPosterUrl:searchIcon, SDPosterUrl:searchIcon},
        {ShortDescriptionLine1:"Shuffle Photos", ShortDescriptionLine2:"Display a random slideshow of your photos", HDPosterUrl:randomIcon, SDPosterUrl:randomIcon},
		{ShortDescriptionLine1:"Tips and Tricks", ShortDescriptionLine2:"Get the most out of Google Photos!", HDPosterUrl:tipsIcon, SDPosterUrl:tipsIcon},
        {ShortDescriptionLine1:"Settings", ShortDescriptionLine2:"Edit channel settings", HDPosterUrl:settingsIcon, SDPosterUrl:settingsIcon},
    ]
    onselect=[0, m.googlephotos, "BrowseAlbums", "SearchAlbums", "ShufflePhotos", "TipsAndTricks", "BrowseSettings"]
    
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
