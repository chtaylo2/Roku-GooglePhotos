Sub RunScreensaver()
    screen=CreateObject("roSGScreen")
    photo=CreateObject("roAssociativeArray")
    port=CreateObject("roMessagePort")
    port2=CreateObject("roMessagePort")
    device=CreateObject("roDeviceInfo")
    ds=device.GetDisplaySize()
    
    Init()
    REM oa = Oauth()
    REM googlephotos = LoadGooglePhotos()
    
    ssUser=RegRead("SSaverUser","Settings")
    userIndex=0
    if ssUser=invalid then		
        userIndex=0
    else if ssUser="All (Random)" then
        userIndex=100
    else
        userCount=m.oa.count()
        for i = 0 to userCount-1
            if m.oa.userInfoEmail[i] = ssUser then userIndex = i
        end for
    end if
    
    ssMethodAvailable=["Multi-Scrolling Photos", "Fading Photo - Large", "Fading Photo - Small"]
    ssMethod=RegRead("SSaverMethod","Settings")
    if ssMethod=invalid then		
        ssMethodSel=ssMethodAvailable[0]
    else if ssMethod="Random" then
        ssMethodSel=ssMethodAvailable[Rnd(ssMethodAvailable.Count())-1]
    else
        ssMethodSel=ssMethod			
    end if
    
    photoItems=[]
    if not m.oa.linked() then
        rsp="invalid"
    else
    
    
        if (ssMethodSel="Fading Photo - Large" or ssMethodSel="Fading Photo - Small") then
           ' Fading Screensaver
            screen.setMessagePort(port)
            scene = screen.createScene("compPhotoFade")  
            screen.show()    
        else
            ' Multi-Scrolling Screensaver
            screen.setMessagePort(port)
            scene = screen.createScene("compPhotoScroll") 
            screen.show()        
        end if
        
        'If userIndex is set to 100, means user wants random photos from each linked account shown. 
        if userIndex=100 then
            userCount=m.oa.count()
            for i = 0 to userCount-1
                rsp=m.googlephotos.ExecServerAPI("?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))","default",i)
    
                album_cache_count=0
                albums=googlephotos_new_album_list(rsp.entry)
                if albums.Count()>0 then
                    for each album in albums

                        if album_cache_count = 0 and album.GetImageCount()>0 then
                            ' We will always pull node 0 as this is Auto Backup, likely contains most photos
                            album_idx=0
                        else
                            ' Randomly pull 5 additional albums and cache photos
                            album_idx=Rnd(albums.Count())-1
                        end if
                        
                        album_cache_count=album_cache_count+1
                        
                        imagelist=album_get_images(albums[album_idx])
                        albums.delete(album_idx)
                    
                        for each image in imagelist
                            if image.GetURL().instr(".MOV") <> -1 Or image.GetURL().instr(".mp4") <> -1 then
                                print "Ignore: "; image.GetURL()
                            else
                                print "Push: "; image.GetURL()
                                photoItems.Push(image.GetURL())
                            end if    
                        end for
                        
                        if album_cache_count>=5
                            exit for
                        end if
                        
                    end for
                end if
            end for
        else
            rsp=m.googlephotos.ExecServerAPI("?kind=album&v=3.0&fields=entry(title,gphoto:numphotos,gphoto:user,gphoto:id,media:group(media:description,media:thumbnail))",username,userIndex)

            album_cache_count=0
            albums=googlephotos_new_album_list(rsp.entry)
            if albums.Count()>0 then
                for each album in albums
                    if album_cache_count = 0 and album.GetImageCount()>0 then
                        ' We will always pull node 0 as this is Auto Backup, likely contains most photos
                        album_idx=0
                    else
                        ' Randomly pull 5 additional albums and cache photos
                        album_idx=Rnd(albums.Count())-1
                    end if
                    
                    album_cache_count=album_cache_count+1
                    
                    imagelist=album_get_images(albums[album_idx])
                    albums.delete(album_idx)
                
                    for each image in imagelist
                        if image.GetURL().instr(".MOV") <> -1 Or image.GetURL().instr(".mp4") <> -1 then
                            print "Ignore: "; image.GetURL()
                        else
                            print "Push: "; image.GetURL()
                            photoItems.Push(image.GetURL())
                        end if    
                    end for
                    
                    if album_cache_count>=5
                        exit for
                    end if
                    
                end for
            end if
        end if
    end if

    'If unlinked, we'll advertise our channel! ..And a couple Easter Eggs are always cool :-) 
    if photoItems.count() = 0 then
        photoItems.Push("pkg:/images/screensaver_splash.png")
        photoItems.Push("pkg:/images/screensaver_splash.png")
        photoItems.Push("pkg:/images/cat_pic_1.jpg")
        photoItems.Push("pkg:/images/cat_pic_2.jpg")
    end if

    photo.GetNext=function(photoItems):return Rnd(photoItems.Count())-1:end function
    
    print "Display method selected: "; ssMethodSel
    
    multiplier = 1
    if ds.w = 1920 then
        print "FHD detected"
        multiplier = 1.5
    end if

    
    if (ssMethodSel="Fading Photo - Large" or ssMethodSel="Fading Photo - Small") then
        
        if (ssMethodSel="Fading Photo - Large") then
            'Full Screen Mode
            tmpWidth = ds.w / 2
            tmpHeight = ds.h / 2
            scene.primaryImageWidth = ds.w
            scene.primaryImageHeight = ds.h
            scene.layoutGrouphorizAlignment = "center"
            scene.layoutGroupvertAlignment = "center"
        else
            'Small Photo Mode
            tmpWidth = Rnd(ds.w-(400*multiplier))
            tmpHeight = Rnd(ds.h-(400*multiplier))
            scene.primaryImageWidth = 400*multiplier
            scene.primaryImageHeight = 400*multiplier
            scene.layoutGrouphorizAlignment = "left"
            scene.layoutGroupvertAlignment = "left"
        end if
        
        tmpTranslation = []
        tmpTranslation.Push(tmpWidth)
        tmpTranslation.Push(tmpHeight)
        scene.layoutGroupTranslation = tmpTranslation
        
        scene.primaryImageUri=photoItems[photo.GetNext(photoItems)]

        scene.loadingvisible="false"
        
        while(true)
            msg = wait(12000, port)
            if (msg <> invalid)
                msgType = type(msg)
                if msgType = "roSGScreenEvent"
                    if msg.isScreenClosed() then return
                end if
            else
                scene.controlFade="start"
                'Pause for 2.5 seconds, then load new image.
                msg = wait(2500, port2)
                scene.primaryImageUri=photoItems[photo.GetNext(photoItems)]
                if (ssMethodSel="Fading Photo - Small") then
                    tmpTranslation = []
                    tmpTranslation.Push(Rnd(ds.w-(400*multiplier)))
                    tmpTranslation.Push(Rnd(ds.h-(400*multiplier)))
                    scene.layoutGroupTranslation = tmpTranslation
                end if
            end if
        end while

    else

        ' Initial photo loads
        scene.image1Uri=photoItems[photo.GetNext(photoItems)]
        scene.image5Uri=photoItems[photo.GetNext(photoItems)]
        scene.image6Uri=photoItems[photo.GetNext(photoItems)]
        scene.image4Uri=photoItems[photo.GetNext(photoItems)]
        scene.image8Uri=photoItems[photo.GetNext(photoItems)]
        scene.image2Uri=photoItems[photo.GetNext(photoItems)]
        scene.image3Uri=photoItems[photo.GetNext(photoItems)]
        scene.image7Uri=photoItems[photo.GetNext(photoItems)]
        
        scene.loadingtext="Completed. Enjoy!"
        
        ' Start the animiation
        scene.controlAnimate1="start"
        scene.controlAnimate5="start"
        
        sleep(1000)
        scene.loadingvisible="false"
        
        sleep(4000)
        scene.controlAnimate6="start"
        sleep(5000)
        scene.controlAnimate4="start"
        scene.controlAnimate8="start"
        sleep(5000)
        scene.controlAnimate2="start"
        scene.controlAnimate3="start"
        scene.controlAnimate7="start"



        'FHD Support
        endPoint=-400*multiplier

        'Need to find a way to concatenate variables to reduce this while loop.
        while(true)
            if (scene.image1translation[1] = endPoint) then
                scene.image1Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate1="start"
            end if
 
            if (scene.image2translation[1] = endPoint) then
                scene.image2Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate2="start"
            end if

            if (scene.image3translation[1] = endPoint) then
                scene.image3Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate3="start"
            end if
        
            if (scene.image4translation[1] = endPoint) then
                scene.image4Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate4="start"
            end if

            if (scene.image5translation[1] = endPoint) then
                scene.image5Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate5="start"
            end if

            if (scene.image6translation[1] = endPoint) then
                scene.image6Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate6="start"
            end if
            
            if (scene.image7translation[1] = endPoint) then
                scene.image7Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate7="start"
            end if
            
            if (scene.image8translation[1] = endPoint) then
                scene.image8Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate8="start"
            end if       
        end while
    end if
End Sub


Sub RunScreenSaverSettings()
    initTheme()
    Init()
    REM oa = Oauth()
    
    linked=m.oa.linked()
    userCount=m.oa.count()

    m.googlephotos.BrowseSSaverSettings()
End Sub
