Sub RunScreensaver()
    screen=CreateObject("roSGScreen")
    photo=CreateObject("roAssociativeArray")
    port=CreateObject("roMessagePort")
    device=CreateObject("roDeviceInfo")
    ds=device.GetDisplaySize()
    
    Init()
    REM oa = Oauth()
    REM googlephotos = LoadGooglePhotos()
    
    ssUser=RegRead("ScreensaverUser","Settings")
    userIndex=0
    if ssUser=invalid then		
        userIndex=0
    else
        userCount=m.oa.count()
        for i = 0 to userCount-1
            if m.oa.userInfoEmail[i] = ssUser then userIndex = i
        end for
    end if
    
    if not m.oa.linked() then
        rsp="invalid"
    else
        rsp=m.googlephotos.ExecServerAPI("?kind=photo&max-results=500&v=2.0&fields=entry(media:group(media:content))&imgmax=900","default",userIndex)
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

    ' Build the custom scene
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
End Sub


Sub HandlePortWait(port, wait, screen)
    msg = wait(wait, port)
    if type(msg) = "roImageCanvasEvent" then
        if (msg.isRemoteKeyPressed()) then
            i = msg.GetIndex()
            print "Key Pressed - " ; msg.GetIndex()
            ' Up - Close the screen.
            screen.close()
            end
        else if (msg.isScreenClosed()) then
            print "Closed"
            end
        end if
    end if
End Sub

Sub RunScreenSaverSettings()
    initTheme()
    Init()
    REM oa = Oauth()
    
    linked=m.oa.linked()
    userCount=m.oa.count()

    ssUser=RegRead("ScreensaverUser","Settings")
    if ssUser=invalid then		
        typetext=m.oa.userInfoName[0]		
    else
        userIndex=0
        for i=0 to userCount-1
            if m.oa.userInfoEmail[i] = ssUser then userIndex=i
        end for
        typetext=m.oa.userInfoName[userIndex]				
    end if		

    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    
    screen.AddHeaderText("About Screensaver")
    if linked then
        screen.AddParagraph("Your Google Photos account is successfully linked. This screensavor will randomly display your personal photos")
        screen.AddParagraph("Thank you for using the Google Photos channel!")
    
        if userCount > 1 then
            screen.AddParagraph(" ")
            screen.AddParagraph("Choose which linked user to display photos from")
            screen.AddParagraph("Current setting: "+typetext)
            
            for i = 0 to userCount-1
                screen.AddButton(i, m.oa.userInfoName[i])
            end for
        end if
        
    else
        screen.AddParagraph("Your Google Photos account is not linked.  Please link your account through the Google Photos channel to view your personal photos.")
    end if
    screen.AddButton(99, "Back")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                button_idx=msg.GetIndex()
                if button_idx <> 99 then
                    RegWrite("ScreensaverUser",m.oa.userInfoEmail[button_idx],"Settings")
                    test=RegRead("ScreensaverUser","Settings")
                end if
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub
