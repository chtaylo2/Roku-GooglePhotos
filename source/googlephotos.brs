
Function LoadGooglePhotos() As Object
    ' global singleton
    return m.googlephotos
End Function

Function InitGooglePhotos() As Object

    this                      = CreateObject("roAssociativeArray")
	
    this.releaseVersion       = "1.6"
    this.scope                = "https://picasaweb.google.com/data"
    this.prefix               = this.scope + "/feed/api"
    
    this.ExecServerAPI        = googlephotos_exec_api
    
    'Search
    this.SearchAlbums         = googlephotos_user_search
	
    'Album
    this.BrowseAlbums         = googlephotos_browse_albums
    this.newAlbumListFromXML  = googlephotos_new_album_list
    this.newAlbumFromXML      = googlephotos_new_album
    this.getAlbumMetaData     = googlephotos_get_album_meta
    this.DisplayAlbum         = googlephotos_display_album
    this.AlbumPages           = googlephotos_album_pages
    
    'Video
    this.BrowseVideos         = googlephotos_browse_videos
	
    'Main / Settings
    this.ShufflePhotos        = googlephotos_random_photos
    this.TipsAndTricks        = googlephotos_browse_tips
    this.BrowseSettings       = googlephotos_browse_settings
    this.SetSlideshowSpeed    = googlephotos_set_slideshow_speed
    this.SetResoltion         = googlephotos_set_slideshow_res
    this.DelinkPlayer         = googlephotos_delink
    this.About                = googlephotos_about
 
    'Screensaver
    this.BrowseSSaverSettings = googlephotos_browse_ssaversettings
	
    'Popups
    this.FeaturesPopup        = googlephotos_featurespopup

    'Pull setting
    this.GetResolution        = googlephotos_get_resolution
    this.GetSlideShowSpeed    = googlephotos_get_slideshow_speed
	
    print "GooglePhotos: init complete"

    return this
End Function

' ********************************************************************
' ********************************************************************
' ***** GooglePhotos Functions
' ********************************************************************
' ********************************************************************

Function googlephotos_exec_api(url_stub="" As String, username="default" As Dynamic, userIndex=0 As Integer)

    username="default"
	print "googlephotos_exec_api - enter (username: "; username; " & userIndex: "; userIndex; ")"

    rsp = invalid
    oa = Oauth()
    
    LF = Chr(10)
    
    if username=invalid then
        username=""
    else
        username="user/"+username
    end if
    
	
    ' Issue an API request.
    ' If the access token has expired then request a new one
    ' Retry if an error occurs
    maxAttempts = 3
    for i = 1 to maxAttempts
        http = NewHttp(m.prefix + "/" + username + url_stub)
        oa.sign(http,userIndex)
		
        xml=http.getToStringWithTimeout(10)
        
		responseCode = http.GetResponseCode()
		print "googlephotos_exec_api - attempt #"; i; " responseCode: "; responseCode

        if responseCode >= 400 and responseCode < 500
            ' Expired access token or some other authentication error - refresh access token then retry
			Sleep(500)
            status = oa.RefreshTokens()
			
			' Save the new tokens in the registry
			oa.save()
			print "New access code saved: "; oa.dump()
			
            if i = maxAttempts
                if status <> 0
                    ShowErrorDialog("There is a problem with the Google Photos API access token" + LF + LF + oa.errorMsg + LF + LF + "Exit the channel then try again later","API Authentication Error")
                else
                    ShowErrorDialog("Google Photos API Access Error" + LF + LF + http.GetFailureReason() + LF + LF + "Exit the channel then try again later","API Authentication Error")
                endif
                oa.erase()
                return invalid
            end if
        else if responseCode <> 200
            ' Some other HTTP error - retry
            if i = maxAttempts
                ShowErrorDialog("Invalid return code from Google Photos API" + LF + LF + http.GetFailureReason() + LF + LF + "Exit the channel then try again later","API Error")
                return invalid
            endif
            Sleep(500)
        else
            ' Success
            exit for
        end if
    end for
    
    'print xml
    rsp=ParseXML(xml)
    if rsp=invalid then
        ShowErrorDialog("Unable to parse Google Photos API response" + LF + LF + "Exit the channel then try again later","API Error")
    end if
    
    return rsp
End Function


' ********************************************************************
' ********************************************************************
' ***** Album Functions
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse_albums(username="default")

    oa = Oauth()
    userIndex = oa.accessTokenIndex()
	
    breadcrumb_name=oa.userInfoName[userIndex]
    screen=uitkPreShowPosterMenu(1, breadcrumb_name,"My Albums")
    
    rsp=m.ExecServerAPI("?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))&thumbsize=220",username,userIndex)
    if not isxmlelement(rsp) then return
    albums=m.newAlbumListFromXML(rsp.entry)
    
    if albums.Count()>0 then
        onselect = [1, albums, m, function(albums, googlephotos, set_idx):googlephotos.AlbumPages(albums[set_idx]):end function]
        uitkDoPosterMenu(googlephotos_get_album_meta(albums), screen, onselect)
    else
        uitkDoMessage("You do not have any albums containing photos", screen)
    end if

End Sub

Function googlephotos_new_album_list(xmllist As Object) As Object
    albumlist=CreateObject("roList")
    for each record in xmllist
        album=m.newAlbumFromXML(record)
        if album.GetImageCount() > 0 then
            albumlist.Push(album)
        end if
    next
    
    return albumlist
End Function

Function googlephotos_new_album(xml As Object) As Object
    album = CreateObject("roAssociativeArray")
    album.googlephotos=m
    album.xml=xml

    album.GetUsername=function():return m.xml.GetNamedElements("gphoto:user")[0].GetText():end function
    album.GetTitle=function():return m.xml.title[0].GetText():end function
    album.GetID=function():return m.xml.GetNamedElements("gphoto:id")[0].GetText():end function
    album.GetImageCount=function():return Val(m.xml.GetNamedElements("gphoto:numphotos")[0].GetText()):end function
    album.GetThumb=get_thumb
    return album
End Function

Function googlephotos_get_album_meta(albums As Object)
    albummetadata=[]
    for each album in albums
        thumb=album.GetThumb()
        albummetadata.Push({ShortDescriptionLine1: album.GetTitle(), HDPosterUrl: thumb, SDPosterUrl: thumb})
    next
    return albummetadata
End Function

Function googlephotos_get_album_pages(album As Object)
    albumpages   = []
    totalPages   = album.GetImageCount() / 1000
	currentCount = album.GetImageCount()
	page_start   = 0
	page_end     = 0
	title        = album.GetTitle()
	thumb        = album.GetThumb()
	
    for i = 1 to ceiling(totalPages)
		page_start = 1 + page_end
		if currentCount > 1000 then
		   page_end=page_end + 1000
		   currentCount = currentCount - 1000
		else
           page_end=page_end + currentCount
		end if
		
		page_start_dply = str(page_start)
		page_start_dply = page_start_dply.Replace(" ", "")
        page_end_dply   = str(page_end)
        page_end_dply   = page_end_dply.Replace(" ", "")
        albumpages.Push({Title: "Media Page "+str(i), ShortDescriptionLine1: title, ShortDescriptionLine2: "Items: "+page_start_dply+" thru "+page_end_dply, HDPosterUrl: thumb, SDPosterUrl: thumb})
    end for
	
    return albumpages
End Function

Function album_get_images(album As Object, startIndex=1 as Integer)

    oa = Oauth()
	
	start = str(startIndex)
	start = start.Replace(" ", "")

    rsp=m.googlephotos.ExecServerAPI("/albumid/"+album.GetID()+"?start-index="+start+"&max-results=1000kind=photo&v=3.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax="+googlephotos_get_resolution(),album.GetUsername(),oa.accessTokenIndex())
    print "GooglePhotos StartIndex: "; start
	print "GooglePhotos Res: "; googlephotos_get_resolution()
    if not isxmlelement(rsp) then 
        return invalid
    end if
	
    return googlephotos_new_image_list(rsp.entry)
End Function

Sub googlephotos_display_album(album As Object, index=0 As Integer)

    print "DisplayAlbum: init"
	
    title      = album.GetTitle()
    totalPages = ceiling(album.GetImageCount() / 1000)
    screen     = uitkPreShowPosterMenu(1, title,"Album")
	
    startIndex = 1
    if index > 0 then startIndex=(index*1000)+1
    medialist=album_get_images(album, startIndex)
    
    videos=[]
    images=[]
    for each media in medialist
        if media.IsVideo() then
            videos.Push(media)
            'print "VIDEO: "; media.GetURL()
        else
            images.Push(media)
            'print "IMAGE: "; media.GetURL()
        end if
    end for
    
   pagesShow  = ""
   if totalPages > 1 then
       currentPage = str(index + 1)
       currentPage = currentPage.Replace(" ", "")
       totalPages  = str(totalPages)
       totalPages  = totalPages.Replace(" ", "")
       pagesShow   = "Page "+currentPage+" of "+totalPages
    end if
    
    if videos.Count()>0 then        
        if images.Count()>0 then 'Combined photo and photo album
            listIcon="pkg:/images/browse.png"
            
            albummenudata = [
                {ShortDescriptionLine1:Pluralize(images.Count(),"Photo") + " - Start Slideshow",
                 ShortDescriptionLine2:pagesShow,
                 HDPosterUrl:images[0].GetThumb(),
                 SDPosterUrl:images[0].GetThumb()},
                {ShortDescriptionLine1:Pluralize(videos.Count(),"Video"),
                 HDPosterUrl:videos[0].GetThumb(),
                 SDPosterUrl:videos[0].GetThumb()},
                {ShortDescriptionLine1:"Browse Photos",
                 HDPosterUrl:listIcon,
                 SDPosterUrl:listIcon},
            ]
            
            onselect = [1, [images, videos], title, album_select]
            uitkDoPosterMenu(albummenudata, screen, onselect)
        else 'Video only album
            googlephotos_browse_videos(videos, title)
        end if
    else 'Photo only album			
            listIcon="pkg:/images/browse.png"
			
            albummenudata = [
                {ShortDescriptionLine1:Pluralize(images.Count(),"Photo") + " - Start Slideshow",
                 ShortDescriptionLine2:pagesShow,
                 HDPosterUrl:images[0].GetThumb(),
                 SDPosterUrl:images[0].GetThumb()},
                {ShortDescriptionLine1:"Browse Photos",
                 HDPosterUrl:listIcon,
                 SDPosterUrl:listIcon},
            ]
            
            onselect = [1, [images, videos], title, album_play_browse_select]
            uitkDoPosterMenu(albummenudata, screen, onselect)				
    end if
End Sub

Sub googlephotos_browse_pages(album As Object)
    screen=CreateObject("roListScreen")
    screen.SetContent(googlephotos_get_album_pages(album))
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetBreadcrumbText("Select Page", "Album")
    screen.show()
	
    while(true)
        msg = wait(0,port)
        if msg.isScreenClosed() then 'ScreenClosed event
            exit while
        else if (type(msg) = "roListScreenEvent")
            if(msg.isListItemSelected())
				googlephotos_display_album(album, msg.GetIndex())
            endif
        endif
    end while
End Sub

Sub googlephotos_album_pages(album As Object)
    if album.GetImageCount() > 1000 then
        lastPopup = RegRead("ThousandPopup","Settings")
        if lastPopup=invalid then googlephotos_thousandpopup()
	    googlephotos_browse_pages(album)
	else
        googlephotos_display_album(album)
	end if
End Sub

Sub album_select(media, title, set_idx)
    if set_idx=0 then
        DisplayImageSet(media[0], title, 0, googlephotos_get_slideshow_speed())
		
    else if set_idx=1 then
        googlephotos_browse_videos(media[1], title)
		
	else if set_idx=2 then
	    BrowseImages(media[0], title)
    end if
End Sub

Sub album_play_browse_select(media, title, set_idx)
    if set_idx=0 then 
        DisplayImageSet(media[0], title, 0, googlephotos_get_slideshow_speed()) 
    else if set_idx=1 then
        BrowseImages(media[0], title)
    end if
End Sub


' ********************************************************************
' ********************************************************************
' ***** Search Functions
' ********************************************************************
' ********************************************************************

Sub googlephotos_user_search(username="default", nickname=invalid)

    oa = Oauth()
    userIndex = oa.accessTokenIndex()

    port=CreateObject("roMessagePort") 
    screen=CreateObject("roSearchScreen")
	screen.SetBreadcrumbText(oa.userInfoName[userIndex], "Search")
    screen.SetMessagePort(port)
    
    history=CreateObject("roSearchHistory")
    screen.SetSearchTerms(history.GetAsArray())
    
    screen.Show()
    
    while true
        msg = wait(0, port)
        
        if type(msg) = "roSearchScreenEvent" then
            print "Event: "; msg.GetType(); " msg: "; msg.GetMessage()
            if msg.isScreenClosed() then
                return
            else if msg.isFullResult()
                keyword=msg.GetMessage()
                dialog=ShowPleaseWait("Please wait","Searching your albums for '" + keyword + "'")
				rsp=m.ExecServerAPI("?kind=photo&v=3.0&q="+keyword+"&max-results=1000&thumbsize=220&imgmax=" + googlephotos_get_resolution(),username,userIndex)
                images=googlephotos_new_image_list(rsp.entry)
                dialog.Close()
                if images.Count()>0 then
                    history.Push(keyword)
                    screen.AddSearchTerm(keyword)
					screen.Close()
					
					screen=uitkPreShowPosterMenu(1, oa.userInfoName[userIndex],"Search Results")
					listIcon="pkg:/images/browse.png"
					searchIcon="pkg:/images/search.png"

					' It's unclear what the limit is, only it's around 1000
					additional=""
					if images.Count()>900 then additional="Search results reached Googles limit"
					albummenudata = [
						{ShortDescriptionLine1:Pluralize(images.Count(),"Photo") + " - Start Slideshow", ShortDescriptionLine2:additional, HDPosterUrl:images[0].GetThumb(), SDPosterUrl:images[0].GetThumb()},
						{ShortDescriptionLine1:"Browse Photos", HDPosterUrl:listIcon, SDPosterUrl:listIcon},
					]
            
					onselect = [1, [images, videos], "Search Results", album_play_browse_select]
					uitkDoPosterMenu(albummenudata, screen, onselect)						
					
                else
                    ShowErrorDialog("No images match your search","Search results")
                end if
            else if msg.isCleared() then
                history.Clear()
            end if
        end if
    end while
End Sub


' ********************************************************************
' ********************************************************************
' ***** Images Functions
' ********************************************************************
' ********************************************************************

Function googlephotos_new_image_list(xmllist As Object) As Object
    images=CreateObject("roList")
    for each record in xmllist
        image=googlephotos_new_image(record)
        if image.GetURL()<>invalid then
            images.Push(image)
        end if
    next
    
    return images
End Function

Function googlephotos_new_image(xml As Object) As Object
    image = CreateObject("roAssociativeArray")
    image.xml=xml
    image.GetTitle=function():return m.xml.GetNamedElements("title")[0].GetText():end function
    image.GetID=function():return m.xml.GetNamedElements("gphoto:id")[0].GetText():end function
    image.GetURL=image_get_url
    image.GetThumb=get_thumb
    image.GetTimestamp=function():return Left(m.xml.GetNamedElements("gphoto:timestamp")[0].GetText(), 10):end function
    image.IsVideo=function():return (m.xml.GetNamedElements("gphoto:videostatus")[0]<>invalid):end function
    image.GetVideoStatus=function():return m.xml.GetNamedElements("gphoto:videostatus")[0].GetText():end function
    return image
End Function

Function image_get_url()
    images=m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:content")
    if m.IsVideo() then
        if m.GetVideoStatus()="final" or m.GetVideoStatus()="ready" then
            for each image in images
                if image.GetAttributes()["type"]="video/mpeg4" then
                    return image.GetAttributes()["url"]
                end if
            end for
        end if
    else
        if images[0]<>invalid then
            return images[0].GetAttributes()["url"]
        end if
    end if
    
    return invalid
End Function

Function images_get_meta(images As Object)
    imagemetadata=[]
    for each image in images
        imagemetadata.Push({Title: image.GetTitle(), Description: "  " + friendlyDate(strtoi(image.GetTimestamp())), HDPosterUrl: image.GetThumb(), SDPosterUrl: image.GetThumb()})
    next
    return imagemetadata
End Function

Function get_thumb()
    if m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail").Count()>0 then
        return m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail")[0].GetAttributes()["url"]
    end if
    
    return "pkg:/images/icon_s.png"
End Function


' ********************************************************************
' ********************************************************************
' ***** Random Slideshow Functions
' ********************************************************************
' ********************************************************************
Sub googlephotos_random_photos(username="default")

    oa = Oauth()
    userIndex = oa.accessTokenIndex()

    screen=uitkPreShowPosterMenu(1, oa.userInfoName[userIndex],"Shuffle Photos")
    
    rsp=m.ExecServerAPI("?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))",username,userIndex)
    if not isxmlelement(rsp) then return
    albums=m.newAlbumListFromXML(rsp.entry)
    
    if albums.Count()=0 then
        uitkDoMessage("You have no albums containing any photos", screen)
    else
        ss=PrepDisplaySlideShow()
        screen.Close()
        ss.SetPeriod(googlephotos_get_slideshow_speed())
        port=ss.GetMessagePort()
        
        image_univ=[]
        for i=0 to albums.Count()-1
            image_count=albums[i].GetImageCount()
            for j=0 to image_count-1
                image_univ.Push([i,j])
            end for
        end for
        
        album_cache={}
        album_skip={}
        while true
            next_image:
            'Select image from total universe
            selected_idx=Rnd(image_univ.Count())-1
            
            'Caching image lookup results, saves us some API calls
            album_idx=image_univ[selected_idx][0]
            
            'Skip if passworded
            if album_skip.DoesExist(itostr(album_idx)) then goto next_image
            
            if album_cache.DoesExist(itostr(album_idx)) then
                imagelist=album_cache.Lookup(itostr(album_idx))
            else
                imagelist=album_get_images(albums[album_idx])
                if imagelist=invalid then 
                    album_skip.AddReplace(itostr(album_idx),1)
                    goto next_image
                end if
                album_cache.AddReplace(itostr(album_idx), imagelist)
            end if
            
            image_idx=image_univ[selected_idx][1]
            image=imagelist[image_idx]
            
            if image<>invalid then
                image.Info={}
                image.Info.TextOverlayUL="Album: "+albums[album_idx].GetTitle()
                
                imagelist=[image]
                
                AddNextimageToSlideShow(ss, imagelist, 0)
                while true
                    msg = port.GetMessage()
                    if msg=invalid then exit while
                    if ProcessSlideShowEvent(ss, msg, imagelist) then return
                end while
                
                'Sleeping for Slideshow Duration - 2.5 seconds
                sleep((googlephotos_get_slideshow_speed()-2.5)*1000)
            end if
        end while
    end if
End Sub

Sub BrowseImages(images AS Object, title="" As String)
    screen=uitkPreShowGrid(title,"Photos")
    
    while true
        selected=uitkDoGrid(images_get_meta(images), screen)
        if selected>-1 then
            DisplayImageSet(images, title, selected, googlephotos_get_slideshow_speed())
        else
            return
        end if
    end while
End Sub


' ********************************************************************
' ********************************************************************
' ***** Videos Functions
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse_videos(videos As Object, title As String)
    if videos.Count()=1 then
        DisplayVideo(GetVideoMetaData(videos)[0])
    else
        screen=uitkPreShowPosterMenu(1, title,"Videos")
        metadata=GetVideoMetaData(videos)
        
        onselect = [1, metadata, m, function(video, googlephotos, set_idx):DisplayVideo(video[set_idx]):end function]
        uitkDoPosterMenu(metadata, screen, onselect)
    end if
End Sub

Function GetVideoMetaData(videos As Object)
    metadata=[]
    
    res=[480]
    bitrates=[1000]
    qualities=["SD"]
    
    for each video in videos
        meta=CreateObject("roAssociativeArray")
        meta.ContentType="movie"
        meta.Title=video.GetTitle()
        meta.ShortDescriptionLine1=meta.Title
        meta.SDPosterUrl=video.GetThumb()
        meta.HDPosterUrl=video.GetThumb()
        meta.StreamBitrates=bitrates
        meta.StreamQualities=qualities
        meta.StreamFormat="mp4"
        
        meta.StreamBitrates=[]
        meta.StreamQualities=[]
        meta.StreamUrls=[]
        for i=0 to res.Count()-1
            url=video.GetURL()
            if url<>invalid then
                meta.StreamUrls.Push(url)
                meta.StreamBitrates.Push(bitrates[i])
                meta.StreamQualities.Push(qualities[i])
                if res[i]>960 then
                    meta.IsHD=True
                    meta.HDBranded=True
                end if
            end if
        end for
        
        metadata.Push(meta)
    end for
    
    return metadata
End Function

Function DisplayVideo(content As Object)
    print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    video.InitClientCertificates()
    video.SetContent(content)
    video.show()
    
    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                video.Close()
                exit while
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
End Function
