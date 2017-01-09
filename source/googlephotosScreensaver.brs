Sub RunScreensaver()
    ba=CreateObject("roByteArray")
    canvas=CreateObject("roImageCanvas")
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

    print "userIndex: '"; userIndex; "'"

    if not m.oa.linked() then
        rsp="invalid"
    else
        rsp=m.googlephotos.ExecServerAPI("?kind=photo&max-results=500&v=2.0&fields=entry(media:group(media:content))&imgmax=400","default",userIndex)
    end if

    canvasItems=[]
    if isxmlelement(rsp) then 
        images=googlephotos_new_image_list(rsp.entry)
        print "DEBUG "; image
        for each image in images
            if image.GetURL().instr(".MOV") <> -1 Or image.GetURL().instr(".mp4") <> -1 then
                print "Ignore: "; image.GetURL()
            else
                print "Push: "; image.GetURL()
                canvasItems.Push(image.GetURL())
            end if    
        end for
    end if    

    'If unlinked, we'll advertise our channel!  :-) 
    if canvasItems.count() = 0 then
        canvasItems.Push("https://image.roku.com/developer_channels/prod/3eedea580e39763e6220974c270504123e8a11aaa9248c0e308c3526003f19b8.png")
    end if

    canvas.SetMessagePort(port)
    canvas.PurgeCachedImages()
    canvas.SetRequireAllImagesToDraw(true)
    canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
    canvas.Show()
    counter=Rnd(canvasItems.Count())-1
    while(true)
        'Reset counter if end
        nextimg=Rnd(canvasItems.Count())-1
        
        canvasItem=[
            {url: canvasItems[counter],
             TargetRect:{x:Rnd(ds.w-420), y:Rnd(ds.h-300)}},
            {url: canvasItems[nextimg],
            TargetRect:{x:-1000, y:-1000}}   'Off the screen to preload     
        ]
        
        canvas.SetLayer(2, {Color:"#FF000000", CompositionMode:"Source"})
        canvas.SetLayer(1, canvasItem)
        HandleCanvasPort(port, 1000, canvas)
        
        for i=255 to -1 step -8
            if i=-1 then i=0
            ba[0]=i
            ab=ba.ToHexString()
            canvas.SetLayer(2, {Color:"#"+ab+"000000", CompositionMode:"Source_Over"})
            canvas.Show()
            HandleCanvasPort(port, 32, canvas)
        end for
        
        HandleCanvasPort(port, 12000, canvas)
        
        for i=0 to 256 step 8
            if i=256 then i=255
            ba[0]=i
            ab=ba.ToHexString()
            canvas.SetLayer(2, {Color:"#"+ab+"000000", CompositionMode:"Source_Over"})
            canvas.Show()
            HandleCanvasPort(port, 32, canvas)
        end for
        
        counter=nextimg
    end while
End Sub

Sub HandleCanvasPort(port, wait, canvas)
    msg = wait(wait, port)
    if type(msg) = "roImageCanvasEvent" then
        if (msg.isRemoteKeyPressed()) then
            i = msg.GetIndex()
            print "Key Pressed - " ; msg.GetIndex()
            ' Up - Close the screen.
            canvas.close()
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
