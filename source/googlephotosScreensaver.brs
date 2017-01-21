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
        'userName="All (Random)"
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
    
    
    if not m.oa.linked() then
        rsp="invalid"
    else
        rsp=m.googlephotos.ExecServerAPI("?kind=photo&max-results=500&v=2.0&fields=entry(media:group(media:content))&imgmax="+m.googlephotos.GetResolution(),"default",userIndex)
    end if

    photoItems=[]
    if isxmlelement(rsp) then 
        images=googlephotos_new_image_list(rsp.entry)
        print "DEBUG "; image
        for each image in images
            if image.GetURL().instr(".MOV") <> -1 Or image.GetURL().instr(".mp4") <> -1 then
                print "Ignore: "; image.GetURL()
            else
                print "Push: "; image.GetURL()
                photoItems.Push(image.GetURL())
            end if    
        end for
    end if    

    'If unlinked, we'll advertise our channel! ..And a couple Easter Eggs are always cool :-) 
    if photoItems.count() = 0 then
        photoItems.Push("pkg:/images/mm_icon_focus_hd.png")
        photoItems.Push("pkg:/images/mm_icon_focus_hd.png")
        photoItems.Push("pkg:/images/cat_pic_1.jpg")
        photoItems.Push("pkg:/images/cat_pic_2.jpg")
    end if

    photo.GetNext=function(photoItems):return Rnd(photoItems.Count())-1:end function
    
    print "TEST: "; ssMethodSel
    
    if (ssMethodSel="Fading Photo - Large" or ssMethodSel="Fading Photo - Small") then
    
        ' Fading Screensaver
        screen.setMessagePort(port)
        scene = screen.createScene("compPhotoFade")  
        screen.show()
    
        if (ssMethodSel="Fading Photo - Large") then
            'Full Screen Mode
            tmpWidth = ds.w / 2
            tmpHeight = ds.h / 2
            scene.primaryImageWidth = ds.w
            scene.primaryImageHeight = ds.h
            scene.loyoutGrouphorizAlignment = "center"
            scene.loyoutGroupvertAlignment = "center"
        else
            'Small Photo Mode
            tmpWidth = Rnd(ds.w-400)
            tmpHeight = Rnd(ds.h-400)
            scene.primaryImageWidth = 400
            scene.primaryImageHeight = 400
            scene.loyoutGrouphorizAlignment = "left"
            scene.loyoutGroupvertAlignment = "left"
        end if
        
        tmpTranslation = []
        tmpTranslation.Push(tmpWidth)
        tmpTranslation.Push(tmpHeight)
        scene.loyoutGroupTranslation = tmpTranslation
        
        scene.primaryImageUri=photoItems[photo.GetNext(photoItems)]
        
        while(true)
            msg = wait(5000, port)
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
                    tmpTranslation.Push(Rnd(ds.w-400))
                    tmpTranslation.Push(Rnd(ds.h-400))
                    scene.loyoutGroupTranslation = tmpTranslation
                end if
            end if
        end while

    else
    
        ' Multi-Scrolling Screensaver
        screen.setMessagePort(port)
        scene = screen.createScene("compPhotoScroll")  
        screen.show()

        ' Initial photo loads
        scene.image1Uri=photoItems[photo.GetNext(photoItems)]
        scene.image5Uri=photoItems[photo.GetNext(photoItems)]
        scene.image6Uri=photoItems[photo.GetNext(photoItems)]
        scene.image4Uri=photoItems[photo.GetNext(photoItems)]
        scene.image8Uri=photoItems[photo.GetNext(photoItems)]
        scene.image2Uri=photoItems[photo.GetNext(photoItems)]
        scene.image3Uri=photoItems[photo.GetNext(photoItems)]
        scene.image7Uri=photoItems[photo.GetNext(photoItems)]    
    
        ' Start the animiation
        scene.controlAnimate1="start"
        scene.controlAnimate5="start"
        sleep(5000)
        scene.controlAnimate6="start"
        sleep(5000)
        scene.controlAnimate4="start"
        scene.controlAnimate8="start"
        sleep(5000)
        scene.controlAnimate2="start"
        scene.controlAnimate3="start"
        scene.controlAnimate7="start"

        'Need to find a way to concatenate variables to reduce this while loop.
        while(true)
            if (scene.image1translation[1] = -400) then
                scene.image1Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate1="start"
            end if
 
            if (scene.image2translation[1] = -400) then
                scene.image2Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate2="start"
            end if

            if (scene.image3translation[1] = -400) then
                scene.image3Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate3="start"
            end if
        
            if (scene.image4translation[1] = -400) then
                scene.image4Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate4="start"
            end if

            if (scene.image5translation[1] = -400) then
                scene.image5Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate5="start"
            end if

            if (scene.image6translation[1] = -400) then
                scene.image6Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate6="start"
            end if
            
            if (scene.image7translation[1] = -400) then
                scene.image7Uri=photoItems[photo.GetNext(photoItems)]
                scene.controlAnimate7="start"
            end if
            
            if (scene.image8translation[1] = -400) then
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
