Sub Init()
    if m.oa = invalid then m.oa = InitOauth(getClientId(), getClientSecret())
    if m.picasa = invalid then m.picasa = InitPicasa()
End Sub

Sub RunUserInterface()
    'initialize theme attributes like titles, logos and overhang color
    initTheme()
    
    ' Pop up start of UI for some instant feedback while we load the icon data
    screen=uitkPreShowPosterMenu()
	
    if screen=invalid then
        print "unexpected error in uitkPreShowPosterMenu"
        return
    end if    
    
    Init()
    oa = Oauth()
    picasa = LoadPicasa()
    
    ' Attempt to register if we are not already registered
    doRegistration()

    ' If registration fails, continue anyway so the user can still access the settings (about) screen for help
    
    highlights=[]
    rsp=picasa.ExecServerAPI("featured?max-results=10&v=2.0&fields=entry(title,gphoto:id,media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax=912",invalid)
    if isxmlelement(rsp) then 
        images=picasa_new_image_list(rsp.entry)
        for each image in images
            highlights.Push(image.GetThumb())
        end for
    end if    
    
    for i=0 to 14
        if highlights[i]=invalid then
            highlights[i]="pkg:/images/icon_s.png"
        end if
    end for

	photoIcon="pkg:/images/icon_photo_big.png"
	searchIcon="pkg:/images/search.png"
	settingsIcon="pkg:/images/gear.png"
	favoriteIcon="pkg:/images/favorite.png"
	tagsIcon="pkg:/images/tags.png"
	randomIcon="pkg:/images/XXX.png"
    picasa.highlights=highlights
    
    menudata=[
        {ShortDescriptionLine1:"My Albums", ShortDescriptionLine2:"Browse your albums", HDPosterUrl:photoIcon, SDPosterUrl:photoIcon},
		{ShortDescriptionLine1:"Search", ShortDescriptionLine2:"Search your albums", HDPosterUrl:searchIcon, SDPosterUrl:searchIcon},
        {ShortDescriptionLine1:"Tags", ShortDescriptionLine2:"Browse your tags", HDPosterUrl:tagsIcon, SDPosterUrl:tagsIcon},
        {ShortDescriptionLine1:"Favorites", ShortDescriptionLine2:"Browse your favorites", HDPosterUrl:favoriteIcon, SDPosterUrl:favoriteIcon},
        {ShortDescriptionLine1:"Random Photos", ShortDescriptionLine2:"Display a random slideshow of your photos", HDPosterUrl:randomIcon, SDPosterUrl:randomIcon},
	    {ShortDescriptionLine1:"Explore Picasa", ShortDescriptionLine2:"Browse content from around Picasa", HDPosterUrl:highlights[0], SDPosterUrl:highlights[0]},
        {ShortDescriptionLine1:"Settings", ShortDescriptionLine2:"Edit channel settings", HDPosterUrl:settingsIcon, SDPosterUrl:settingsIcon},
    ]
    onselect=[0, m.picasa, "BrowseAlbums","SearchAlbums","BrowseTags","BrowseFavorites","RandomPhotos", "BrowsePicasa", "BrowseSettings"]
    
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
    theme.OverhangSliceSD 				= "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  		= "pkg:/images/Logo_Overhang_SD.png"
    
    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "10"
    theme.OverhangSliceHD 				= "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  		= "pkg:/images/Logo_Overhang_HD.png"
    
    theme.GridScreenLogoHD          	= "pkg:/images/Logo_Overhang_HD.png"
	theme.GridScreenOverhangSliceHD 	= "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.GridScreenLogoOffsetHD_X  	= "123"
    theme.GridScreenLogoOffsetHD_Y  	= "10"
	theme.GridScreenOverhangHeightHD	= "140"

    theme.GridScreenLogoSD          	= "pkg:/images/Logo_Overhang_SD.png"
	theme.GridScreenOverhangSliceSD 	= "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.GridScreenLogoOffsetSD_X  	= "72"
    theme.GridScreenLogoOffsetSD_Y  	= "10"
	theme.GridScreenOverhangHeightSD	= "95"
	
    theme.BackgroundColor 				= "#EBEBEB"
	theme.GridScreenBackgroundColor		= "#EBEBEB"
	theme.BreadcrumbDelimiter			= "#808080"
	theme.BreadcrumbTextLeft			= "#808080"
	theme.BreadcrumbTextRight			= "#B3B3B3"
	theme.GridScreenListNameColor   	= "#808080"
    theme.GridScreenRetrievingColor		= "#808080"
	
    app.SetTheme(theme)
	
	print "initTheme()"
	
End Sub
