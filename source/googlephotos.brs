
Function LoadGooglePhotos() As Object
    ' global singleton
    return m.googlephotos
End Function

Function InitGooglePhotos() As Object
    ' constructor
    this = CreateObject("roAssociativeArray")
    this.scope = "https://picasaweb.google.com/data"
    this.prefix = this.scope + "/feed/api"
    
    this.ExecServerAPI = googlephotos_exec_api
    
    'GooglePhotos
    this.BrowseGooglePhotos = googlephotos_browse
    this.BrowseFeatured = googlephotos_featured
    this.PhotoSearch = googlephotos_photo_search
    
    'Search
    this.SearchAlbums = googlephotos_user_search
	
    'Album
    this.BrowseAlbums = googlephotos_browse_albums
    this.newAlbumListFromXML = googlephotos_new_album_list
    this.newAlbumFromXML = googlephotos_new_album
    this.getAlbumMetaData = googlephotos_get_album_meta
    this.DisplayAlbum = googlephotos_display_album

    'Tags
    this.BrowseTags = googlephotos_browse_tags
    this.newTagListFromXML = googlephotos_new_tag_list
    this.newTagFromXML = googlephotos_new_tag
    
    'Favorites
    this.BrowseFavorites = googlephotos_browse_favorites
    this.DisplayFavorites = googlephotos_display_favorites
    this.newFavListFromXML = googlephotos_new_fav_list
    this.getFavMetaData = googlephotos_get_fav_meta
    
    'Video
    this.BrowseVideos = googlephotos_browse_videos
    
    this.ShufflePhotos = googlephotos_random_photos
    this.BrowseSettings = googlephotos_browse_settings

    this.SlideshowSpeed = googlephotos_set_slideshow_speed
    this.DelinkPlayer = googlephotos_delink
    this.About = googlephotos_about
 
    'Set Slideshow Duration
    ssdur=RegRead("SlideshowDelay","Settings")
    if ssdur=invalid then
        this.SlideshowDuration=3
    else
        this.SlideshowDuration=Val(ssdur)
    end if   
    
    print "GooglePhotos: init complete"

    return this
End Function


Function googlephotos_exec_api(url_stub="" As String, username="default" As Dynamic)
	print "googlephotos_exec_api - enter"
	
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
        oa.sign(http,true)
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
' ***** GooglePhotos
' ***** GooglePhotos
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse()
    screen=uitkPreShowPosterMenu()

    highlights=m.highlights
    
    menudata=[
        {ShortDescriptionLine1:"Featured", DescriptionLine2:"What's featured now on Google Photos", HDPosterUrl:highlights[2], SDPosterUrl:highlights[2]},
        {ShortDescriptionLine1:"Community Search", ShortDescriptionLine2:"Search community photos", HDPosterUrl:highlights[3], SDPosterUrl:highlights[3]},
    ]
    onselect=[0, m, "BrowseFeatured","PhotoSearch"]
    
    uitkDoPosterMenu(menudata, screen, onselect)  

End Sub

Sub googlephotos_featured()
    rsp=m.ExecServerAPI("featured?max-results=200&v=2.0&fields=entry(title,gphoto:id,media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax=" + GetResolution(),invalid)
    if rsp<>invalid then
        featured=googlephotos_new_image_list(rsp.entry)
        DisplayImageSet(featured, "Featured", 0, m.SlideshowDuration)
    end if
End Sub

Sub googlephotos_photo_search()
    port=CreateObject("roMessagePort") 
    screen=CreateObject("roSearchScreen")
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
                dialog=ShowPleaseWait("Please wait","Searching community images for "+keyword)
                rsp=m.ExecServerAPI("all?kind=photo&q="+keyword+"&max-results=200",invalid)
                images=googlephotos_new_image_list(rsp.entry)
                dialog.Close()
                if images.Count()>0 then
                    history.Push(keyword)
                    screen.AddSearchTerm(keyword)
                    DisplayImageSet(images, keyword, 0, m.SlideshowDuration)
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
' ***** Albums
' ***** Albums
' ********************************************************************
' ********************************************************************

Sub googlephotos_browse_albums(username="default", nickname=invalid)    
    breadcrumb_name=""
    if username<>"default" and nickname<>invalid then
        breadcrumb_name=nickname
    end if
    screen=uitkPreShowPosterMenu(breadcrumb_name,"My Albums")
    
    rsp=m.ExecServerAPI("?kind=album&v=2.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))",username)
    if not isxmlelement(rsp) then return
    albums=m.newAlbumListFromXML(rsp.entry)
    
    if albums.Count()>0 then
        onselect = [1, albums, m, function(albums, googlephotos, set_idx):googlephotos.DisplayAlbum(albums[set_idx]):end function]
        uitkDoPosterMenu(googlephotos_get_album_meta(albums), screen, onselect)
    else
        uitkDoMessage("You have no albums containing any photos", screen)
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
    album.GetImages=album_get_images
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

Function album_get_images()
    rsp=m.googlephotos.ExecServerAPI("/albumid/"+m.GetID()+"?kind=photo&v=2.0&fields=entry(title,gphoto:timestamp,gphoto:id,gphoto:videostatus,media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax="+GetResolution(),m.GetUsername())
    print "GooglePhotos Res: " + GetResolution()
    if not isxmlelement(rsp) then 
        return invalid
    end if
	
    return googlephotos_new_image_list(rsp.entry)
End Function

Sub googlephotos_display_album(album As Object)
    print "DisplayAlbum: init"
    medialist=album.GetImages()
    
    videos=[]
    images=[]
    for each media in medialist
        if media.IsVideo() then
            videos.Push(media)
            print "VIDEO: "; media.GetURL()
        else
            images.Push(media)
            print "IMAGE: "; media.GetURL()
        end if
    end for
    
    title=album.GetTitle()
    
    if videos.Count()>0 then        
        if images.Count()>0 then 'Combined photo and photo album
            screen=uitkPreShowPosterMenu(title,"Album")
            
            albummenudata = [
                {ShortDescriptionLine1:Pluralize(images.Count(),"Photo"),
                 HDPosterUrl:images[0].GetThumb(),
                 SDPosterUrl:images[0].GetThumb()},
                {ShortDescriptionLine1:Pluralize(videos.Count(),"Video"),
                 HDPosterUrl:videos[0].GetThumb(),
                 SDPosterUrl:videos[0].GetThumb()},
            ]
            
            onselect = [1, [images, videos], title, album_select]
            uitkDoPosterMenu(albummenudata, screen, onselect)
        else 'Video only album
            googlephotos_browse_videos(videos, title)
        end if
    else 'Photo only album			
            screen=uitkPreShowPosterMenu(title,"Album")
            listIcon="pkg:/images/browse.png"
			
            albummenudata = [
                {ShortDescriptionLine1:Pluralize(images.Count(),"Photo") + " - Start Slideshow",
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

Sub album_select(media, title, set_idx)
    if set_idx=0 then
        'DisplayImageSet(media[0], title, 0, m.googlephotos.SlideshowDuration)
		
		screen=uitkPreShowPosterMenu(title,"Album")
        listIcon="pkg:/images/browse.png"
			
        albummenudata = [
            {ShortDescriptionLine1:Pluralize(media[0].Count(),"Photo") + " - Start Slideshow",
             HDPosterUrl:media[0][0].GetThumb(),
             SDPosterUrl:media[0][0].GetThumb()},
            {ShortDescriptionLine1:"Browse Photos",
             HDPosterUrl:listIcon,
             SDPosterUrl:listIcon},
       ]
            
        onselect = [1, [media[0], media[1]], title, album_play_browse_select]
        uitkDoPosterMenu(albummenudata, screen, onselect)				

    else 
        googlephotos_browse_videos(media[1], title)
    end if
End Sub

Sub album_play_browse_select(media, title, set_idx)
    if set_idx=0 then 
        DisplayImageSet(media[0], title, 0, m.googlephotos.SlideshowDuration) 
    else 
        BrowseImages(media[0], title)
    end if
End Sub

Sub googlephotos_user_search(username="default", nickname=invalid)
    port=CreateObject("roMessagePort") 
    screen=CreateObject("roSearchScreen")
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
				rsp=m.ExecServerAPI("?kind=photo&v=2.0&q="+keyword+"&max-results=200&thumbsize=220&imgmax=" + GetResolution(),username)
                images=googlephotos_new_image_list(rsp.entry)
                dialog.Close()
                if images.Count()>0 then
                    history.Push(keyword)
                    screen.AddSearchTerm(keyword)
                    'DisplayImageSet(images, keyword, 0, m.SlideshowDuration)
					screen.Close()
					
					screen=uitkPreShowPosterMenu("","Search Results")
					listIcon="pkg:/images/browse.png"
			
					albummenudata = [
						{ShortDescriptionLine1:Pluralize(images.Count(),"Photo") + " - Start Slideshow",
						 HDPosterUrl:images[0].GetThumb(),
						 SDPosterUrl:images[0].GetThumb()},
						{ShortDescriptionLine1:"Browse Photos",
						 HDPosterUrl:listIcon,
						 SDPosterUrl:listIcon},
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
' ***** Tags
' ***** Tags
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse_tags(username="default", nickname=invalid)    
    breadcrumb_name=""
    if username<>"default" and nickname<>invalid then
        breadcrumb_name=nickname
    end if
    
    screen=uitkPreShowPosterMenu(breadcrumb_name,"Tags")
    
    rsp=m.ExecServerAPI("?kind=tag&v=2.0&fields=entry(title)",username)
    if not isxmlelement(rsp) then return
    tags=m.newTagListFromXML(rsp.entry, username)
    
    if tags.Count()>0 then
        onselect = [1, tags, m, function(tags, googlephotos, set_idx):googlephotos.DisplayAlbum(tags[set_idx]):end function]
        uitkDoPosterMenu(googlephotos_get_album_meta(tags), screen, onselect)
    else
        uitkDoMessage("No photos have been tagged", screen)
    end if
End Sub

Function googlephotos_new_tag_list(xmllist As Object, username) As Object
    taglist=CreateObject("roList")
    for each record in xmllist
        tag=m.newTagFromXML(record, username)
	print "Tags: "; tag
        taglist.Push(tag)
    next
    
    return taglist
End Function

Function googlephotos_new_tag(xml As Object, username) As Object
    tag = CreateObject("roAssociativeArray")
    tag.googlephotos=m
    tag.xml=xml
    tag.username=username
    tag.GetUsername=function():return m.username:end function
    tag.GetTitle=function():return m.xml.title[0].GetText():end function
    tag.GetThumb=function():return "pkg:/images/icon_s.png":end function
    tag.GetImages=tag_get_images
    return tag
End Function

Function tag_get_images()
    rsp=m.googlephotos.ExecServerAPI("?kind=photo&tag="+m.GetTitle()+"&thumbsize=220&imgmax=" + GetResolution(),m.GetUsername())
    if not isxmlelement(rsp) then 
        return invalid
    end if
    
    return googlephotos_new_image_list(rsp.entry)
End Function

' ********************************************************************
' ********************************************************************
' ***** Images
' ***** Images
' ********************************************************************
' ********************************************************************

Function GetResolution()
    ssres = RegRead("SlideshowRes","Settings")

    if ssres=invalid then
        device = createObject("roDeviceInfo")
        is4k = (val(device.GetVideoMode()) = 2160)
        is1080p = (val(device.GetVideoMode()) = 1080)

        if is4k then
            res="1600"
        else if is1080p
            res="1280"
        else
            res="720"
        end if
    else
        if ssres="FHD" then
            res="1600"
        else if ssres="HD"
            res="1280"
        else
            res="720"
        end if
    end if

    return res
End Function

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
        imagemetadata.Push({Title: image.GetTitle(), Description: friendlyDate(strtoi(image.GetTimestamp())), HDPosterUrl: image.GetThumb(), SDPosterUrl: image.GetThumb()})
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
' ***** Favorites
' ***** Favorites
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse_favorites(username="default", nickname=invalid)
    breadcrumb_name=""
    if username<>"default" and nickname<>invalid then
        breadcrumb_name=nickname
    end if
    
    screen=uitkPreShowPosterMenu(breadcrumb_name,"Favorites")
    
    rsp=m.ExecServerAPI("/contacts?kind=user",username)
    if not isxmlelement(rsp) then return
    favs=googlephotos_new_fav_list(rsp.entry)
    
    if favs.Count() > 0 then
        onselect = [1, favs, m, function(ff, googlephotos, set_idx):googlephotos.DisplayFavorites(ff[set_idx]):end function]
        uitkDoPosterMenu(m.getFavMetaData(favs), screen, onselect)
    else
        uitkDoMessage("You do not have any favorites", screen)
    end if
End Sub

Sub googlephotos_display_favorites(fav As Object)
    user=fav.GetUser()
    nickname=fav.GetNickname()
    
    screen=uitkPreShowPosterMenu("",nickname)
    
    'Get highlights from recent photo feed
    highlights=[]
    rsp=m.ExecServerAPI("?kind=photo&max-results=5&v=2.0&fields=entry(media:group(media:description,media:content,media:thumbnail))&thumbsize=220&imgmax=" + GetResolution(),user)
    if isxmlelement(rsp) then 
        images=googlephotos_new_image_list(rsp.entry)
        for each image in images
            highlights.Push(image.GetThumb())
        end for
    end if
    
    for i=0 to 3
        if highlights[i]=invalid then
            highlights[i]="pkg:/images/icon_s.png"
        end if
    end for
    
    menudata = [
        {ShortDescriptionLine1:"Albums", ShortDescriptionLine2:"Browse Recently Updated Albums", HDPosterUrl:highlights[0], SDPosterUrl:highlights[0]},
        {ShortDescriptionLine1:"Tags", ShortDescriptionLine2:"Browse Tags", HDPosterUrl:highlights[1], SDPosterUrl:highlights[1]},
        {ShortDescriptionLine1:"Favorites", ShortDescriptionLine2:"Browse Favorites", HDPosterUrl:highlights[2], SDPosterUrl:highlights[2]},
        {ShortDescriptionLine1:"Shuffle Photos", ShortDescriptionLine2:"Display slideshow of random photos", HDPosterUrl:highlights[3], SDPosterUrl:highlights[3]},
    ]
    
    onclick=[0, m, ["BrowseAlbums", user, nickname], ["BrowseTags", user, nickname], ["BrowseFavorites", user, nickname], ["ShufflePhotos", user]]
    
    uitkDoPosterMenu(menudata, screen, onclick)
End Sub

Function googlephotos_new_fav_list(xmllist As Object)
    favs=[]
    for each record in xmllist
        fav = CreateObject("roAssociativeArray")
        fav.xml=record
        fav.GetUser=function():return m.xml.GetNamedElements("gphoto:user")[0].GetText():end function
        fav.GetNickname=function():return m.xml.GetNamedElements("gphoto:nickname")[0].GetText():end function
        fav.GetThumb=function():return m.xml.GetNamedElements("gphoto:thumbnail")[0].GetText():end function
        fav.GetURL=function():return m.xml.author.uri[0].GetText():end function
        favs.Push(fav)
    end for
    
    return favs
End Function

Function googlephotos_get_fav_meta(fav As Object)
    favmetadata=[]
    for each f in fav
        favmetadata.Push({ShortDescriptionLine1: f.GetNickname(), ShortDescriptionLine2: f.GetURL(), HDPosterUrl: f.GetThumb(), SDPosterUrl: f.GetThumb()})
    next
    
    return favmetadata
End Function

' ********************************************************************
' ********************************************************************
' ***** Random Slideshow
' ***** Random Slideshow
' ********************************************************************
' ********************************************************************
Sub googlephotos_random_photos(username="default")
    screen=uitkPreShowPosterMenu("","Shuffle Photos")
    
    rsp=m.ExecServerAPI("?kind=album&v=2.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))",username)
    if not isxmlelement(rsp) then return
    albums=m.newAlbumListFromXML(rsp.entry)
    
    if albums.Count()=0 then
        uitkDoMessage("You have no albums containing any photos", screen)
    else
        ss=PrepDisplaySlideShow()
        screen.Close()
        ss.SetPeriod(m.SlideshowDuration)
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
                imagelist=albums[album_idx].GetImages()
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
                sleep((m.SlideshowDuration-2.5)*1000)
            end if
        end while
    end if
End Sub

Sub BrowseImages(images AS Object, title="" As String)
    screen=uitkPreShowGrid(title,"Photos")
    
    while true
        selected=uitkDoGrid(images_get_meta(images), screen)
        if selected>-1 then
            DisplayImageSet(images, title, selected, m.googlephotos.SlideshowDuration)
        else
            return
        end if
    end while
End Sub

' ********************************************************************
' ********************************************************************
' ***** Videos
' ***** Videos
' ********************************************************************
' ********************************************************************
Sub googlephotos_browse_videos(videos As Object, title As String)
    if videos.Count()=1 then
        DisplayVideo(GetVideoMetaData(videos)[0])
    else
        screen=uitkPreShowPosterMenu(title,"Videos")
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
